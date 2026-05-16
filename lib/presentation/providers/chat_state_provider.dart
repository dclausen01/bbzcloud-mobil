/// BBZCloud Mobile - Chat State Provider
///
/// In-memory state fed by the JS bridge (unread count, ready flag) plus
/// pending deeplink targets coming from push-notification taps.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  const ChatState({
    this.ready = false,
    this.unread = 0,
    this.pendingDeeplink,
    this.currentPath = '/',
  });

  /// Bridge handshake completed.
  final bool ready;

  /// Total unread (channels + DMs).
  final int unread;

  /// Set by push-tap or future deep-link sources. Consumed by ChatWebView
  /// which calls `window.bbzChat.navigate(...)` and clears it.
  final String? pendingDeeplink;

  /// Aktueller React-Router-Pfad, vom Frontend ueber
  /// `notifyRouteChange(path)` gemeldet. Wird genutzt, um z.B. die
  /// Back-Geste auf der Root-Sicht ohne JS-Round-Trip direkt auf
  /// "App in Hintergrund" zu mappen.
  final String currentPath;

  ChatState copyWith({
    bool? ready,
    int? unread,
    String? currentPath,
  }) {
    return ChatState(
      ready: ready ?? this.ready,
      unread: unread ?? this.unread,
      pendingDeeplink: pendingDeeplink,
      currentPath: currentPath ?? this.currentPath,
    );
  }
}

class ChatStateNotifier extends StateNotifier<ChatState> {
  ChatStateNotifier() : super(const ChatState());

  void setReady(bool value) => state = state.copyWith(ready: value);
  void setUnread(int value) =>
      state = state.copyWith(unread: value < 0 ? 0 : value);
  void setCurrentPath(String path) =>
      state = state.copyWith(currentPath: path);

  void requestDeeplink(String path) {
    state = ChatState(
      ready: state.ready,
      unread: state.unread,
      currentPath: state.currentPath,
      pendingDeeplink: path,
    );
  }

  void consumeDeeplink() {
    state = ChatState(
      ready: state.ready,
      unread: state.unread,
      currentPath: state.currentPath,
      pendingDeeplink: null,
    );
  }
}

final chatStateProvider =
    StateNotifierProvider<ChatStateNotifier, ChatState>((ref) {
  return ChatStateNotifier();
});

/// Convenience selector – avoids unnecessary rebuilds where only the unread
/// count matters (AppBar badge, drawer tile badge).
final chatUnreadProvider = Provider<int>((ref) {
  return ref.watch(chatStateProvider.select((s) => s.unread));
});
