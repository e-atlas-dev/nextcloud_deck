import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/presentation/providers/app_providers.dart';
import 'package:nextcloud_deck/presentation/providers/settings_provider.dart';

// BOARDS

class BoardsNotifier extends AsyncNotifier<List<DeckBoard>> {
  @override
  Future<List<DeckBoard>> build() async {
    // Use ref.watch so this notifier rebuilds when the repository becomes
    // available (i.e. after credentials load from SecureStorage on first run).
    final repo = ref.watch(boardsRepositoryProvider);
    if (repo == null) return [];
    // Drain any queued offline operations now that the API is available.
    final api = ref.read(deckApiServiceProvider);
    if (api != null) {
      unawaited(ref.read(syncQueueServiceProvider).drainIfNeeded(api));
    }
    final boards = await repo.getBoards();
    _syncVersionInfo();
    return boards;
  }

  Future<List<DeckBoard>> _fetch() async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return [];
    final boards = await repo.getBoards();
    _syncVersionInfo();
    return boards;
  }

  /// Calls the Nextcloud capabilities endpoint and persists the server and
  /// Deck plugin versions. Silently swallowed on any error so a network
  /// hiccup or a server without the Deck app never breaks the board list.
  Future<void> _syncVersionInfo() async {
    try {
      final api = ref.read(deckApiServiceProvider);
      if (api == null) return;
      final response = await api.getCapabilities();
      final ocs = response['ocs'] as Map<String, dynamic>?;
      final data = ocs?['data'] as Map<String, dynamic>?;
      if (data == null) return;
      final serverVersion =
          (data['version'] as Map<String, dynamic>?)?['string'] as String? ??
          '';
      final caps = data['capabilities'] as Map<String, dynamic>?;
      final deckVersion =
          (caps?['deck'] as Map<String, dynamic>?)?['version'] as String? ?? '';
      if (serverVersion.isEmpty && deckVersion.isEmpty) return;
      await ref
          .read(settingsProvider.notifier)
          .updateVersionInfo(
            serverVersion: serverVersion,
            deckVersion: deckVersion,
          );
    } catch (_) {
      // Version info is informational - never surface these errors to the UI.
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    // Clear per-board stack cache so boards re-fetch stacks on next open
    ref.read(boardDetailProvider.notifier).clearAll();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> createBoard({
    required String title,
    required String color,
  }) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    final board = await repo.createBoard(title: title, color: color);
    final boards = state.value ?? [];
    state = AsyncData([...boards, board]);
  }

  Future<void> updateBoard(DeckBoard board) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    final updated = await repo.updateBoard(board);
    final boards = state.value ?? [];
    state = AsyncData(
      boards.map((b) => b.id == updated.id ? updated : b).toList(),
    );
  }

  Future<void> deleteBoard(int boardId) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    await repo.deleteBoard(boardId);
    final boards = state.value ?? [];
    state = AsyncData(boards.where((b) => b.id != boardId).toList());
  }
}

