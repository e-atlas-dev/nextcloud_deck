import 'package:hive_ce/hive.dart';

import 'package:nextcloud_deck/core/constants/api_constants.dart';

// SYNC QUEUE ITEM

/// Represents a pending local change that must be pushed to the server.
class SyncQueueItemHiveModel extends HiveObject {
  SyncQueueItemHiveModel({
    required this.localId,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.boardId,
    required this.stackId,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.lastError,
  });

  /// UUID generated locally so we can de-duplicate on retry.
  String localId;

  /// 'create' | 'update' | 'delete'
  String operation;

  /// 'board' | 'stack' | 'card'
  String entityType;

  /// Server-assigned ID (0 for creates not yet committed to server).
  int entityId;

  int boardId;
  int stackId;

  /// JSON-encoded body to send with the request.
  String payload;

  int createdAt; // epoch millis
  int retryCount;
  String lastError;
}

class SyncQueueItemHiveAdapter extends TypeAdapter<SyncQueueItemHiveModel> {
  @override
  int get typeId => HiveTypeIds.syncQueueItem;

  @override
  SyncQueueItemHiveModel read(BinaryReader reader) {
    return SyncQueueItemHiveModel(
      localId: reader.readString(),
      operation: reader.readString(),
      entityType: reader.readString(),
      entityId: reader.readInt(),
      boardId: reader.readInt(),
      stackId: reader.readInt(),
      payload: reader.readString(),
      createdAt: reader.readInt(),
      retryCount: reader.readInt(),
      lastError: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItemHiveModel obj) {
    writer
      ..writeString(obj.localId)
      ..writeString(obj.operation)
      ..writeString(obj.entityType)
      ..writeInt(obj.entityId)
      ..writeInt(obj.boardId)
      ..writeInt(obj.stackId)
      ..writeString(obj.payload)
      ..writeInt(obj.createdAt)
      ..writeInt(obj.retryCount)
      ..writeString(obj.lastError);
  }
}

// SYNC LOG ENTRY

class SyncLogEntryHiveModel extends HiveObject {
  SyncLogEntryHiveModel({
    required this.id,
    required this.timestamp,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.status,
    required this.errorMessage,
  });

  String id;
  int timestamp; // epoch millis
  String operation;
  String entityType;
  int entityId;

  /// 'success' | 'failed'
  String status;
  String errorMessage;
}

class SyncLogEntryHiveAdapter extends TypeAdapter<SyncLogEntryHiveModel> {
  @override
  int get typeId => HiveTypeIds.syncLogEntry;

  @override
  SyncLogEntryHiveModel read(BinaryReader reader) {
    return SyncLogEntryHiveModel(
      id: reader.readString(),
      timestamp: reader.readInt(),
      operation: reader.readString(),
      entityType: reader.readString(),
      entityId: reader.readInt(),
      status: reader.readString(),
      errorMessage: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncLogEntryHiveModel obj) {
    writer
      ..writeString(obj.id)
      ..writeInt(obj.timestamp)
      ..writeString(obj.operation)
      ..writeString(obj.entityType)
      ..writeInt(obj.entityId)
      ..writeString(obj.status)
      ..writeString(obj.errorMessage);
  }
}

// CONFLICT ITEM

class ConflictItemHiveModel extends HiveObject {
  ConflictItemHiveModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.boardId,
    required this.stackId,
    required this.localPayload,
    required this.serverPayload,
    required this.detectedAt,
  });

  String id;
  String entityType;
  int entityId;
  int boardId;
  int stackId;
  String localPayload; // JSON
  String serverPayload; // JSON
  int detectedAt;
}

class ConflictItemHiveAdapter extends TypeAdapter<ConflictItemHiveModel> {
  @override
  int get typeId => HiveTypeIds.conflictItem;

  @override
  ConflictItemHiveModel read(BinaryReader reader) {
    return ConflictItemHiveModel(
      id: reader.readString(),
      entityType: reader.readString(),
      entityId: reader.readInt(),
      boardId: reader.readInt(),
      stackId: reader.readInt(),
      localPayload: reader.readString(),
      serverPayload: reader.readString(),
      detectedAt: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ConflictItemHiveModel obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.entityType)
      ..writeInt(obj.entityId)
      ..writeInt(obj.boardId)
      ..writeInt(obj.stackId)
      ..writeString(obj.localPayload)
      ..writeString(obj.serverPayload)
      ..writeInt(obj.detectedAt);
  }
}
