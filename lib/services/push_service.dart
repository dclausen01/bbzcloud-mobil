/// BBZCloud Mobile - Push Service
///
/// Owns the Firebase Messaging lifecycle:
///   • requests notification permission (iOS + Android 13+)
///   • obtains the FCM/APNs token and registers it with the BBZ chat server
///   • renders foreground messages via flutter_local_notifications (the
///     chat backend sends data-only pushes on Android so we have full
///     control over rendering)
///   • routes message taps into the Riverpod chatStateProvider so
///     ChatWebView can deeplink the user to the right channel
///   • re-registers on token refresh; unregisters on logout.
///
/// Designed to be safe to call even when Firebase isn't initialised
/// (returns gracefully). Background-message handling lives in the
/// top-level `_firebaseMessagingBackgroundHandler` because FCM spawns an
/// isolated Dart isolate for background pushes.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/services/chat_auth_service.dart';
import 'package:bbzcloud_mobil/data/services/credential_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/chat_state_provider.dart';
import 'package:bbzcloud_mobil/services/app_icon_badge.dart';

const String _androidChannelId = 'bbz_chat_messages';
const String _androidChannelName = 'Chat-Nachrichten';
const String _androidChannelDescription =
    'Benachrichtigungen für neue Chat-Nachrichten.';

