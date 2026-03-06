import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';

class FilterSortSheet extends ConsumerWidget {
  const FilterSortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Text(
                  l10n.filterTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (filter.hasActiveFilter)
                  TextButton(
                    onPressed: notifier.reset,
                    child: Text(l10n.filterClear),
                  ),
              ],
            ),
          ),
          const Divider(height: 16),
          // Filters
          SwitchListTile(
            title: Text(l10n.filterAssignedToMe),
            secondary: const Icon(Icons.person_rounded),
            value: filter.assignedToMe,
            onChanged: (_) => notifier.toggleAssignedToMe(),
            activeThumbColor: AppColors.brand,
          ),
          SwitchListTile(
            title: Text(l10n.filterOverdue),
            secondary: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
            ),
            value: filter.overdueOnly,
            onChanged: (_) => notifier.toggleOverdue(),
            activeThumbColor: AppColors.brand,
          ),
          SwitchListTile(
            title: Text(l10n.filterHasDueDate),
            secondary: const Icon(Icons.event_rounded),
            value: filter.dueDateOnly,
            onChanged: (_) => notifier.toggleDueDateOnly(),
            activeThumbColor: AppColors.brand,
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Sort
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(
              l10n.sortSectionTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<SortOption>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.brandLight,
                selectedForegroundColor: AppColors.brand,
              ),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: SortOption.order,
                  label: Text(l10n.sortOrder),
                  icon: const Icon(Icons.list_rounded),
                ),
                ButtonSegment(
                  value: SortOption.dueDate,
                  label: Text(l10n.sortDueDate),
                  icon: const Icon(Icons.event_rounded),
                ),
                ButtonSegment(
                  value: SortOption.alphabetical,
                  label: Text(l10n.sortAlphabetical),
                  icon: const Icon(Icons.sort_by_alpha_rounded),
                ),
              ],
              selected: {filter.sortOption},
              onSelectionChanged: (selected) =>
                  notifier.setSort(selected.first),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.filterApply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
