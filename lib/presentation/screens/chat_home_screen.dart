/// BBZCloud Mobile - Chat Home Screen
///
/// Replaces the old apps-grid home. The stashcat-chat WebView is now the
/// primary surface; navigation to other apps happens exclusively through the
/// side drawer (phone) or permanent sidebar (tablet).
///
/// See docs/STASHCAT_CHAT_INTEGRATION.md for the bridge contract.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bbzcloud_mobil/core/constants/app_config.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/utils/platform_utils.dart';
import 'package:bbzcloud_mobil/presentation/providers/current_webview_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';
import 'package:bbzcloud_mobil/presentation/screens/welcome_screen.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_drawer.dart';
import 'package:bbzcloud_mobil/presentation/widgets/embedded_webview_widget.dart';

class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final isTablet = PlatformUtils.isTablet(context);

    return userState.when(
      data: (user) {
        if (user == null) {
          // No user yet → fall back to onboarding.
          return const WelcomeScreen();
        }
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

  Widget _buildPhone(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
      ),
      body: const _ChatWebView(),
    );
  }

  // -- Tablet ----------------------------------------------------------------

  Widget _buildTablet(BuildContext context, WidgetRef ref) {
    final activeWebView = ref.watch(tabletWebViewProvider);

    return Scaffold(
      body: Row(
        children: [
          // Permanent sidebar – the AppDrawer used as a side panel.
          SizedBox(
            width: 300,
            child: const AppDrawer(),
          ),
          // Vertical divider
          VerticalDivider(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
          // Main content: chat by default, or an embedded app WebView when
          // the user picks one from the sidebar.
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
                : const _ChatWebView(),
          ),
        ],
      ),
    );
  }
}

/// The actual chat WebView. Wrapped so we can later attach the JS bridge,
/// theme sync and push deeplink handling without touching the host screen.
class _ChatWebView extends StatelessWidget {
  const _ChatWebView();

  @override
  Widget build(BuildContext context) {
    return const EmbeddedWebViewWidget(
      appId: AppConfig.chatAppId,
      title: 'Chat',
      url: AppConfig.chatUrl,
      // The chat handles its own auth via the upcoming mobile-bridge SSO
      // (Phase 2). No legacy injection scripts.
      requiresAuth: false,
      // We render our own AppBar on phones; on tablets the chat lives inside
      // the body of the host Scaffold, so we hide the embedded chrome here.
      showAppBar: false,
      // The chat is an SPA – no back/forward/refresh bottom bar.
      showBottomBar: false,
    );
  }
}
