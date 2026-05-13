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
}