final boardsProvider = AsyncNotifierProvider<BoardsNotifier, List<DeckBoard>>(
  BoardsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// BOARD DETAIL STATE
//
// Riverpod 3.x removed FamilyAsyncNotifier / AsyncNotifierProviderFamily.
// We replace the family pattern with:
//   • A single NotifierProvider<BoardDetailNotifier, BoardDetailState> that
//     holds a Map<boardId, AsyncValue<List<DeckStack>>> for ALL boards.
//   • A derived Provider.family that projects one board's stacks out of the map.
//
// Usage in screens:
//   READ  → ref.watch(boardStacksProvider(boardId))
//   WRITE → ref.read(boardDetailProvider.notifier).createCard(boardId, ...)
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of all per-board stack/card data.
class BoardDetailState {
  const BoardDetailState({this.byBoardId = const {}});

  /// Stacks (with nested cards) keyed by boardId.
  final Map<int, AsyncValue<List<DeckStack>>> byBoardId;

  /// Returns the stacks for [boardId], or [AsyncLoading] if not yet fetched.
  AsyncValue<List<DeckStack>> forBoard(int boardId) =>
      byBoardId[boardId] ?? const AsyncValue.loading();

  /// Whether the board has been fetched at least once (even if empty).
  bool isLoaded(int boardId) => byBoardId[boardId]?.hasValue == true;

  BoardDetailState _set(int boardId, AsyncValue<List<DeckStack>> val) =>
      BoardDetailState(byBoardId: {...byBoardId, boardId: val});

  /// Applies [fn] to the current stacks for [boardId] (no operation if not loaded).
  BoardDetailState _map(
    int boardId,
    List<DeckStack> Function(List<DeckStack>) fn,
  ) {
    final current = byBoardId[boardId];
    if (current == null || !current.hasValue) return this;
    return _set(boardId, AsyncData(fn(current.requireValue)));
  }
}

class BoardDetailNotifier extends Notifier<BoardDetailState> {
  @override
  BoardDetailState build() => const BoardDetailState();

  // Load / refresh

  /// Clears all cached board data (called when user triggers a full sync).
  void clearAll() => state = const BoardDetailState();

  /// Publicly exposes the private _replaceCard helper so that screens outside
  /// the provider (e.g. ConflictResolutionScreen) can push a resolved card
  /// into the in-memory board state without triggering a full reload.
  void replaceCardPublic(int boardId, DeckCard card) =>
      _replaceCard(boardId, card);

  Future<void> loadBoard(int boardId) async {
    state = state._set(boardId, const AsyncValue.loading());
    try {
      final repo = ref.read(boardsRepositoryProvider);
      if (repo == null) {
        state = state._set(boardId, const AsyncData([]));
        return;
      }
      final stacks = await repo.getStacksForBoard(boardId);
      state = state._set(boardId, AsyncData(stacks));
    } catch (e, st) {
      state = state._set(boardId, AsyncValue.error(e, st));
    }
  }

  Future<void> refresh(int boardId) => loadBoard(boardId);

  // Stacks

  Future<void> createStack(int boardId, String title) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    final stack = await repo.createStack(boardId, title: title);
    state = state._map(boardId, (stacks) => [...stacks, stack]);
  }

  Future<void> renameStack(int boardId, int stackId, String title) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    final updated = await repo.renameStack(boardId, stackId, title);
    state = state._map(
      boardId,
      (stacks) => stacks.map((s) => s.id == stackId ? updated : s).toList(),
    );
  }

  Future<void> deleteStack(int boardId, int stackId) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    await repo.deleteStack(boardId, stackId);
    state = state._map(
      boardId,
      (stacks) => stacks.where((s) => s.id != stackId).toList(),
    );
  }

  // Cards

  Future<void> createCard(
    int boardId,
    int stackId, {
    required String title,
    String description = '',
    String? duedate,
  }) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    final card = await repo.createCard(
      boardId,
      stackId,
      title: title,
      description: description,
      duedate: duedate,
    );
    state = state._map(
      boardId,
      (stacks) => stacks.map((s) {
        if (s.id != stackId) return s;
        return s.copyWith(cards: [...s.cards, card]);
      }).toList(),
    );
  }

  Future<void> updateCard(int boardId, DeckCard card) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    final resolution = ref.read(settingsProvider).conflictResolution;
    try {
      final updated = await repo.updateCard(card, resolution: resolution);
      _replaceCard(boardId, updated);
    } on ConflictException {
      // Card was updated by another user and resolution is 'ask' -
      // the conflict has already been recorded in Hive. Rethrow so the
      // UI can show a snackbar prompting the user to visit Settings → Conflicts.
      rethrow;
    }
  }

  Future<void> deleteCard(int boardId, DeckCard card) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;
    await repo.deleteCard(card);
    state = state._map(
      boardId,
      (stacks) => stacks.map((s) {
        if (s.id != card.stackId) return s;
        return s.copyWith(
          cards: s.cards.where((c) => c.id != card.id).toList(),
        );
      }).toList(),
    );
  }

  Future<void> moveCard(
    int boardId,
    DeckCard card, {
    required int targetStackId,
    required int order,
  }) async {
    final repo = ref.read(boardsRepositoryProvider);
    if (repo == null) return;

    // Optimistic: remove from old stack, insert into target
    _removeCard(boardId, card.stackId, card.id);
    final optimistic = card.copyWith(stackId: targetStackId, order: order);
    _insertCard(boardId, targetStackId, optimistic);

    try {
      final serverCard = await repo.moveCard(
        card,
        targetStackId: targetStackId,
        order: order,
      );
      _replaceCard(boardId, serverCard);
    } catch (e) {
      // Revert on failure
      _removeCard(boardId, targetStackId, card.id);
      _insertCard(boardId, card.stackId, card);
      rethrow;
    }
  }

  // Private helpers

  void _replaceCard(int boardId, DeckCard updated) {
    state = state._map(
      boardId,
      (stacks) => stacks.map((stack) {
        // Remove old copy from every stack (handles cross-stack moves)
        final cleaned = stack.cards.where((c) => c.id != updated.id).toList();
        if (stack.id == updated.stackId) {
          return stack.copyWith(cards: [...cleaned, updated]);
        }
        return stack.copyWith(cards: cleaned);
      }).toList(),
    );
  }

  void _insertCard(int boardId, int stackId, DeckCard card) {
    state = state._map(
      boardId,
      (stacks) => stacks.map((s) {
        if (s.id != stackId) return s;
        return s.copyWith(cards: [...s.cards, card]);
      }).toList(),
    );
  }

  void _removeCard(int boardId, int stackId, int cardId) {
    state = state._map(
      boardId,
      (stacks) => stacks.map((s) {
        if (s.id != stackId) return s;
        return s.copyWith(cards: s.cards.where((c) => c.id != cardId).toList());
      }).toList(),
    );
  }
}

final boardDetailProvider =
    NotifierProvider<BoardDetailNotifier, BoardDetailState>(
      BoardDetailNotifier.new,
    );

/// Derived read-only provider: projects a single board's stacks from the Map.
/// Using this automatically triggers a load on first watch via [_boardLoaderProvider].
final boardStacksProvider = Provider.family<AsyncValue<List<DeckStack>>, int>((
  ref,
  boardId,
) {
  // Ensure the board is loaded the first time this provider is watched.
  ref.watch(_boardLoaderProvider(boardId));
  return ref.watch(boardDetailProvider).forBoard(boardId);
});

