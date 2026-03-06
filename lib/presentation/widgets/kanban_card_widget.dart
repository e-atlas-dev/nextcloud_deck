import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/core/utils/date_formatter.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';
import 'package:nextcloud_deck/presentation/screens/card_detail_screen.dart';
import 'package:nextcloud_deck/presentation/widgets/move_card_sheet.dart';

class KanbanCardWidget extends ConsumerWidget {
  const KanbanCardWidget({
    super.key,
    required this.card,
    required this.allStacks,
    required this.boardId,
  });

  final DeckCard card;
  final List<DeckStack> allStacks;
  final int boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Draggable<DeckCard>(
      data: card,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 280,
          child: _CardBody(
            card: card,
            boardId: boardId,
            allStacks: allStacks,
            isDark: isDark,
            theme: theme,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _CardBody(
          card: card,
          boardId: boardId,
          allStacks: allStacks,
          isDark: isDark,
          theme: theme,
        ),
      ),
      child: _CardBody(
        card: card,
        boardId: boardId,
        allStacks: allStacks,
        isDark: isDark,
        theme: theme,
      ),
    );
  }
}

class _CardBody extends ConsumerWidget {
  const _CardBody({
    required this.card,
    required this.boardId,
    required this.allStacks,
    required this.isDark,
    required this.theme,
  });
  final DeckCard card;
  final int boardId;
  final List<DeckStack> allStacks;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overdue = card.isOverdue;
    final dueToday = card.isDueToday;

    Color? dueBg, dueText;
    if (overdue) {
      dueBg = AppColors.errorLight;
      dueText = AppColors.error;
    } else if (dueToday) {
      dueBg = AppColors.warningLight;
      dueText = const Color(0xFFA0700A);
    }

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => CardDetailScreen.sheet(
          boardId: boardId,
          stackId: card.stackId,
          cardId: card.id,
        ),
      ),
      onLongPress: () => _showContextMenu(context, ref, l10n),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: overdue
                ? AppColors.error.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              card.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Labels
            if (card.labels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: card.labels
                    .map((l10n) => _LabelChip(label: l10n))
                    .toList(),
              ),
            ],
            // Due date
            if (card.hasDueDate) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: dueBg ?? theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      overdue
                          ? Icons.warning_amber_rounded
                          : Icons.schedule_rounded,
                      size: 12,
                      color: dueText ?? theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      card.dueDateParsed != null
                          ? DateFormatter.formatDue(card.dueDateParsed!, l10n)
                          : '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: dueText ?? theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Assignees
            if (card.assignedUsers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ...card.assignedUsers
                      .take(3)
                      .map(
                        (u) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _UserAvatar(user: u, size: 22),
                        ),
                      ),
                  if (card.assignedUsers.length > 3)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      child: Center(
                        child: Text(
                          '+${card.assignedUsers.length - 3}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            // Description indicator
            if (card.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    l10n.cardHasDescription,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                card.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: Text(l10n.cardViewEdit),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => CardDetailScreen.sheet(
                    boardId: boardId,
                    stackId: card.stackId,
                    cardId: card.id,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: Text(l10n.cardMove),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MoveCardSheet(
                    card: card,
                    stacks: allStacks,
                    boardId: boardId,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: Text(
                l10n.cardDelete,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref, l10n);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
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

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});
  final DeckLabel label;
  @override
  Widget build(BuildContext context) {
    final color = label.flutterColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.size});
  final DeckUser user;
  final double size;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : l10n.unknownValue;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.brand.withValues(alpha: 0.2),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
          color: AppColors.brand,
        ),
      ),
    );
  }
}
