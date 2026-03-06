import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/storage/hive_service.dart';
import 'package:nextcloud_deck/data/models/hive/deck_hive_models.dart';
import 'package:nextcloud_deck/data/models/hive/sync_hive_models.dart';
import 'package:nextcloud_deck/data/services/deck_api_service.dart';
import 'package:nextcloud_deck/data/services/sync_queue_service.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';

const _uuid = Uuid();

class BoardsRepository {
  BoardsRepository({
    required this.apiService,
    required this.hive,
    required this.syncQueue,
  });

  final DeckApiService apiService;
  final HiveService hive;
  final SyncQueueService syncQueue;

  // Sync logging

  Future<void> _log({
    required String operation,
    required String entityType,
    required int entityId,
    required bool success,
    String errorMessage = '',
  }) async {
    try {
      await hive.syncLogsBox.add(
        SyncLogEntryHiveModel(
          id: _uuid.v4(),
          timestamp: DateTime.now().millisecondsSinceEpoch,
          operation: operation,
          entityType: entityType,
          entityId: entityId,
          status: success ? 'success' : 'failed',
          errorMessage: errorMessage,
        ),
      );
      // Keep at most 200 log entries
      final box = hive.syncLogsBox;
      if (box.length > 200) {
        final oldest = box.keys.take(box.length - 200).toList();
        for (final k in oldest) {
          await box.delete(k);
        }
      }
    } catch (_) {
      // Logging failures are silent
    }
  }

  // BOARDS

  Future<List<DeckBoard>> getBoards({bool forceRefresh = false}) async {
    try {
      final raw = await apiService.getBoards();
      // The server soft-deletes boards by setting deletedAt; exclude them so
      // they never appear in the UI (the user already dismissed them).
      final boards = raw
          .map(DeckBoard.fromJson)
          .where((b) => !b.isDeleted)
          .toList();
      await _cacheBoards(boards);
      return boards;
    } on AppException {
      return _cachedBoards();
    } catch (_) {
      return _cachedBoards();
    }
  }

  List<DeckBoard> _cachedBoards() => hive.boardsBox.values
      .map(_boardFromHive)
      .where((b) => !b.isDeleted)
      .toList();

  Future<void> _cacheBoards(List<DeckBoard> boards) async {
    // Guard: never wipe local cache with an empty server list - it almost
    // certainly means a transient error slipped past the catch blocks.
    if (boards.isEmpty && hive.boardsBox.isNotEmpty) return;

    final serverIds = boards.map((b) => b.id).toSet();
    final cachedIds = hive.boardsBox.keys.cast<int>().toSet();

    // IDs present in cache but absent from the (already-filtered) server list
    // are boards that were deleted (soft or hard) on the server.  Evict them
    // together with all their stacks and cards.
    final removedIds = cachedIds.difference(serverIds);
    for (final boardId in removedIds) {
      await hive.boardsBox.delete(boardId);
      final deadStacks = hive.stacksBox.values
          .where((s) => s.boardId == boardId)
          .toList();
      for (final s in deadStacks) {
        final deadCardKeys = hive.cardsBox.keys
            .where((k) => hive.cardsBox.get(k)?.stackId == s.id)
            .toList();
        for (final k in deadCardKeys) {
          await hive.cardsBox.delete(k);
        }
        await hive.stacksBox.delete(s.id);
      }
    }

    // Upsert the live boards - never clear() the whole box.
    for (final b in boards) {
      await hive.boardsBox.put(b.id, _boardToHive(b));
    }
  }

  Future<DeckBoard> createBoard({
    required String title,
    required String color,
  }) async {
    final raw = await apiService.createBoard(title: title, color: color);
    final board = DeckBoard.fromJson(raw);
    await hive.boardsBox.put(board.id, _boardToHive(board));
    await _log(
      operation: 'create',
      entityType: 'board',
      entityId: board.id,
      success: true,
    );
    return board;
  }

  Future<DeckBoard> updateBoard(DeckBoard board) async {
    final raw = await apiService.updateBoard(
      board.id,
      title: board.title,
      color: board.color,
      archived: board.archived,
    );
    final updated = DeckBoard.fromJson(raw);
    await hive.boardsBox.put(updated.id, _boardToHive(updated));
    await _log(
      operation: 'update',
      entityType: 'board',
      entityId: board.id,
      success: true,
    );
    return updated;
  }

