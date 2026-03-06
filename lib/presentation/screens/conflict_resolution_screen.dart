import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/core/utils/date_formatter.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/app_providers.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';

class ConflictResolutionScreen extends ConsumerStatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  ConsumerState<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState
    extends ConsumerState<ConflictResolutionScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hive = ref.read(hiveServiceProvider);
    final conflicts = hive.conflictsBox.values.toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.conflictsTitle)),
      body: conflicts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 56,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.conflictsEmpty,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conflicts.length,
              itemBuilder: (ctx, i) {
                final conflict = conflicts[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.merge_type_rounded,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.conflictEntityLabel(
                                  _capType(conflict.entityType),
                                  conflict.entityId,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.conflictDetectedAt(
                            DateFormatter.formatLogMillis(conflict.detectedAt),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _VersionCard(
                                label: l10n.conflictLocalVersion,
                                color: AppColors.brand,
                                payload: conflict.localPayload,
                                l10n: l10n,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _VersionCard(
                                label: l10n.conflictServerVersion,
                                color: AppColors.success,
                                payload: conflict.serverPayload,
                                l10n: l10n,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _resolve(
                                  conflict.id,
                                  keepLocal: false,
                                  l10n: l10n,
                                ),
                                child: Text(l10n.conflictKeepServer),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _resolve(
                                  conflict.id,
                                  keepLocal: true,
                                  l10n: l10n,
                                ),
                                child: Text(l10n.conflictKeepLocal),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _resolve(
    String conflictId, {
    required bool keepLocal,
    required AppLocalizations l10n,
  }) async {
    final hive = ref.read(hiveServiceProvider);
    final conflict = hive.conflictsBox.get(conflictId);
    if (conflict == null) return;

    final repo = ref.read(boardsRepositoryProvider);
    String? errorMsg;

    if (keepLocal) {
      if (repo != null) {
        try {
          final fields =
              jsonDecode(conflict.localPayload) as Map<String, dynamic>;
          final cachedHive = hive.cardsBox.get(conflict.entityId);
          if (cachedHive != null) {
            final card = repo
                .cardFromHivePublic(cachedHive)
                .copyWith(
                  title: fields['title'] as String? ?? cachedHive.title,
                  description:
                      fields['description'] as String? ??
                      cachedHive.description,
                );
            final updated = await repo.updateCard(
              card,
              resolution: ConflictResolutionPreference.keepLocal,
            );
            ref
                .read(boardDetailProvider.notifier)
                .replaceCardPublic(conflict.boardId, updated);
          }
        } on NotFoundException {
          errorMsg =
              'Card no longer exists on server; local changes discarded.';
        } catch (e) {
          errorMsg = e.toString();
        }
      }
    } else {
      if (repo != null) {
        try {
          final serverFields =
              jsonDecode(conflict.serverPayload) as Map<String, dynamic>;
          final cachedHive = hive.cardsBox.get(conflict.entityId);
          if (cachedHive != null) {
            final serverCard = repo
                .cardFromHivePublic(cachedHive)
                .copyWith(
                  title: serverFields['title'] as String? ?? cachedHive.title,
                  description:
                      serverFields['description'] as String? ??
                      cachedHive.description,
                );
            await hive.cardsBox.put(
              serverCard.id,
              repo.cardToHivePublic(serverCard),
            );
            ref
                .read(boardDetailProvider.notifier)
                .replaceCardPublic(conflict.boardId, serverCard);
          }
        } catch (e) {
          errorMsg = e.toString();
        }
      }
    }

    if (repo != null) {
      await repo.logConflictResolution(
        entityType: conflict.entityType,
        entityId: conflict.entityId,
        keepLocal: keepLocal,
        error: errorMsg ?? '',
      );
    }

    await hive.conflictsBox.delete(conflictId);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg != null
                ? '${l10n.unknownError}: $errorMsg'
                : keepLocal
                ? l10n.conflictResolvedLocal
                : l10n.conflictResolvedServer,
          ),
          backgroundColor: errorMsg != null
              ? AppColors.error
              : keepLocal
              ? AppColors.brand
              : AppColors.success,
        ),
      );
    }
  }

  String _capType(String t) =>
      t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1)}';
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.label,
    required this.color,
    required this.payload,
    required this.l10n,
  });

  final String label;
  final Color color;
  final String payload;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {}

    final title = data['title'] as String? ?? '-';
    final description = data['description'] as String? ?? '';
    final duedate = data['duedate'] as String?;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Row(label: l10n.cardTitleLabel.replaceAll(' *', ''), value: title),
          if (description.isNotEmpty)
            _Row(
              label: l10n.cardDescriptionLabel,
              value: description,
              maxLines: 3,
            ),
          if (duedate != null)
            _Row(label: l10n.cardDueDateLabel, value: duedate),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.maxLines = 1});
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}
