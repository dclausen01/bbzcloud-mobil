/// BBZCloud Mobile - Chat Auth Service
///
/// Thin HTTP client for the mobile-bridge auth endpoints exposed by
/// stashcat-chat (see docs/STASHCAT_CHAT_INTEGRATION.md §3).
///
/// Flow:
///   1. mobileLogin(email, password) → { mobileToken, ... }
///   2. Token wird per CredentialService gespeichert.
///   3. Beim WebView-Boot ruft Flutter `window.bbzChat.setToken(token)`;
///      der Chat selbst fragt dann `/api/auth/mobile-session` ab und
///      bekommt einen frischen Session-Cookie.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:bbzcloud_mobil/core/constants/app_config.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';

class ChatAuthException implements Exception {
  ChatAuthException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ChatAuthException($statusCode): $message';
}

class ChatAuthService {
  ChatAuthService._({http.Client? client}) : _client = client ?? http.Client();

  static final ChatAuthService instance = ChatAuthService._();

  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  Uri _u(String path) => Uri.parse('${AppConfig.chatBaseUrl}$path');

  /// Calls `/api/auth/mobile-login`. Returns the long-lived mobile token.
  ///
  /// [securityPassword] is the optional E2E password (defaults to [password]
  /// if the BBZ-Account uses the same secret; pass null to let the server
  /// decide / prompt later).
  Future<String> mobileLogin({
    required String email,
    required String password,
    String? securityPassword,
  }) async {
    final body = jsonEncode({
      'email': email,
      'password': password,
      // Spec: { email, password, securityPassword }. For BBZ accounts the
      // chat password and the security password are usually identical.
      'securityPassword': securityPassword ?? password,
    });

    final res = await _client
        .post(
          _u('/api/auth/mobile-login'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      logger.warning('mobile-login HTTP ${res.statusCode}: ${res.body}');
      throw ChatAuthException(
        'Mobile-Login fehlgeschlagen',
        statusCode: res.statusCode,
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw ChatAuthException('Antwort konnte nicht gelesen werden: $e');
    }

    final token = json['mobileToken'];
    if (token is! String || token.isEmpty) {
      throw ChatAuthException('Antwort ohne mobileToken');
    }
    return token;
  }

  /// Best-effort logout. Errors are swallowed because the local token is
  /// always cleared regardless of server response.
  Future<void> mobileLogout(String mobileToken) async {
    try {
      await _client
          .post(
            _u('/api/auth/mobile-logout'),
            headers: {
              'Authorization': 'Bearer $mobileToken',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);
    } catch (e) {
      logger.warning('mobile-logout swallowed error: $e');
    }
  }

  // -- Push tokens ---------------------------------------------------------

  /// Registers (or refreshes) an FCM/APNs token for this account. The
  /// server stores it together with the user id, platform and
  /// app version so the push dispatcher can target the right devices.
  /// Registers (or refreshes) an FCM/APNs token for this account.
  /// Returns true if the server accepted the token, false otherwise.
  Future<bool> registerPushToken({
    required String mobileToken,
    required String pushToken,
    required String platform,
    String? appVersion,
    String? locale,
  }) async {
    final endpoint = _u('/api/push-tokens');
    // Damit man im Log direkt sieht, welche Form das Bearer-Token hat
    // (mobileToken-Hex vs. Stashcat-Session-Token mit ":"-Trennzeichen):
    final preview = mobileToken.length > 20
        ? '${mobileToken.substring(0, 12)}…${mobileToken.substring(mobileToken.length - 4)} (len=${mobileToken.length}, hasColon=${mobileToken.contains(':')})'
        : '$mobileToken (len=${mobileToken.length})';
    logger.info('push-token register Bearer: $preview');
    try {
      final res = await _client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $mobileToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'token': pushToken,
              'platform': platform,
              if (appVersion != null) 'appVersion': appVersion,
              if (locale != null) 'locale': locale,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        logger.info(
            'push-token register OK (HTTP ${res.statusCode}) → $endpoint');
        return true;
      } else {
        logger.warning(
            'push-token register HTTP ${res.statusCode}: ${res.body}');
        return false;
      }
    } catch (e) {
      logger.warning('push-token register error ($endpoint): $e');
      return false;
    }
  }

  /// Unregisters a push token (best-effort).
  Future<void> unregisterPushToken({
    required String mobileToken,
    required String pushToken,
  }) async {
    try {
      await _client
          .delete(
            _u('/api/push-tokens/${Uri.encodeComponent(pushToken)}'),
            headers: {
              'Authorization': 'Bearer $mobileToken',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);
    } catch (e) {
      logger.warning('push-token unregister swallowed error: $e');
    }
  }
}