  Future<void> deleteBoard(int boardId) async {
    await apiService.deleteBoard(boardId);
    await hive.boardsBox.delete(boardId);
    final stacks = hive.stacksBox.values
        .where((s) => s.boardId == boardId)
        .toList();
    for (final s in stacks) {
      final cards = hive.cardsBox.values
          .where((c) => c.stackId == s.id)
          .toList();
      for (final c in cards) {
        await hive.cardsBox.delete(c.id);
      }
      await hive.stacksBox.delete(s.id);
    }
    await _log(
      operation: 'delete',
      entityType: 'board',
      entityId: boardId,
      success: true,
    );
  }

  // STACKS

  Future<List<DeckStack>> getStacksForBoard(
    int boardId, {
    bool forceRefresh = false,
  }) async {
    try {
      final raw = await apiService.getStacks(boardId);
      final stacks = raw.map(DeckStack.fromJson).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      await _cacheStacks(boardId, stacks);
      return stacks;
    } on AppException {
      return _cachedStacks(boardId);
    } catch (_) {
      return _cachedStacks(boardId);
    }
  }

  List<DeckStack> _cachedStacks(int boardId) {
    final stacks =
        hive.stacksBox.values
            .where((s) => s.boardId == boardId && s.deletedAt == 0)
            .map(_stackFromHive)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return stacks.map((stack) {
      final cards =
          hive.cardsBox.values
              .where((c) => c.stackId == stack.id && c.deletedAt == 0)
              .map(_cardFromHive)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));
      return stack.copyWith(cards: cards);
    }).toList();
  }

  Future<void> _cacheStacks(int boardId, List<DeckStack> stacks) async {
    // Only persist non-deleted stacks
    final liveStacks = stacks.where((s) => !s.isDeleted).toList();
    final liveStackIds = liveStacks.map((s) => s.id).toSet();

    // Collect the IDs of all cards the server says belong to this board.
    final serverCardIds = <int>{};
    for (final s in liveStacks) {
      for (final c in s.cards) {
        if (!c.isDeleted) serverCardIds.add(c.id);
      }
    }

    // Delete cards in this board's stacks that the server no longer returns.
    // This covers: deleted cards, and cards moved to a different board.
    final deadCardKeys = hive.cardsBox.keys.where((k) {
      final card = hive.cardsBox.get(k);
      if (card == null) return false;
      // Only touch cards that belong to a stack owned by this board.
      final ownerStack = hive.stacksBox.get(card.stackId);
      if (ownerStack == null || ownerStack.boardId != boardId) return false;
      return !serverCardIds.contains(card.id);
    }).toList();
    for (final k in deadCardKeys) {
      await hive.cardsBox.delete(k);
    }

    // Delete stacks for this board that the server no longer returns.
    final deadStackKeys = hive.stacksBox.keys.where((k) {
      final s = hive.stacksBox.get(k);
      return s != null && s.boardId == boardId && !liveStackIds.contains(s.id);
    }).toList();
    for (final k in deadStackKeys) {
      await hive.stacksBox.delete(k);
    }

    // Upsert live stacks and their cards.
    for (final s in liveStacks) {
      await hive.stacksBox.put(s.id, _stackToHive(s));
      for (final c in s.cards.where((c) => !c.isDeleted)) {
        await hive.cardsBox.put(c.id, _cardToHive(c));
      }
    }
  }

  Future<DeckStack> createStack(int boardId, {required String title}) async {
    final count = hive.stacksBox.values
        .where((s) => s.boardId == boardId)
        .length;
    final raw = await apiService.createStack(
      boardId,
      title: title,
      order: count,
    );
    final stack = DeckStack.fromJson(raw).copyWith(cards: []);
    await hive.stacksBox.put(stack.id, _stackToHive(stack));
    await _log(
      operation: 'create',
      entityType: 'stack',
      entityId: stack.id,
      success: true,
    );
    return stack;
  }

  Future<DeckStack> renameStack(int boardId, int stackId, String title) async {
    final existing = hive.stacksBox.get(stackId);
    final raw = await apiService.updateStack(
      boardId,
      stackId,
      title: title,
      order: existing?.order ?? 0,
    );
    final updated = DeckStack.fromJson(raw).copyWith(
      cards: _cachedStacks(boardId)
          .firstWhere(
            (s) => s.id == stackId,
            orElse: () => DeckStack.fromJson(raw),
          )
          .cards,
    );
    await hive.stacksBox.put(stackId, _stackToHive(updated));
    await _log(
      operation: 'update',
      entityType: 'stack',
      entityId: stackId,
      success: true,
    );
    return updated;
  }

  Future<void> deleteStack(int boardId, int stackId) async {
    await apiService.deleteStack(boardId, stackId);
    await hive.stacksBox.delete(stackId);
    final cardKeys = hive.cardsBox.keys
        .where((k) => hive.cardsBox.get(k)?.stackId == stackId)
        .toList();
    for (final k in cardKeys) {
      await hive.cardsBox.delete(k);
    }
    await _log(
      operation: 'delete',
      entityType: 'stack',
      entityId: stackId,
      success: true,
    );
  }

  // CARDS

  Future<DeckCard> createCard(
    int boardId,
    int stackId, {
    required String title,
    String description = '',
    String? duedate,
  }) async {
    try {
      final raw = await apiService.createCard(
        boardId,
        stackId,
        title: title,
        description: description,
        duedate: duedate,
      );
      final card = DeckCard.fromJson(raw);
      await hive.cardsBox.put(card.id, _cardToHive(card));
      await _log(
        operation: 'create',
        entityType: 'card',
        entityId: card.id,
        success: true,
      );
      return card;
    } on NetworkException {
      // Offline - create a temporary local card with a negative ID so it can
      // be displayed immediately. Queue the real create for when we reconnect.
      await syncQueue.enqueueCreateCard(
        boardId: boardId,
        stackId: stackId,
        title: title,
        description: description,
        duedate: duedate,
      );
      final tempId = -(DateTime.now().millisecondsSinceEpoch);
      final tempCard = DeckCard(
        id: tempId,
        title: title,
        description: description,
        stackId: stackId,
        boardId: boardId,
        order: 9999,
        archived: false,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        lastModified: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        deletedAt: 0,
        duedate: duedate,
        labels: const [],
        assignedUsers: const [],
        owner: null,
        type: 'plain',
      );
      await hive.cardsBox.put(tempCard.id, _cardToHive(tempCard));
      await _log(
        operation: 'create',
        entityType: 'card',
        entityId: 0,
        success: false,
        errorMessage: 'Queued offline',
      );
      return tempCard;
    }
  }

  Future<DeckCard> updateCard(
    DeckCard card, {
    ConflictResolutionPreference resolution = ConflictResolutionPreference.ask,
  }) async {
    final fields = {
      'title': card.title,
      'description': card.description,
      'type': card.type.isEmpty ? 'plain' : card.type,
      'owner': card.owner?.uid ?? '',
      'stackId': card.stackId,
      'order': card.order,
      'archived': card.archived,
      if (card.duedate != null) 'duedate': card.duedate,
    };

    // Conflict detection via lastModified
    // Only run when we can reach the server (skip if already offline).
    if (resolution == ConflictResolutionPreference.ask ||
        resolution == ConflictResolutionPreference.keepServer) {
      final serverCard = await _fetchServerCard(
        card.boardId,
        card.stackId,
        card.id,
      );
      if (serverCard != null && serverCard.lastModified > card.lastModified) {
        switch (resolution) {
          case ConflictResolutionPreference.keepServer:
            await hive.cardsBox.put(serverCard.id, _cardToHive(serverCard));
            await _log(
              operation: 'update',
              entityType: 'card',
              entityId: card.id,
              success: true,
              errorMessage: 'Conflict auto-resolved: kept server version.',
            );
            return serverCard;
          case ConflictResolutionPreference.ask:
            await _recordConflict(
              card: card,
              serverCard: serverCard,
              localFields: fields,
            );
            await _log(
              operation: 'update',
              entityType: 'card',
              entityId: card.id,
              success: false,
              errorMessage: 'Conflict detected.',
            );
            throw ConflictException(
              'Card "${card.title}" was modified by another user since your last sync. '
              'Go to Settings > Conflicts to resolve.',
            );
          case ConflictResolutionPreference.keepLocal:
            break; // fall through to write
        }
      }
    }

    // Write
    try {
      final raw = await apiService.updateCard(
        card.boardId,
        card.stackId,
        card.id,
        fields: fields,
      );
      final updated = DeckCard.fromJson(raw);
      await hive.cardsBox.put(updated.id, _cardToHive(updated));
      await _log(
        operation: 'update',
        entityType: 'card',
        entityId: card.id,
        success: true,
      );
      return updated;
    } on NetworkException {
      // Offline - apply change locally and queue for later
      await syncQueue.enqueueUpdateCard(card);
      await hive.cardsBox.put(card.id, _cardToHive(card));
      await _log(
        operation: 'update',
        entityType: 'card',
        entityId: card.id,
        success: false,
        errorMessage: 'Queued offline',
      );
      return card;
    } catch (e) {
      await _log(
        operation: 'update',
        entityType: 'card',
        entityId: card.id,
        success: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Fetch the server's live copy of a single card to enable conflict detection.
  Future<DeckCard?> _fetchServerCard(
    int boardId,
    int stackId,
    int cardId,
  ) async {
    try {
      // getStack returns the stack object; cards are in the 'cards' array.
      final stackRaw = await apiService.getStack(boardId, stackId);
      final cardsRaw = stackRaw['cards'] as List<dynamic>? ?? [];
      for (final c in cardsRaw) {
        final card = c as Map<String, dynamic>;
        if (card['id'] == cardId) return DeckCard.fromJson(card);
      }
      return null;
    } on NetworkException {
      return null; // Offline - skip conflict check, proceed with write
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCard(DeckCard card) async {
    try {
      await apiService.deleteCard(card.boardId, card.stackId, card.id);
      await hive.cardsBox.delete(card.id);
      await _log(
        operation: 'delete',
        entityType: 'card',
        entityId: card.id,
        success: true,
      );
    } on NetworkException {
      // Offline - remove locally and queue
      await syncQueue.enqueueDeleteCard(card);
      await hive.cardsBox.delete(card.id);
      await _log(
        operation: 'delete',
        entityType: 'card',
        entityId: card.id,
        success: false,
        errorMessage: 'Queued offline',
      );
    } catch (e) {
      await _log(
        operation: 'delete',
        entityType: 'card',
        entityId: card.id,
        success: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<DeckCard> moveCard(
    DeckCard card, {
    required int targetStackId,
    required int order,
  }) async {
    try {
      final raw = await apiService.moveCard(
        card.boardId,
        card.stackId,
        card.id,
        order: order,
        targetStackId: targetStackId,
      );

      await _log(
        operation: 'update',
        entityType: 'card',
        entityId: card.id,
        success: true,
      );

      return DeckCard.fromJson(raw);
    } catch (e) {
      await _log(
        operation: 'update',
        entityType: 'card',
        entityId: card.id,
        success: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Conflict recording

  /// Fetches the server's current version of [card] and records a ConflictItem
  /// so the user can decide which version to keep.
  Future<void> _recordConflict({
    required DeckCard card,
    required DeckCard serverCard,
    required Map<String, dynamic> localFields,
  }) async {
    try {
      await hive.conflictsBox.put(
        card.id.toString(),
        ConflictItemHiveModel(
          id: card.id.toString(),
          entityType: 'card',
          entityId: card.id,
          boardId: card.boardId,
          stackId: card.stackId,
          localPayload: jsonEncode(localFields),
          serverPayload: jsonEncode(serverCard.toJson()),
          detectedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (_) {
      // Conflict recording failures are silent - the user already sees an error.
    }
  }

  // Labels

  Future<DeckLabel> createLabel(
    int boardId, {
    required String title,
    required String color,
  }) async {
    final raw = await apiService.createLabel(
      boardId,
      title: title,
      color: color,
    );
    final label = DeckLabel.fromJson(raw);
    await hive.labelsBox.put(label.id, _labelToHive(label, boardId));
    return label;
  }

  List<DeckLabel> getLabelsForBoard(int boardId) {
    return hive.labelsBox.values
        .where((l) => l.boardId == boardId)
        .map(
          (l) => DeckLabel(
            id: l.id,
            title: l.title,
            color: l.color,
            boardId: l.boardId,
          ),
        )
        .toList();
  }

  // Public mappers (used by conflict resolution screen)

  DeckCard cardFromHivePublic(CardHiveModel h) => _cardFromHive(h);

  /// Converts a [DeckCard] domain object to its Hive model.
  /// Exposed so callers (e.g. ConflictResolutionScreen) can persist a card
  /// directly without going through the full write path.
  CardHiveModel cardToHivePublic(DeckCard card) => _cardToHive(card);

  /// Writes a conflict-resolution event to the sync log.
  Future<void> logConflictResolution({
    required String entityType,
    required int entityId,
    required bool keepLocal,
    String error = '',
  }) => _log(
    operation: 'resolve',
    entityType: entityType,
    entityId: entityId,
    success: error.isEmpty,
    errorMessage: error.isNotEmpty
        ? error
        : keepLocal
        ? 'Kept local version.'
        : 'Kept server version.',
  );

  // Mappers

  DeckBoard _boardFromHive(BoardHiveModel h) => DeckBoard(
    id: h.id,
    title: h.title,
    color: h.color,
    archived: h.archived,
    shared: h.shared,
    deletedAt: h.deletedAt,
    lastModified: h.lastModified,
    etag: h.etag,
    owner: DeckUser(uid: h.ownerUid, displayName: h.ownerDisplayName, type: 0),
    labels: getLabelsForBoard(h.id),
    permissionRead: h.permissionRead,
    permissionEdit: h.permissionEdit,
    permissionManage: h.permissionManage,
    permissionShare: h.permissionShare,
  );

  BoardHiveModel _boardToHive(DeckBoard b) {
    for (final lbl in b.labels) {
      hive.labelsBox.put(lbl.id, _labelToHive(lbl, b.id));
    }
    return BoardHiveModel(
      id: b.id,
      title: b.title,
      color: b.color,
      archived: b.archived,
      shared: b.shared,
      deletedAt: 0,
      lastModified: b.lastModified,
      etag: b.etag,
      ownerUid: b.owner?.uid ?? '',
      ownerDisplayName: b.owner?.displayName ?? '',
      permissionRead: b.permissionRead,
      permissionEdit: b.permissionEdit,
      permissionManage: b.permissionManage,
      permissionShare: b.permissionShare,
    );
  }

  DeckStack _stackFromHive(StackHiveModel h) => DeckStack(
    id: h.id,
    title: h.title,
    boardId: h.boardId,
    order: h.order,
    lastModified: h.lastModified,
    deletedAt: h.deletedAt,
    cards: const [],
  );

  StackHiveModel _stackToHive(DeckStack s) => StackHiveModel(
    id: s.id,
    title: s.title,
    boardId: s.boardId,
    order: s.order,
    deletedAt: s.deletedAt,
    lastModified: s.lastModified,
  );

  DeckCard _cardFromHive(CardHiveModel h) {
    final labels = h.labelIds
        .map((id) => hive.labelsBox.get(id))
        .whereType<LabelHiveModel>()
        .map(
          (l) => DeckLabel(
            id: l.id,
            title: l.title,
            color: l.color,
            boardId: l.boardId,
          ),
        )
        .toList();
    return DeckCard(
      id: h.id,
      title: h.title,
      description: h.description,
      stackId: h.stackId,
      boardId: h.boardId,
      order: h.order,
      archived: h.archived,
      createdAt: h.createdAt,
      lastModified: h.lastModified,
      deletedAt: h.deletedAt,
      duedate: h.duedate.isEmpty ? null : h.duedate,
      labels: labels,
      assignedUsers: h.assignedUserUids
          .map((uid) => DeckUser(uid: uid, displayName: uid, type: 0))
          .toList(),
      owner: DeckUser(uid: h.ownerUid, displayName: h.ownerUid, type: 0),
      type: h.type,
    );
  }

  CardHiveModel _cardToHive(DeckCard c) => CardHiveModel(
    id: c.id,
    title: c.title,
    description: c.description,
    stackId: c.stackId,
    boardId: c.boardId,
    order: c.order,
    archived: c.archived,
    createdAt: c.createdAt,
    lastModified: c.lastModified,
    deletedAt: c.deletedAt,
    duedate: c.duedate ?? '',
    labelIds: c.labels.map((l) => l.id).toList(),
    assignedUserUids: c.assignedUsers.map((u) => u.uid).toList(),
    ownerUid: c.owner?.uid ?? '',
    type: c.type,
  );

  LabelHiveModel _labelToHive(DeckLabel l, int boardId) => LabelHiveModel(
    id: l.id,
    title: l.title,
    color: l.color,
    boardId: boardId,
    cardId: 0,
  );
}
