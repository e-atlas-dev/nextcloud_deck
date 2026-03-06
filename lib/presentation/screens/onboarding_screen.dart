import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/settings_provider.dart';
import 'package:nextcloud_deck/presentation/widgets/app_icon_widget.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _gradients = [
    (Color(0xFF0082C9), Color(0xFF005C8F)),
    (Color(0xFF46BA61), Color(0xFF2D8A45)),
    (Color(0xFF9D5BD2), Color(0xFF6B3A9A)),
  ];
  // Index 0 uses AppIcon (see itemBuilder below); only indices 1 and 2
  // are used from this list.
  static const _icons = [
    Icons.dashboard_rounded, // unused - AppIcon used instead
    Icons.cloud_off_rounded,
    Icons.sync_rounded,
  ];

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(settingsProvider.notifier).setHasSeenOnboarding(true);
    context.go('/');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = [
      l10n.onboardingTitle1,
      l10n.onboardingTitle2,
      l10n.onboardingTitle3,
    ];
    final bodies = [
      l10n.onboardingBody1,
      l10n.onboardingBody2,
      l10n.onboardingBody3,
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: 3,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (ctx, i) => _OnboardingPage(
              title: titles[i],
              body: bodies[i],
              gradientStart: _gradients[i].$1,
              gradientEnd: _gradients[i].$2,
              // Page 0 shows the app icon; subsequent pages use material icons.
              iconWidget: i == 0
                  ? AppIcon(size: 52, fallbackColor: AppColors.lightBackground)
                  : null,
              icon: i != 0 ? _icons[i] : null,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: AnimatedOpacity(
              opacity: _page < 2 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightBackground.withValues(
                    alpha: 0.7,
                  ),
                ),
                child: Text(l10n.onboardingSkip),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.lightBackground
                            : AppColors.lightBackground.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.lightBackground,
                        foregroundColor: _gradients[_page].$1,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _page < 2
                            ? l10n.onboardingNext
                            : l10n.onboardingGetStarted,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.gradientStart,
    required this.gradientEnd,
    this.iconWidget,
    this.icon,
  }) : assert(
         iconWidget != null || icon != null,
         'Provide either iconWidget or icon',
       );
  final Widget? iconWidget;
  final IconData? icon;
  final String title;
  final String body;
  final Color gradientStart;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.lightBackground.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child:
                    iconWidget ??
                    Icon(icon, size: 52, color: AppColors.lightBackground),
              ),
              const SizedBox(height: 40),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.lightBackground,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                body,
                style: TextStyle(
                  color: AppColors.lightBackground.withValues(alpha: 0.85),
                  fontSize: 17,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
