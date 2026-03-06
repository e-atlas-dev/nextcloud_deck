import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/main.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';

class MoveCardSheet extends ConsumerStatefulWidget {
  const MoveCardSheet({
    super.key,
    required this.card,
    required this.stacks,
    required this.boardId,
  });
  final DeckCard card;
  final List<DeckStack> stacks;
  final int boardId;

  @override
  ConsumerState<MoveCardSheet> createState() => _MoveCardSheetState();
}

class _MoveCardSheetState extends ConsumerState<MoveCardSheet> {
  bool _moving = false;

  Future<void> _move(DeckStack target) async {
    if (target.id == widget.card.stackId) {
      Navigator.pop(context);
      return;
    }
    setState(() => _moving = true);
    try {
      await ref
          .read(boardDetailProvider.notifier)
          .moveCard(
            widget.boardId,
            widget.card,
            targetStackId: target.id,
            order: target.cards.length,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _moving = false);
      if (mounted) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).unknownError}: ${e is AppException ? (e).userMessage : e}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                l10n.moveCardTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.moveCardSubtitle(widget.card.title),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            if (_moving)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...widget.stacks.map((s) {
                final isCurrent = s.id == widget.card.stackId;

                return Expanded(
                  child: ListTile(
                    leading: Icon(
                      isCurrent
                          ? Icons.check_circle_rounded
                          : Icons.view_column_rounded,
                      color: isCurrent ? AppColors.brand : null,
                    ),
                    title: Text(
                      s.title,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isCurrent ? AppColors.brand : null,
                      ),
                    ),
                    subtitle: Text(l10n.moveCardCount(s.cards.length)),
                    onTap: () => _move(s),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
