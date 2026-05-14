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

const String _androidChannelId = 'bbz_chat_messages';
const String _androidChannelName = 'Chat-Nachrichten';
const String _androidChannelDescription =
    'Benachrichtigungen für neue Chat-Nachrichten.';

/// Background isolate handler. **Must** be a top-level function so the
/// Dart isolate can find it.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {/* already initialised */}
  // We don't render anything here on Android because the server already
  // sends a notification payload for iOS, and Android receives data-only
  // pushes that the system will not display anyway when the app is fully
  // terminated. The local-notification rendering happens on
  // onMessageOpenedApp / onMessage instead.
  debugPrint('Background FCM message id=${message.messageId}');
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
    final sessionToken =
        await CredentialService.instance.loadChatSessionToken();
    if (token != null && sessionToken != null && sessionToken.isNotEmpty) {
      await ChatAuthService.instance.unregisterPushToken(
        mobileToken: sessionToken,
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
    // /api/push-tokens haengt aktuell noch an der alten Stashcat-Session-
    // Auth – wir muessen das `sessionToken` aus mobile-login als Bearer
    // schicken, nicht den `mobileToken`.
    final sessionToken =
        await CredentialService.instance.loadChatSessionToken();
    if (sessionToken == null || sessionToken.isEmpty) {
      logger.warning(
          'Skip push register – no chat session token yet. Will retry on next chat login.');
      return;
    }
    logger.info('Registering push token with chat server…');
    final ok = await ChatAuthService.instance.registerPushToken(
      mobileToken: sessionToken,
      pushToken: pushToken,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
    if (ok) {
      logger.info('Push token registered with chat server.');
      return;
    }

    // 401 / 4xx → Session-Token ungueltig oder abgelaufen. Cache leeren,
    // damit der naechste Chat-Boot eine frische mobile-login-Runde
    // ausloest.
    logger.warning(
        'Push token NOT registered – server rejected. '
        'Invalidating cached session token.');
    await CredentialService.instance.deleteChatSessionToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final title =
        message.notification?.title ?? data['channelName']?.toString() ?? 'BBZ Chat';
    final body =
        message.notification?.body ?? data['preview']?.toString() ?? 'Neue Nachricht';
    final deeplink = data['deeplink']?.toString();

    // Bump unread badge if the server included it.
    final unreadRaw = data['unreadCount'];
    final unread = int.tryParse(unreadRaw?.toString() ?? '');
    if (unread != null) {
      _container
          ?.read(chatStateProvider.notifier)
          .setUnread(unread);
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
