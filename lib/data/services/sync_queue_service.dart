import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/storage/hive_service.dart';
import 'package:nextcloud_deck/core/utils/connectivity_service.dart';
import 'package:nextcloud_deck/data/models/hive/sync_hive_models.dart';
import 'package:nextcloud_deck/data/services/deck_api_service.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';

const _uuid = Uuid();

/// Operations that can be queued for offline replay.
enum QueuedOp { createCard, updateCard, deleteCard, createStack, deleteStack }

/// A lightweight offline-first sync queue.
///
/// When a write operation fails with [NetworkException] (device is offline or
/// the server is unreachable), the caller stores the intent in this queue.
/// As soon as connectivity is restored the queue is drained in FIFO order.
///
/// The queue is durable - it survives app restarts via Hive.
class SyncQueueService {
  SyncQueueService({required this.hive, required this.connectivity});

  final HiveService hive;
  final ConnectivityService connectivity;

  StreamSubscription<bool>? _connectSub;
  bool _draining = false;

  // Lifecycle

  /// Start watching connectivity and drain the queue whenever we go online.
  void start() {
    _connectSub?.cancel();
    _connectSub = connectivity.onConnectivityChanged.listen((online) {
      if (online) drainIfNeeded(null);
    });
  }

  void stop() {
    _connectSub?.cancel();
    _connectSub = null;
  }

  // Enqueue

  Future<void> enqueueCreateCard({
    required int boardId,
    required int stackId,
    required String title,
    required String description,
    String? duedate,
  }) => _enqueue(
    op: 'createCard',
    entityType: 'card',
    entityId: 0,
    boardId: boardId,
    stackId: stackId,
    payload: {
      'title': title,
      'description': description,
      if (duedate != null) 'duedate': duedate,
    },
  );

  Future<void> enqueueUpdateCard(DeckCard card) => _enqueue(
    op: 'updateCard',
    entityType: 'card',
    entityId: card.id,
    boardId: card.boardId,
    stackId: card.stackId,
    payload: {
      'title': card.title,
      'description': card.description,
      'type': card.type.isEmpty ? 'plain' : card.type,
      'owner': card.owner?.uid ?? '',
      'stackId': card.stackId,
      'order': card.order,
      'archived': card.archived,
      if (card.duedate != null) 'duedate': card.duedate,
    },
  );

  Future<void> enqueueDeleteCard(DeckCard card) => _enqueue(
    op: 'deleteCard',
    entityType: 'card',
    entityId: card.id,
    boardId: card.boardId,
    stackId: card.stackId,
    payload: {'stackId': card.stackId},
  );

  Future<void> enqueueCreateStack({
    required int boardId,
    required String title,
    required int order,
  }) => _enqueue(
    op: 'createStack',
    entityType: 'stack',
    entityId: 0,
    boardId: boardId,
    stackId: 0,
    payload: {'title': title, 'order': order},
  );

  Future<void> enqueueDeleteStack({
    required int boardId,
    required int stackId,
  }) => _enqueue(
    op: 'deleteStack',
    entityType: 'stack',
    entityId: stackId,
    boardId: boardId,
    stackId: stackId,
    payload: {},
  );

  Future<void> _enqueue({
    required String op,
    required String entityType,
    required int entityId,
    required int boardId,
    required int stackId,
    required Map<String, dynamic> payload,
  }) async {
    await hive.syncQueueBox.add(
      SyncQueueItemHiveModel(
        localId: _uuid.v4(),
        operation: op,
        entityType: entityType,
        entityId: entityId,
        boardId: boardId,
        stackId: stackId,
        payload: jsonEncode(payload),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        retryCount: 0,
        lastError: '',
      ),
    );
  }

  // Drain

  int get pendingCount => hive.syncQueueBox.length;

  /// Attempt to replay all queued operations against the server.
  /// [api] - pass a live [DeckApiService]; if null the drain is skipped
  /// (used when connectivity fires before the API service is ready).
  Future<void> drainIfNeeded(DeckApiService? api) async {
    if (_draining || api == null || hive.syncQueueBox.isEmpty) return;
    _draining = true;
    try {
      await _drain(api);
    } finally {
      _draining = false;
    }
  }

  Future<void> _drain(DeckApiService api) async {
    // Process in insertion order. We work through a snapshot of the keys so
    // that newly-enqueued items during a drain don't get processed twice.
    final keys = hive.syncQueueBox.keys.toList();
    for (final key in keys) {
      final item = hive.syncQueueBox.get(key);
      if (item == null) continue;

      try {
        await _replay(api, item);
        await hive.syncQueueBox.delete(key);
        await _log(item: item, success: true);
      } on NetworkException {
        // Still offline - stop draining, we'll retry next reconnect.
        break;
      } on FormatException catch (e) {
        // Malformed payload in Hive - discard immediately, it can never succeed.
        await hive.syncQueueBox.delete(key);
        await _log(item: item, success: false, error: 'Corrupt payload: $e');
      } catch (e) {
        // Server-side error (4xx, parse error, etc.) - log, increment retry
        // count, and discard after 5 failures so one bad item never blocks
        // the rest of the queue permanently.
        item.retryCount += 1;
        item.lastError = e.toString();
        await item.save();
        await _log(item: item, success: false, error: e.toString());

        if (item.retryCount >= 5) {
          await hive.syncQueueBox.delete(key);
          await _log(
            item: item,
            success: false,
            error: 'Abandoned after ${item.retryCount} failures: ${e}',
          );
        }
      }
    }
  }

  Future<void> _replay(DeckApiService api, SyncQueueItemHiveModel item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    switch (item.operation) {
      case 'createCard':
        await api.createCard(
          item.boardId,
          item.stackId,
          title: payload['title'] as String,
          description: payload['description'] as String? ?? '',
          duedate: payload['duedate'] as String?,
        );

      case 'updateCard':
        await api.updateCard(
          item.boardId,
          item.stackId,
          item.entityId,
          fields: payload,
        );

      case 'deleteCard':
        await api.deleteCard(
          item.boardId,
          payload['stackId'] as int,
          item.entityId,
        );

      case 'createStack':
        await api.createStack(
          item.boardId,
          title: payload['title'] as String,
          order: payload['order'] as int? ?? 0,
        );

      case 'deleteStack':
        await api.deleteStack(item.boardId, item.entityId);

      default:
        // Unknown operation - discard silently
        break;
    }
  }

  Future<void> _log({
    required SyncQueueItemHiveModel item,
    required bool success,
    String error = '',
  }) async {
    try {
      await hive.syncLogsBox.add(
        SyncLogEntryHiveModel(
          id: _uuid.v4(),
          timestamp: DateTime.now().millisecondsSinceEpoch,
          operation: item.operation
              .replaceAll('Card', '')
              .replaceAll('Stack', '')
              .replaceAll('Board', ''),
          entityType: item.entityType,
          entityId: item.entityId,
          status: success ? 'success' : 'failed',
          errorMessage: error,
        ),
      );
    } catch (_) {}
  }
}
