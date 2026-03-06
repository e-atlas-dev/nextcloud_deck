import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/core/utils/date_formatter.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/app_providers.dart';

class SyncLogsScreen extends ConsumerStatefulWidget {
  const SyncLogsScreen({super.key});

  @override
  ConsumerState<SyncLogsScreen> createState() => _SyncLogsScreenState();
}

class _SyncLogsScreenState extends ConsumerState<SyncLogsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hive = ref.read(hiveServiceProvider);
    final logs = hive.syncLogsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncLogsTitle),
        actions: [
          if (logs.isNotEmpty)
            TextButton(
              onPressed: () {
                hive.syncLogsBox.clear();
                setState(() {});
              },
              child: Text(l10n.syncLogsClear),
            ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.syncLogsEmpty),
                ],
              ),
            )
          : ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final log = logs[i];
                final isSuccess = log.status == 'success';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: isSuccess
                        ? AppColors.successLight
                        : AppColors.errorLight,
                    child: Icon(
                      isSuccess
                          ? Icons.check_rounded
                          : Icons.error_outline_rounded,
                      size: 18,
                      color: isSuccess ? AppColors.success : AppColors.error,
                    ),
                  ),
                  title: Text(
                    '${_opLabel(log.operation, l10n)} ${log.entityType} #${log.entityId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.formatLogMillis(log.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (log.errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          log.errorMessage,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _opLabel(String op, AppLocalizations l10n) => switch (op) {
    'create' => l10n.syncLogOpCreated,
    'update' => l10n.syncLogOpUpdated,
    'delete' => l10n.syncLogOpDeleted,
    'resolve' => l10n.syncLogOpConflictResolved,
    _ => op,
  };
}
