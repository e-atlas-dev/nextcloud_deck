import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';
import 'package:nextcloud_deck/presentation/widgets/app_icon_widget.dart';
import 'package:nextcloud_deck/presentation/widgets/create_board_dialog.dart';
import 'package:nextcloud_deck/presentation/widgets/offline_banner_widget.dart';

class BoardsListScreen extends ConsumerWidget {
  const BoardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final boardsAsync = ref.watch(boardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.boardsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => showSearch(
              context: context,
              delegate: _BoardSearchDelegate(ref, l10n),
            ),
            tooltip: l10n.searchHint,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.go('/settings'),
            tooltip: l10n.settingsTitle,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBannerWidget(),
          Expanded(
            child: boardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e is Exception
                    ? (e is AppException ? (e).userMessage : e.toString())
                    : e.toString(),
                onRetry: () => ref.invalidate(boardsProvider),
              ),
              data: (boards) => _BoardsGrid(boards: boards),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => CreateBoardDialog(ref: ref),
        ),
        tooltip: l10n.boardCreate,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _BoardsGrid extends ConsumerWidget {
  const _BoardsGrid({required this.boards});
  final List<DeckBoard> boards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = boards.where((b) => !b.archived).toList();
    final archived = boards.where((b) => b.archived).toList();

    if (boards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.45,
              child: AppIcon(
                size: 64,
                fallbackColor: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.boardsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.boardsEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(boardsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (active.isNotEmpty) _BoardGrid(boards: active),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(l10n.boardsArchivedSection(archived.length)),
            const SizedBox(height: 12),
            _BoardGrid(boards: archived),
          ],
        ],
      ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.boards});
  final List<DeckBoard> boards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 140,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: boards.length,
      itemBuilder: (ctx, i) => _BoardCard(board: boards[i]),
    );
  }
}

class _BoardCard extends ConsumerWidget {
  const _BoardCard({required this.board});
  final DeckBoard board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = board.flutterColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.go(
        '/board/${board.id}?title=${Uri.encodeComponent(board.title)}&color=${board.color}',
      ),
      onLongPress: () => _showContextMenu(context, ref, l10n),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: isDark ? 0.25 : 0.12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 0.25),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      board.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      if (board.archived)
                        const Icon(
                          Icons.archive_rounded,
                          size: 14,
                          color: AppColors.lightTextMuted,
                        ),
                      if (board.shared > 0) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.people_rounded,
                          size: 14,
                          color: AppColors.lightTextMuted,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
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
                board.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.boardEdit),
              onTap: () {
                Navigator.pop(ctx);
                showDialog<void>(
                  context: context,
                  builder: (_) => CreateBoardDialog(ref: ref, existing: board),
                );
              },
            ),
            ListTile(
              leading: Icon(
                board.archived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
              ),
              title: Text(
                board.archived ? l10n.boardUnarchive : l10n.boardArchive,
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(boardsProvider.notifier)
                    .updateBoard(board.copyWith(archived: !board.archived));
              },
            ),
            if (board.permissionManage)
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  l10n.boardDelete,
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
        title: Text(l10n.boardDelete),
        content: Text(l10n.boardDeleteConfirm(board.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(boardsProvider.notifier).deleteBoard(board.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.5,
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.unableToLoadUpdates,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search result that can point to a board, a stack, or a card.
class _SearchResult {
  const _SearchResult({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.boardId,
    required this.boardTitle,
    required this.boardColor,
    this.color,
  });

  /// 'board' | 'stack' | 'card'
  final String kind;
  final String title;
  final String subtitle;
  final int boardId;
  final String boardTitle;
  final String boardColor;
  final Color? color;
}

class _BoardSearchDelegate extends SearchDelegate<String> {
  _BoardSearchDelegate(this.ref, this.l10n);
  final WidgetRef ref;
  final AppLocalizations l10n;

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  List<_SearchResult> _search(String q) {
    final boards = ref.read(boardsProvider).value ?? [];
    final results = <_SearchResult>[];

    for (final board in boards) {
      // Match board title
      if (board.title.toLowerCase().contains(q)) {
        results.add(
          _SearchResult(
            kind: 'board',
            title: board.title,
            subtitle: l10n.boardsTitle,
            boardId: board.id,
            boardTitle: board.title,
            boardColor: board.color,
            color: board.flutterColor,
          ),
        );
      }

      // Match stacks
      final stacks =
          ref.read(boardDetailProvider).forBoard(board.id).value ?? [];
      for (final stack in stacks) {
        if (stack.title.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              kind: 'stack',
              title: stack.title,
              subtitle: board.title,
              boardId: board.id,
              boardTitle: board.title,
              boardColor: board.color,
              color: board.flutterColor,
            ),
          );
        }
        // Match cards within each stack
        for (final card in stack.cards) {
          if (card.title.toLowerCase().contains(q) ||
              card.description.toLowerCase().contains(q)) {
            results.add(
              _SearchResult(
                kind: 'card',
                title: card.title,
                subtitle: '${board.title} > ${stack.title}',
                boardId: board.id,
                boardTitle: board.title,
                boardColor: board.color,
                color: board.flutterColor,
              ),
            );
          }
        }
      }
    }
    return results;
  }

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return Center(child: Text(l10n.searchPrompt));

    final results = _search(q);
    if (results.isEmpty) return Center(child: Text(l10n.searchNoResults));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final r = results[i];
        final icon = switch (r.kind) {
          'stack' => Icons.view_column_rounded,
          'card' => Icons.credit_card_rounded,
          _ => Icons.space_dashboard_rounded,
        };
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: (r.color ?? AppColors.brand).withValues(
              alpha: 0.15,
            ),
            child: Icon(icon, size: 20, color: r.color ?? AppColors.brand),
          ),
          title: Text(r.title),
          subtitle: Text(
            r.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () {
            close(context, '');
            context.go(
              '/board/${r.boardId}?title=${Uri.encodeComponent(r.boardTitle)}&color=${r.boardColor}',
            );
          },
        );
      },
    );
  }
}
