import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/app_providers.dart';

class OfflineBannerWidget extends ConsumerWidget {
  const OfflineBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isOffline = ref
        .watch(isOnlineProvider)
        .when(
          data: (online) => !online,
          loading: () => false,
          error: (_, __) => false,
        );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          SizeTransition(sizeFactor: animation, child: child),
      child: isOffline
          ? Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Builder(
                builder: (ctx) {
                  final pending = ref
                      .watch(syncQueueServiceProvider)
                      .pendingCount;
                  final msg = pending > 0
                      ? l10n.offlineBannerQueued(pending)
                      : l10n.offlineBanner;

                  return Row(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          msg,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          : const SizedBox.shrink(key: ValueKey('online')),
    );
  }
}
