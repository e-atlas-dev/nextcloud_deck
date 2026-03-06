import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/core/utils/date_formatter.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';
import 'package:nextcloud_deck/presentation/widgets/create_card_sheet.dart';
import 'package:nextcloud_deck/presentation/widgets/move_card_sheet.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    super.key,
    required this.boardId,
    required this.stackId,
    required this.cardId,
  });

  factory CardDetailScreen.sheet({
    required int boardId,
    required int stackId,
    required int cardId,
  }) => CardDetailScreen(boardId: boardId, stackId: stackId, cardId: cardId);

  final int boardId;
  final int stackId;
  final int cardId;

  DeckCard? _findCard(List<DeckStack> stacks) {
    for (final s in stacks) {
      for (final c in s.cards) {
        if (c.id == cardId) return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stacksAsync = ref.watch(boardStacksProvider(boardId));
    return stacksAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 200,
        child: Center(
          child: Text(e is AppException ? (e).userMessage : e.toString()),
        ),
      ),
      data: (stacks) {
        final card = _findCard(stacks);
        if (card == null) {
          return SizedBox(
            height: 200,
            child: Center(child: Text(l10n.unknownError)),
          );
        }
        return _CardDetailBody(card: card, allStacks: stacks, boardId: boardId);
      },
    );
  }
}

class _CardDetailBody extends ConsumerWidget {
  const _CardDetailBody({
    required this.card,
    required this.allStacks,
    required this.boardId,
  });
  final DeckCard card;
  final List<DeckStack> allStacks;
  final int boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stackName = allStacks
        .firstWhere((s) => s.id == card.stackId, orElse: () => allStacks.first)
        .title;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: l10n.cardEdit,
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CreateEditCardSheet(
                      boardId: boardId,
                      stackId: card.stackId,
                      existing: card,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'move', child: Text(l10n.cardMove)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l10n.cardDelete,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'move') {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => MoveCardSheet(
                          card: card,
                          stacks: allStacks,
                          boardId: boardId,
                        ),
                      );
                    } else if (v == 'delete') {
                      _confirmDelete(context, ref, l10n);
                    }
                  },
                ),
              ],
            ),
          ),
          // Stack badge
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.view_column_rounded,
                  size: 14,
                  color: AppColors.lightTextMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  stackName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // Labels
                if (card.labels.isNotEmpty) ...[
                  _SectionTitle(l10n.cardLabelsLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: card.labels
                        .map((lbl) => _LabelChip(label: lbl))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                // Due date
                _SectionTitle(l10n.cardDueDateLabel),
                const SizedBox(height: 8),
                _DueDateRow(card: card, l10n: l10n),
                const SizedBox(height: 20),
                // Assignees
                if (card.assignedUsers.isNotEmpty) ...[
                  _SectionTitle(l10n.cardAssigneesLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: card.assignedUsers
                        .map((u) => _AssigneeChip(user: u))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                // Description
                _SectionTitle(l10n.cardDescriptionLabel),
                const SizedBox(height: 8),
                if (card.description.isEmpty)
                  Text(
                    l10n.cardNoDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: MarkdownBody(
                      data: card.description,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme),
                    ),
                  ),
                const SizedBox(height: 20),
                // Metadata
                _SectionTitle(l10n.cardDetailsLabel),
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  label: l10n.cardCreatedLabel,
                  value: DateFormatter.formatEpoch(card.createdAt),
                ),
                if (card.owner != null)
                  _MetaRow(
                    icon: Icons.person_rounded,
                    label: l10n.cardOwnerLabel,
                    value: card.owner!.displayName,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    Navigator.pop(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cardDelete),
        content: Text(l10n.cardDeleteConfirm(card.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(boardDetailProvider.notifier).deleteCard(boardId, card);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );
}

class _DueDateRow extends StatelessWidget {
  const _DueDateRow({required this.card, required this.l10n});
  final DeckCard card;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (!card.hasDueDate) {
      return Text(
        l10n.cardNoDueDate,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final due = card.dueDateParsed!;
    Color bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    Color fg = Theme.of(context).colorScheme.onSurface;
    if (card.isOverdue) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
    } else if (card.isDueToday) {
      bg = AppColors.warningLight;
      fg = const Color(0xFFA0700A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            DateFormatter.formatDateTime(due),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (card.isOverdue) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.cardOverdue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});
  final DeckLabel label;
  @override
  Widget build(BuildContext context) {
    final color = label.flutterColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({required this.user});
  final DeckUser user;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : l10n.unknownValue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.brand.withValues(alpha: 0.2),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          user.displayName,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
