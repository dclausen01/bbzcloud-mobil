/// BBZCloud Mobile - Chat ⇄ Flutter Bridge
///
/// Implements the JS bridge contract from
/// docs/STASHCAT_CHAT_INTEGRATION.md §2.
///
/// Inbound (Chat → Flutter): handlers registered on the WebView controller.
/// Outbound (Flutter → Chat): static methods that call `window.bbzChat.*`
/// through `evaluateJavascript`.

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bbzcloud_mobil/core/utils/app_logger.dart';
import 'package:bbzcloud_mobil/data/services/chat_auth_service.dart';
import 'package:bbzcloud_mobil/data/services/credential_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/chat_state_provider.dart';
import 'package:bbzcloud_mobil/services/push_service.dart';

typedef OnLogoutCallback = Future<void> Function();

/// Lifecycle helper that attaches the JS handlers to a freshly created
/// [InAppWebViewController] and exposes the outbound helpers.
class ChatBridge {
  ChatBridge({
    required this.controller,
    required this.ref,
    this.onLogout,
  });

  final InAppWebViewController controller;
  final WidgetRef ref;
  final OnLogoutCallback? onLogout;

  // --- Inbound handlers ----------------------------------------------------

  void attachHandlers() {
    controller.addJavaScriptHandler(
      handlerName: 'bridgeReady',
      callback: (args) {
        logger.info('ChatBridge: bridgeReady $args');
        ref.read(chatStateProvider.notifier).setReady(true);
        return {'ok': true};
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'unread',
      callback: (args) {
        final n = _firstInt(args);
        if (n != null) {
          ref.read(chatStateProvider.notifier).setUnread(n);
        }
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'setBadge',
      callback: (args) {
        final n = _firstInt(args);
        if (n != null) {
          ref.read(chatStateProvider.notifier).setUnread(n);
        }
        // FlutterAppBadger integration → Phase 3 (with push). For now we
        // simply mirror the value into the unread state, which already
        // drives all visible badges.
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'notify',
      callback: (args) {
        // While the app is in the foreground push is suppressed
        // server-side – this handler only fires from inside the chat
        // itself (e.g. "neue Reaktion auf deine Nachricht"). Phase 3 will
        // turn this into a local notification; for now we just log.
        logger.info('ChatBridge: notify $args');
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'openExternal',
      callback: (args) async {
        final url = _firstString(args);
        if (url == null || url.isEmpty) return null;
        await _launchExternal(url);
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'jitsi',
      callback: (args) async {
        final url = _firstString(args);
        if (url == null || url.isEmpty) return null;
        // Open via the native Jitsi app where possible. canLaunchUrl()
        // returns true for both https:// and jitsi-meet:// schemes if the
        // app is installed; fall back to the browser otherwise.
        await _launchExternal(url, preferExternalApp: true);
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'logout',
      callback: (args) async {
        logger.info('ChatBridge: logout requested');
        if (onLogout != null) await onLogout!.call();
        return {'ok': true};
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'pickFiles',
      callback: (args) async {
        // args[0] kann ein Optionsobjekt sein. Aktuell unterstuetzte
        // Felder: { allowMultiple: bool, type: 'image' | 'video' | 'any' }
        bool allowMultiple = true;
        FileType fileType = FileType.any;
        if (args.isNotEmpty && args.first is Map) {
          final opts = (args.first as Map).cast<String, dynamic>();
          allowMultiple = opts['allowMultiple'] != false;
          switch (opts['type']?.toString()) {
            case 'image':
              fileType = FileType.image;
              break;
            case 'video':
              fileType = FileType.video;
              break;
            case 'audio':
              fileType = FileType.audio;
              break;
            default:
              fileType = FileType.any;
          }
        }

        try {
          final result = await FilePicker.platform.pickFiles(
            type: fileType,
            allowMultiple: allowMultiple,
            withData: false,
            // Wir liefern Pfade an JS - die React-Seite kann sie via
            // fetch('file://…') NICHT lesen (WebView-Security). Das ist
            // Absicht: der eigentliche Upload-Pfad laeuft ueber
            // window.bbzChat.attachFiles(...) im Frontend, das die
            // Pfade von uns entgegennimmt und dann via Bridge die Bytes
            // anfordert. Bis das frontend-seitig implementiert ist,
            // liefern wir die file:// URIs und laesst React den Rest
            // entscheiden.
          );
          if (result == null || result.files.isEmpty) {
            return <String>[];
          }
          return result.files
              .map((f) => f.path)
              .whereType<String>()
              .map((p) => Uri.file(p).toString())
              .toList();
        } catch (e) {
          logger.warning('pickFiles failed: $e');
          return <String>[];
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'haptic',
      callback: (args) async {
        // Arg kann String ('light'|'medium'|'heavy'|'selection'|'success'
        // |'warning'|'error') oder ein Map mit { type: '...' } sein.
        String type = 'light';
        if (args.isNotEmpty) {
          final a = args.first;
          if (a is String) {
            type = a;
          } else if (a is Map && a['type'] is String) {
            type = a['type'] as String;
          }
        }
        try {
          switch (type) {
            case 'medium':
              await HapticFeedback.mediumImpact();
              break;
            case 'heavy':
            case 'error':
              await HapticFeedback.heavyImpact();
              break;
            case 'selection':
              await HapticFeedback.selectionClick();
              break;
            case 'success':
            case 'warning':
              await HapticFeedback.mediumImpact();
              break;
            case 'light':
            default:
              await HapticFeedback.lightImpact();
          }
        } catch (e) {
          // Auf Plattformen ohne Haptik (z.B. iPad ohne Taptic Engine)
          // einfach ignorieren.
        }
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'captureImage',
      callback: (args) async {
        // Optionsobjekt: { maxWidth?: number, maxHeight?: number,
        // imageQuality?: number (0..100), preferFrontCamera?: bool }
        // Returns: string (file:// URI) bei Erfolg, null bei Abbruch.
        double? maxWidth;
        double? maxHeight;
        int? imageQuality;
        CameraDevice cam = CameraDevice.rear;
        if (args.isNotEmpty && args.first is Map) {
          final opts = (args.first as Map).cast<String, dynamic>();
          maxWidth = (opts['maxWidth'] as num?)?.toDouble();
          maxHeight = (opts['maxHeight'] as num?)?.toDouble();
          imageQuality = (opts['imageQuality'] as num?)?.toInt();
          if (opts['preferFrontCamera'] == true) cam = CameraDevice.front;
        }
        try {
          final XFile? photo = await ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            imageQuality: imageQuality,
            preferredCameraDevice: cam,
          );
          if (photo == null) return null;
          return Uri.file(photo.path).toString();
        } catch (e) {
          logger.warning('captureImage failed: $e');
          return null;
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'captureVideo',
      callback: (args) async {
        // Optionsobjekt: { maxDurationSeconds?: number, preferFrontCamera?: bool }
        // Returns: string (file:// URI) bei Erfolg, null bei Abbruch.
        Duration? maxDur;
        CameraDevice cam = CameraDevice.rear;
        if (args.isNotEmpty && args.first is Map) {
          final opts = (args.first as Map).cast<String, dynamic>();
          final secs = (opts['maxDurationSeconds'] as num?)?.toInt();
          if (secs != null && secs > 0) maxDur = Duration(seconds: secs);
          if (opts['preferFrontCamera'] == true) cam = CameraDevice.front;
        }
        try {
          final XFile? video = await ImagePicker().pickVideo(
            source: ImageSource.camera,
            maxDuration: maxDur,
            preferredCameraDevice: cam,
          );
          if (video == null) return null;
          return Uri.file(video.path).toString();
        } catch (e) {
          logger.warning('captureVideo failed: $e');
          return null;
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'readFile',
      callback: (args) async {
        // Liest eine vorher per pickFiles ausgewaehlte Datei als
        // base64. Damit kann der React-Code die Bytes in einen Blob
        // verwandeln und per fetch() hochladen. Args: [fileUri:string]
        if (args.isEmpty) return null;
        final raw = args.first?.toString() ?? '';
        if (raw.isEmpty) return null;
        try {
          final uri = Uri.parse(raw);
          final path = uri.scheme == 'file' ? uri.toFilePath() : raw;
          final file = File(path);
          if (!await file.exists()) return null;
          final bytes = await file.readAsBytes();
          return {
            'name': path.split('/').last,
            'size': bytes.length,
            'base64': base64Encode(bytes),
          };
        } catch (e) {
          logger.warning('readFile failed: $e');
          return null;
        }
      },
    );
  }

  // --- Outbound helpers ----------------------------------------------------

  /// Sends the mobile bridge token. The chat then calls
  /// /api/auth/mobile-session and bootstraps its auth context.
  Future<void> setToken(String token) =>
      _evalBbzChat('setToken', [jsonEncode(token)]);

  Future<void> setTheme(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'light', // fallback; ChatHomeScreen resolves real
    };
    return _evalBbzChat('setTheme', [jsonEncode(value)]);
  }

  Future<void> navigate(String path) =>
      _evalBbzChat('navigate', [jsonEncode(path)]);

  Future<void> reload() => _evalBbzChat('reload', const []);

  Future<void> _evalBbzChat(String fn, List<String> args) async {
    final src = "window.bbzChat && window.bbzChat.$fn(${args.join(', ')});";
    try {
      await controller.evaluateJavascript(source: src);
    } catch (e) {
      logger.warning('ChatBridge: evaluateJavascript($fn) failed: $e');
    }
  }

  // --- Helpers -------------------------------------------------------------

  static Future<void> _launchExternal(
    String url, {
    bool preferExternalApp = false,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final mode = preferExternalApp
        ? LaunchMode.externalApplication
        : LaunchMode.externalNonBrowserApplication;
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      logger.warning('ChatBridge: cannot launch $url');
      return;
    }
    await launchUrl(uri, mode: mode);
  }

  static int? _firstInt(List<dynamic> args) {
    if (args.isEmpty) return null;
    final v = args.first;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    if (v is Map && v['value'] is num) {
      return (v['value'] as num).toInt();
    }
    return null;
  }

  static String? _firstString(List<dynamic> args) {
    if (args.isEmpty) return null;
    final v = args.first;
    if (v is String) return v;
    if (v is Map && v['url'] is String) return v['url'] as String;
    return null;
  }
}

/// Shared logout routine that is invoked both from the JS bridge and from
/// the Flutter side (e.g. settings screen "abmelden"). It revokes the
/// mobile token on the server and wipes local storage. The push token is
/// invalidated *before* the mobile token because the unregister call
/// needs the bearer token for auth.
Future<void> performChatLogout() async {
  try {
    await PushService.instance.unregister();
  } catch (e) {
    logger.warning('Push unregister failed: $e');
  }
  final token = await CredentialService.instance.loadChatMobileToken();
  if (token != null && token.isNotEmpty) {
    await ChatAuthService.instance.mobileLogout(token);
  }
  await CredentialService.instance.deleteChatMobileToken();
}
