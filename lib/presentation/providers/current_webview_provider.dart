/// BBZCloud Mobile - Current WebView Provider
/// 
/// Manages the currently displayed WebView on tablets
/// On tablets, the WebView is embedded in the home screen instead of pushed as a new route
/// 
/// @version 0.1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the currently displayed WebView on tablets
class CurrentWebViewState {
  final String? appId;
  final String? title;
  final String? url;
  final bool? requiresAuth;

  const CurrentWebViewState({
    this.appId,
    this.title,
    this.url,
    this.requiresAuth,
  });

  /// Check if a WebView is currently active
  bool get hasWebView => appId != null && title != null && url != null;

  /// Create empty state (no WebView active)
  const CurrentWebViewState.empty()
      : appId = null,
        title = null,
        url = null,
        requiresAuth = null;

  /// Create state with WebView data
  CurrentWebViewState copyWith({
    String? appId,
    String? title,
    String? url,
    bool? requiresAuth,
  }) {
    return CurrentWebViewState(
      appId: appId ?? this.appId,
      title: title ?? this.title,
      url: url ?? this.url,
      requiresAuth: requiresAuth ?? this.requiresAuth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentWebViewState &&
          runtimeType == other.runtimeType &&
          appId == other.appId &&
          title == other.title &&
          url == other.url &&
          requiresAuth == other.requiresAuth;

  @override
  int get hashCode =>
      appId.hashCode ^
      title.hashCode ^
      url.hashCode ^
      (requiresAuth?.hashCode ?? 0);

  @override
  String toString() =>
      'CurrentWebViewState(appId: $appId, title: $title, url: $url, requiresAuth: $requiresAuth)';
}

/// Notifier for managing the current WebView state
class CurrentWebViewNotifier extends StateNotifier<CurrentWebViewState> {
  CurrentWebViewNotifier() : super(const CurrentWebViewState.empty());

  /// Show a WebView with the given parameters
  void showWebView({
    required String appId,
    required String title,
    required String url,
    required bool requiresAuth,
  }) {
    state = CurrentWebViewState(
      appId: appId,
      title: title,
      url: url,
      requiresAuth: requiresAuth,
    );
  }

  /// Clear the current WebView (return to home)
  void clearWebView() {
    state = const CurrentWebViewState.empty();
  }

  /// Check if the given app is currently displayed
  bool isCurrentApp(String appId) {
    return state.appId == appId;
  }
}

/// Provider for the current WebView state
final currentWebViewProvider =
    StateNotifierProvider<CurrentWebViewNotifier, CurrentWebViewState>(
  (ref) => CurrentWebViewNotifier(),
);
