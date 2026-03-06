import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';
import 'package:nextcloud_deck/presentation/widgets/create_card_sheet.dart';
import 'package:nextcloud_deck/presentation/widgets/create_stack_dialog.dart';
import 'package:nextcloud_deck/presentation/widgets/filter_sort_sheet.dart';
import 'package:nextcloud_deck/presentation/widgets/kanban_card_widget.dart';
import 'package:nextcloud_deck/presentation/widgets/offline_banner_widget.dart';

class BoardKanbanScreen extends ConsumerWidget {
  const BoardKanbanScreen({
    super.key,
    required this.boardId,
    required this.boardTitle,
    required this.boardColor,
  });

  final int boardId;
  final String boardTitle;
  final String boardColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stacksAsync = ref.watch(boardStacksProvider(boardId));
    final filter = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(boardTitle),
        actions: [
          Badge(
            isLabelVisible: filter.hasActiveFilter,
            label: const Text(''),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const FilterSortSheet(),
              ),
              tooltip: l10n.filterTitle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(boardDetailProvider.notifier).refresh(boardId),
            tooltip: l10n.settingsSyncNow,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBannerWidget(),
          Expanded(
            child: stacksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                onRetry: () =>
                    ref.read(boardDetailProvider.notifier).refresh(boardId),
              ),
              data: (stacks) => _KanbanView(boardId: boardId, stacks: stacks),
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanView extends StatelessWidget {
  const _KanbanView({required this.boardId, required this.stacks});
  final int boardId;
  final List<DeckStack> stacks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: stacks.length + 1,
        itemBuilder: (ctx, i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: i == stacks.length
                ? _AddStackButton(boardId: boardId)
                : _KanbanColumn(
                    boardId: boardId,
                    stack: stacks[i],
                    allStacks: stacks,
                  ),
          );
        },
      ),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  const _KanbanColumn({
    required this.boardId,
    required this.stack,
    required this.allStacks,
  });
  final int boardId;
  final DeckStack stack;
  final List<DeckStack> allStacks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(filterProvider);
    final filteredCards = filter.apply(stack.cards);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StackHeader(
          boardId: boardId,
          stack: stack,
          cardCount: filteredCards.length,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredCards.isEmpty
              ? _EmptyStackPlaceholder(l10n: l10n)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: filteredCards.length,
                  onReorder: (oldIdx, newIdx) {
                    if (newIdx > oldIdx) newIdx--;
                    if (oldIdx == newIdx) return;
                    ref
                        .read(boardDetailProvider.notifier)
                        .moveCard(
                          boardId,
                          filteredCards[oldIdx],
                          targetStackId: stack.id,
                          order: newIdx,
                        );
                  },
                  proxyDecorator: (child, _, animation) => AnimatedBuilder(
                    animation: animation,
                    builder: (_, __) =>
                        Transform.scale(scale: 1.03, child: child),
                  ),
                  itemBuilder: (ctx, i) => Padding(
                    key: ValueKey(filteredCards[i].id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: KanbanCardWidget(
                      card: filteredCards[i],
                      allStacks: allStacks,
                      boardId: boardId,
                    ),
                  ),
                ),
        ),
        _AddCardButton(boardId: boardId, stackId: stack.id, l10n: l10n),
      ],
    );
  }
}

class _StackHeader extends ConsumerWidget {
  const _StackHeader({
    required this.boardId,
    required this.stack,
    required this.cardCount,
  });
  final int boardId;
  final DeckStack stack;
  final int cardCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stack.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$cardCount',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            padding: EdgeInsets.zero,
            iconSize: 18,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
            onSelected: (action) {
              if (action == 'rename') {
                showDialog<void>(
                  context: context,
                  builder: (_) =>
                      CreateStackDialog(boardId: boardId, existing: stack),
                );
              } else if (action == 'delete') {
                _confirmDelete(context, ref, l10n);
              }
            },
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.stackDelete),
        content: Text(l10n.stackDeleteConfirm(stack.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(boardDetailProvider.notifier)
                  .deleteStack(boardId, stack.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  const _AddCardButton({
    required this.boardId,
    required this.stackId,
    required this.l10n,
  });
  final int boardId;
  final int stackId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => CreateEditCardSheet(boardId: boardId, stackId: stackId),
      ),
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(l10n.cardCreate),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brand,
        side: const BorderSide(color: AppColors.brand, width: 1.5),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
  );
}

class _EmptyStackPlaceholder extends StatelessWidget {
  const _EmptyStackPlaceholder({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DeckCard>(
      builder: (ctx, candidates, _) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: candidates.isNotEmpty
                ? AppColors.brand
                : Theme.of(context).colorScheme.outlineVariant,
          ),
          color: candidates.isNotEmpty
              ? AppColors.brandLight
              : Colors.transparent,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.stackEmpty,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      onAcceptWithDetails: (_) {},
    );
  }
}

class _AddStackButton extends ConsumerWidget {
  const _AddStackButton({required this.boardId});
  final int boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => CreateStackDialog(boardId: boardId),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.stackCreate),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(l10n.unableToLoadBoard),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
