import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/main.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';

class CreateEditCardSheet extends ConsumerStatefulWidget {
  const CreateEditCardSheet({
    super.key,
    required this.boardId,
    required this.stackId,
    this.existing,
  });

  final int boardId;
  final int stackId;
  final DeckCard? existing;

  @override
  ConsumerState<CreateEditCardSheet> createState() =>
      _CreateEditCardSheetState();
}

class _CreateEditCardSheetState extends ConsumerState<CreateEditCardSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _dueDate;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    if (widget.existing?.hasDueDate == true) {
      _dueDate = widget.existing!.dueDateParsed;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final notifier = ref.read(boardDetailProvider.notifier);
    final dueSt = _dueDate?.toUtc().toIso8601String();

    try {
      if (_isEditing) {
        await notifier.updateCard(
          widget.boardId,
          widget.existing!.copyWith(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            duedate: dueSt,
            clearDueDate: _dueDate == null && widget.existing!.hasDueDate,
          ),
        );
      } else {
        await notifier.createCard(
          widget.boardId,
          widget.stackId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          duedate: dueSt,
        );
      }
      if (mounted) Navigator.pop(context);
    } on ConflictException {
      // A conflict was detected and stored for manual resolution.
      // Close the sheet first, then show the snackbar at the root level
      // so it appears in front of any other sheets still on screen.
      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context);
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(l10n.conflictSnackbar),
            action: SnackBarAction(
              label: l10n.conflictSnackbarAction,
              onPressed: () => context.push('/settings/conflicts'),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e is AppException ? e.userMessage : e.toString();
      });
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );
    setState(() {
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        pickedTime?.hour ?? 23,
        pickedTime?.minute ?? 59,
      );
    });
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    _isEditing ? l10n.cardEdit : l10n.cardCreate,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? l10n.save : l10n.create),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      autofocus: !_isEditing,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.cardTitleLabel,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.cardTitleLabel
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.cardDescriptionLabel,
                        hintText: l10n.cardDescriptionHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.cardDueDateLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDueDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_rounded,
                              size: 18,
                              color: AppColors.brand,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _dueDate != null
                                    ? _formatDate(_dueDate!)
                                    : l10n.cardNoDueDate,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _dueDate != null
                                      ? null
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (_dueDate != null)
                              GestureDetector(
                                onTap: () => setState(() => _dueDate = null),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
