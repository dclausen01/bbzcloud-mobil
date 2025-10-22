/// BBZCloud Mobile - WebView Stack Provider
/// 
/// Manages multiple WebView instances for quick app switching
/// 
/// @version 0.1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/utils/app_logger.dart';

/// WebView Stack Item
class WebViewStackItem {
  final String id;
  final String title;
  final String url;
  final bool requiresAuth;
  final DateTime lastAccess;

  const WebViewStackItem({
    required this.id,
    required this.title,
    required this.url,
    required this.requiresAuth,
    required this.lastAccess,
  });

  WebViewStackItem copyWith({
    String? id,
    String? title,
    String? url,
    bool? requiresAuth,
    DateTime? lastAccess,
  }) {
    return WebViewStackItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      lastAccess: lastAccess ?? this.lastAccess,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebViewStackItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// WebView Stack State
class WebViewStackState {
  final List<WebViewStackItem> stack;
  final String? currentWebViewId;
  final int maxStackSize;

  const WebViewStackState({
    required this.stack,
    this.currentWebViewId,
    this.maxStackSize = 5,
  });

  WebViewStackState copyWith({
    List<WebViewStackItem>? stack,
    String? currentWebViewId,
    int? maxStackSize,
  }) {
    return WebViewStackState(
      stack: stack ?? this.stack,
      currentWebViewId: currentWebViewId ?? this.currentWebViewId,
      maxStackSize: maxStackSize ?? this.maxStackSize,
    );
  }

  factory WebViewStackState.initial() {
    return const WebViewStackState(
      stack: [],
      currentWebViewId: null,
      maxStackSize: 5,
    );
  }

  /// Get current WebView item
  WebViewStackItem? get currentItem {
    if (currentWebViewId == null) return null;
    try {
      return stack.firstWhere((item) => item.id == currentWebViewId);
    } catch (e) {
      return null;
    }
  }

  /// Check if WebView exists in stack
  bool hasWebView(String id) {
    return stack.any((item) => item.id == id);
  }

  /// Get WebView count
  int get count => stack.length;
}

/// WebView Stack Notifier
class WebViewStackNotifier extends StateNotifier<WebViewStackState> {
  WebViewStackNotifier() : super(WebViewStackState.initial());

  /// Add or update WebView in stack
  void addOrUpdateWebView({
    required String id,
    required String title,
    required String url,
    required bool requiresAuth,
  }) {
    final existingIndex = state.stack.indexWhere((item) => item.id == id);
    
    if (existingIndex != -1) {
      // Update existing item's last access
      final updatedStack = List<WebViewStackItem>.from(state.stack);
      updatedStack[existingIndex] = updatedStack[existingIndex].copyWith(
        lastAccess: DateTime.now(),
      );
      
      state = state.copyWith(
        stack: updatedStack,
        currentWebViewId: id,
      );
      
      logger.info('Updated WebView in stack: $title');
    } else {
      // Add new item
      var newStack = List<WebViewStackItem>.from(state.stack);
      
      // Remove oldest item if stack is full
      if (newStack.length >= state.maxStackSize) {
        newStack.sort((a, b) => a.lastAccess.compareTo(b.lastAccess));
        newStack.removeAt(0);
        logger.info('Removed oldest WebView from stack');
      }
      
      newStack.add(WebViewStackItem(
        id: id,
        title: title,
        url: url,
        requiresAuth: requiresAuth,
        lastAccess: DateTime.now(),
      ));
      
      state = state.copyWith(
        stack: newStack,
        currentWebViewId: id,
      );
      
      logger.info('Added WebView to stack: $title (${newStack.length}/${state.maxStackSize})');
    }
  }

  /// Switch to existing WebView
  void switchToWebView(String id) {
    if (state.hasWebView(id)) {
      // Update last access time
      final updatedStack = state.stack.map((item) {
        if (item.id == id) {
          return item.copyWith(lastAccess: DateTime.now());
        }
        return item;
      }).toList();
      
      state = state.copyWith(
        stack: updatedStack,
        currentWebViewId: id,
      );
      
      logger.info('Switched to WebView: $id');
    }
  }

  /// Remove WebView from stack
  void removeWebView(String id) {
    final newStack = state.stack.where((item) => item.id != id).toList();
    
    String? newCurrentId = state.currentWebViewId;
    if (state.currentWebViewId == id) {
      // Switch to most recent other WebView
      if (newStack.isNotEmpty) {
        newStack.sort((a, b) => b.lastAccess.compareTo(a.lastAccess));
        newCurrentId = newStack.first.id;
      } else {
        newCurrentId = null;
      }
    }
    
    state = state.copyWith(
      stack: newStack,
      currentWebViewId: newCurrentId,
    );
    
    logger.info('Removed WebView from stack: $id');
  }

  /// Clear current WebView (navigate away)
  void clearCurrent() {
    state = state.copyWith(currentWebViewId: null);
  }

  /// Clear all WebViews from stack
  void clearAll() {
    state = WebViewStackState.initial();
    logger.info('Cleared all WebViews from stack');
  }

  /// Get stack sorted by last access (most recent first)
  List<WebViewStackItem> getSortedStack() {
    final sorted = List<WebViewStackItem>.from(state.stack);
    sorted.sort((a, b) => b.lastAccess.compareTo(a.lastAccess));
    return sorted;
  }
}

/// Provider for WebView stack
final webViewStackProvider = StateNotifierProvider<WebViewStackNotifier, WebViewStackState>((ref) {
  return WebViewStackNotifier();
});

/// Provider for active WebView count
final activeWebViewCountProvider = Provider<int>((ref) {
  return ref.watch(webViewStackProvider).count;
});

/// Provider for current WebView
final currentWebViewProvider = Provider<WebViewStackItem?>((ref) {
  return ref.watch(webViewStackProvider).currentItem;
});
