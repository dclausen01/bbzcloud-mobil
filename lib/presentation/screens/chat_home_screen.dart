/// BBZCloud Mobile - Chat Home Screen
///
/// The stashcat-chat WebView is the primary surface. App-switching
/// happens through the drawer (phone) or permanent sidebar (tablet).
///
/// See docs/STASHCAT_CHAT_INTEGRATION.md for the bridge contract.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/utils/platform_utils.dart';
import 'package:bbzcloud_mobil/presentation/providers/chat_state_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/current_webview_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/welcome_screen.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_drawer.dart';
import 'package:bbzcloud_mobil/presentation/widgets/chat_webview.dart';
import 'package:bbzcloud_mobil/presentation/widgets/embedded_webview_widget.dart';

class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final isTablet = PlatformUtils.isTablet(context);

    return userState.when(
      data: (user) {
        if (user == null) return const WelcomeScreen();
        return isTablet ? _buildTablet(context, ref) : _buildPhone(context);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Fehler beim Laden: $error')),
      ),
    );
  }

  // -- Phone -----------------------------------------------------------------
  //
  // Phone is full-bleed chat. Navigation happens through the draggable
  // overlay button rendered by ChatWebView – tap shows the app switcher,
  // long-press opens the side drawer (settings, todos, manage apps).
  // No AppBar; the chat renders its own header inside the WebView.
  Widget _buildPhone(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: const SafeArea(
        top: true,
        // The React chat sets padding-bottom via env(safe-area-inset-
        // bottom), so we skip the bottom inset here to avoid double
        // padding on devices with home indicators.
        bottom: false,
        child: ChatWebView(),
      ),
    );
  }

  // -- Tablet ----------------------------------------------------------------

  Widget _buildTablet(BuildContext context, WidgetRef ref) {
    final activeWebView = ref.watch(tabletWebViewProvider);

    return Scaffold(
      body: Row(
        children: [
          const SizedBox(width: 300, child: AppDrawer()),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: activeWebView.hasWebView
                ? EmbeddedWebViewWidget(
                    key: ValueKey(activeWebView.appId),
                    appId: activeWebView.appId!,
                    title: activeWebView.title!,
                    url: activeWebView.url!,
                    requiresAuth: activeWebView.requiresAuth ?? false,
                    showAppBar: true,
                    showBottomBar: true,
                    onHomePressed: () => ref
                        .read(tabletWebViewProvider.notifier)
                        .clearWebView(),
                  )
                : const _TabletChatPane(),
          ),
        ],
      ),
    );
  }
}

class _TabletChatPane extends StatelessWidget {
  const _TabletChatPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const _ChatAppBarTitle(),
          automaticallyImplyLeading: false,
        ),
        const Expanded(child: ChatWebView()),
      ],
    );
  }
}

/// AppBar title with live unread badge fed by the JS bridge.
class _ChatAppBarTitle extends ConsumerWidget {
  const _ChatAppBarTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatUnreadProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(AppStrings.appTitle),
        if (unread > 0) ...[
          const SizedBox(width: 8),
          _UnreadBadge(count: unread),
        ],
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 22, minHeight: 18),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