/// Background isolate handler. **Must** be a top-level function so the
/// Dart isolate can find it.
///
/// Wichtig: dieser Handler laeuft in einem **separaten Isolate**, ohne
/// Zugriff auf Riverpod, Singletons oder ProviderContainer. Wir
/// initialisieren Firebase + ein lokales FlutterLocalNotificationsPlugin
/// und rendern die Local-Notification direkt.
///
/// Hintergrund: Der BBZ-Chat-Server schickt Android-Pushes als
/// **data-only**-Payload (siehe `docs/STASHCAT_CHAT_INTEGRATION.md` §4).
/// data-only-Messages werden vom System NICHT von alleine angezeigt -
/// die App muss sie selbst rendern, sonst kommt am Geraet nichts an.
/// iOS bekommt zusaetzlich ein `notification`-Payload und braucht
/// diesen Pfad daher nicht.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {/* already initialised */}
  debugPrint('Background FCM message id=${message.messageId}');

  // iOS: das System zeigt die Notification bereits via `notification`
  // Payload an. Wir wuerden hier sonst doppelt anzeigen.
  if (Platform.isIOS) return;

  // Android: Bei "hybrid" Payloads (Firebase Console Test-Send,
  // oder wenn der Server irgendwann sowohl notification als auch
  // data mitschickt) rendert das System die Notification automatisch
  // aus dem `notification`-Payload. Unser Background-Handler wuerde
  // dann eine zweite, identische Local-Notification draufpacken.
  //
  // Vom BBZ-Chat-Dispatcher (Phase 3 Spec) kommen reine data-only
  // Pushes, dort ist `message.notification` null und wir rendern wie
  // gewohnt.
  if (message.notification != null) {
    debugPrint('Background FCM: notification payload present, skipping '
        'local notification (system will display).');
    return;
  }

  try {
    final local = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('ic_stat_notify');
    await local.initialize(
      const InitializationSettings(android: androidInit),
    );

    // Channel ist OS-weit; falls er noch nicht existiert (z.B. App
    // direkt nach Install ueber Push aufgeweckt), erstellen wir ihn
    // hier defensiv.
    final androidImpl = local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      ),
    );

    final data = message.data;
    final title = message.notification?.title ??
        data['title']?.toString() ??
        data['senderName']?.toString() ??
        data['channelName']?.toString() ??
        'BBZ Chat';
    final body = message.notification?.body ??
        data['body']?.toString() ??
        data['preview']?.toString() ??
        'Neue Nachricht';
    final deeplink = data['deeplink']?.toString();

    // OS-Icon-Badge: wenn der Server unreadCount mitschickt, das nehmen.
    final unread = int.tryParse(data['unreadCount']?.toString() ?? '');
    if (unread != null) {
      await AppIconBadge.set(unread);
    }

    await local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          icon: 'ic_stat_notify',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: deeplink == null ? null : jsonEncode({'deeplink': deeplink}),
    );
  } catch (e) {
    debugPrint('Background notification render failed: $e');
  }
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  ProviderContainer? _container;
  bool _initialised = false;
  String? _currentToken;

  /// Has to be called from `main()` after `Firebase.initializeApp()`.
  /// [container] is the root ProviderContainer (or a ref-derived one)
  /// used to push deeplinks into [chatStateProvider].
  Future<void> init(ProviderContainer container) async {
    if (_initialised) return;
    _initialised = true;
    _container = container;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    // Foreground messages → render a local notification + bump state.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App was background, user tapped the notification → deeplink.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // App was terminated, FCM message launched it → check for a stashed
    // initial message and replay the deeplink once the chat is ready.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleMessageOpenedApp(initial);
    }

    // App was terminated, *Local*-Notification (vom Background-Isolate
    // gerendert, weil der Server data-only schickt) launched die App →
    // Payload aus den NotificationAppLaunchDetails holen und Deeplink
    // einspeisen. Ohne diesen Pfad wuerde ein Tap auf eine BG-Local-
    // Notification zwar die App oeffnen, aber den Chat nicht aufs
    // richtige Channel/DM navigieren.
    try {
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final payload = launch!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleLocalNotificationLaunchPayload(payload);
        }
      }
    } catch (e) {
      logger.warning('getNotificationAppLaunchDetails failed: $e');
    }

    // Token rotation – re-register every time FCM hands us a new token.
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      unawaited(_registerCurrentToken());
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('ic_stat_notify');
    const iosInit = DarwinInitializationSettings(
      // Permissions are requested separately via FirebaseMessaging.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    // Pre-create the channel on Android so the system already knows
    // about it before the first push arrives.
    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// Asks the OS for notification permission and, if granted, fetches
  /// the FCM token and registers it with the BBZ chat server. Safe to
  /// call multiple times.
  Future<void> requestPermissionAndRegister() async {
    if (!_initialised) {
      logger.warning('PushService not initialised – skip register.');
      return;
    }
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      logger.info(
          'Push permission status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        logger.info('Push permission denied by user.');
        return;
      }

      _currentToken = await FirebaseMessaging.instance.getToken();
      if (_currentToken == null) {
        logger.warning('FCM getToken() returned null');
      } else {
        // Vollständiger Token in den App-internen Log-Buffer – im
        // Logcat sind die Strings sowieso schon zu lang. Über
        // Einstellungen → Logs lässt er sich kopieren.
        logger.info('FCM token (len=${_currentToken!.length}): $_currentToken');
        await _registerCurrentToken();
      }
    } catch (e, st) {
      logger.error('Push permission/register failed', e, st);
    }
  }

  /// Sends DELETE /api/push-tokens/<token>, then forgets the token
  /// locally. Called from performChatLogout.
  Future<void> unregister() async {
    final token = _currentToken;
    final mobileToken =
        await CredentialService.instance.loadChatMobileToken();
    if (token != null && mobileToken != null && mobileToken.isNotEmpty) {
      await ChatAuthService.instance.unregisterPushToken(
        mobileToken: mobileToken,
        pushToken: token,
      );
    }
    _currentToken = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      logger.warning('FCM deleteToken failed: $e');
    }
  }

  Future<void> _registerCurrentToken() async {
    final pushToken = _currentToken;
    if (pushToken == null) {
      logger.warning('Skip push register – no FCM token.');
      return;
    }
    final mobileToken =
        await CredentialService.instance.loadChatMobileToken();
    if (mobileToken == null || mobileToken.isEmpty) {
      logger.warning(
          'Skip push register – no mobile token yet. Will retry on next chat login.');
      return;
    }
    logger.info('Registering push token with chat server…');
    final ok = await ChatAuthService.instance.registerPushToken(
      mobileToken: mobileToken,
      pushToken: pushToken,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
    if (ok) {
      logger.info('Push token registered with chat server.');
      return;
    }

    // 401 → Token ungueltig oder abgelaufen. Cache leeren, damit der
    // naechste Chat-Boot eine frische mobile-login-Runde ausloest.
    logger.warning(
        'Push token NOT registered – server rejected. '
        'Invalidating cached mobile token.');
    await CredentialService.instance.deleteChatMobileToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ??
        data['title']?.toString() ??
        data['senderName']?.toString() ??
        data['channelName']?.toString() ??
        'BBZ Chat';
    final body = message.notification?.body ??
        data['body']?.toString() ??
        data['preview']?.toString() ??
        'Neue Nachricht';
    final deeplink = data['deeplink']?.toString();

    // Bump unread badge if the server included it.
    final unreadRaw = data['unreadCount'];
    final unread = int.tryParse(unreadRaw?.toString() ?? '');
    if (unread != null) {
      _container
          ?.read(chatStateProvider.notifier)
          .setUnread(unread);
      unawaited(AppIconBadge.set(unread));
    }

    _local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          icon: 'ic_stat_notify',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: deeplink == null ? null : jsonEncode({'deeplink': deeplink}),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final deeplink = message.data['deeplink']?.toString();
    if (deeplink == null || deeplink.isEmpty) return;
    _container
        ?.read(chatStateProvider.notifier)
        .requestDeeplink(deeplink);
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _handleLocalNotificationLaunchPayload(payload);
  }

  /// Shared payload-parsing path - laeuft sowohl beim Tap auf eine
  /// aktive Local-Notification (App im Vordergrund/Hintergrund) als
  /// auch beim Cold-Start aus den NotificationAppLaunchDetails.
  void _handleLocalNotificationLaunchPayload(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final deeplink = json['deeplink']?.toString();
      if (deeplink != null && deeplink.isNotEmpty) {
        _container
            ?.read(chatStateProvider.notifier)
            .requestDeeplink(deeplink);
      }
    } catch (_) {/* ignore malformed payload */}
  }
}