/// Side-effect-only provider that triggers a board load exactly once per boardId.
final _boardLoaderProvider = Provider.autoDispose.family<void, int>((
  ref,
  boardId,
) {
  final notifier = ref.read(boardDetailProvider.notifier);
  if (!ref.read(boardDetailProvider).isLoaded(boardId)) {
    Future.microtask(() => notifier.loadBoard(boardId));
  }
});

// FILTER / SORT STATE

enum SortOption { order, dueDate, createdDate, alphabetical }

/// Immutable filter + sort state.
/// [apply] lives here (not on FilterNotifier) so it can be called directly on
/// the watched state: `final filtered = ref.watch(filterProvider).apply(cards)`.
class FilterState {
  const FilterState({
    this.assignedToMe = false,
    this.overdueOnly = false,
    this.dueDateOnly = false,
    this.labelFilter,
    this.searchQuery = '',
    this.sortOption = SortOption.order,
    this.currentUsername,
  });

  final bool assignedToMe;
  final bool overdueOnly;
  final bool dueDateOnly;

  final DeckLabel? labelFilter;

  /// Case-insensitive substring match against card title and description.
  final String searchQuery;

  final SortOption sortOption;
  final String? currentUsername;

  bool get hasActiveFilter =>
      assignedToMe ||
      overdueOnly ||
      dueDateOnly ||
      labelFilter != null ||
      searchQuery.trim().isNotEmpty;

  FilterState copyWith({
    bool? assignedToMe,
    bool? overdueOnly,
    bool? dueDateOnly,
    DeckLabel? labelFilter,
    String? searchQuery,
    SortOption? sortOption,
    bool clearLabel = false,
    String? currentUsername,
  }) => FilterState(
    assignedToMe: assignedToMe ?? this.assignedToMe,
    overdueOnly: overdueOnly ?? this.overdueOnly,
    dueDateOnly: dueDateOnly ?? this.dueDateOnly,
    labelFilter: clearLabel ? null : (labelFilter ?? this.labelFilter),
    searchQuery: searchQuery ?? this.searchQuery,
    sortOption: sortOption ?? this.sortOption,
    currentUsername: currentUsername ?? this.currentUsername,
  );

  // apply

  /// Applies all active filters and sort to [cards].
  ///
  /// • Always returns a **new list** - never mutates the input.
  /// • All comparisons are stable (tie-broken by [DeckCard.order]).
  /// • Archived and deleted cards are stripped before filtering.
  List<DeckCard> apply(List<DeckCard> cards) {
    var result = cards.where((c) => !c.archived && c.deletedAt == 0).toList();

    // Text search
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (c) =>
                c.title.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q),
          )
          .toList();
    }

    // Assigned to me
    if (assignedToMe && currentUsername != null) {
      result = result
          .where((c) => c.assignedUsers.any((u) => u.uid == currentUsername))
          .toList();
    }

    // Overdue
    if (overdueOnly) {
      result = result.where((c) => c.isOverdue).toList();
    }

    // Has due date
    if (dueDateOnly) {
      result = result.where((c) => c.hasDueDate).toList();
    }

    // Label filter
    if (labelFilter != null) {
      result = result
          .where((c) => c.labels.any((l) => l.id == labelFilter!.id))
          .toList();
    }

    // Sort
    result.sort(_comparator);

    return result;
  }

  int Function(DeckCard, DeckCard) get _comparator {
    switch (sortOption) {
      case SortOption.order:
        return (a, b) => a.order.compareTo(b.order);

      case SortOption.dueDate:
        return (a, b) {
          final da = a.dueDateParsed;
          final db = b.dueDateParsed;
          // Null due dates sink to the bottom
          if (da == null && db == null) return a.order.compareTo(b.order);
          if (da == null) return 1;
          if (db == null) return -1;
          final cmp = da.compareTo(db);
          return cmp != 0 ? cmp : a.order.compareTo(b.order);
        };

      case SortOption.createdDate:
        return (a, b) {
          final cmp = a.createdAt.compareTo(b.createdAt);
          return cmp != 0 ? cmp : a.order.compareTo(b.order);
        };

      case SortOption.alphabetical:
        return (a, b) {
          final cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          return cmp != 0 ? cmp : a.order.compareTo(b.order);
        };
    }
  }
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setUsername(String? username) =>
      state = state.copyWith(currentUsername: username);

  void toggleAssignedToMe() =>
      state = state.copyWith(assignedToMe: !state.assignedToMe);

  void toggleOverdue() =>
      state = state.copyWith(overdueOnly: !state.overdueOnly);

  void toggleDueDateOnly() =>
      state = state.copyWith(dueDateOnly: !state.dueDateOnly);

  void setLabel(DeckLabel? label) =>
      state = state.copyWith(labelFilter: label, clearLabel: label == null);

  void setSort(SortOption sort) => state = state.copyWith(sortOption: sort);

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void reset() => state = FilterState(currentUsername: state.currentUsername);
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
);
