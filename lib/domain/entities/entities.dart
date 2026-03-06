import 'package:flutter/material.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';

// DECK USER

class DeckUser {
  const DeckUser({
    required this.uid,
    required this.displayName,
    required this.type,
  });

  final String uid;
  final String displayName;
  final int type; // 0 = user, 1 = group

  factory DeckUser.fromJson(Map<String, dynamic> json) => DeckUser(
    uid: json['uid'] as String? ?? '',
    displayName: json['displayname'] as String? ?? '',
    type: json['type'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayname': displayName,
    'type': type,
  };

  @override
  bool operator ==(Object other) => other is DeckUser && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}

// LABEL

class DeckLabel {
  const DeckLabel({
    required this.id,
    required this.title,
    required this.color,
    required this.boardId,
  });

  final int id;
  final String title;
  final String color; // hex, e.g. "0082C9"
  final int boardId;

  Color get flutterColor => AppColors.fromHex(color);

  factory DeckLabel.fromJson(Map<String, dynamic> json) => DeckLabel(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    color: json['color'] as String? ?? '0082C9',
    boardId: json['boardId'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'color': color,
    'boardId': boardId,
  };

  DeckLabel copyWith({String? title, String? color}) => DeckLabel(
    id: id,
    title: title ?? this.title,
    color: color ?? this.color,
    boardId: boardId,
  );
}

// BOARD

class DeckBoard {
  const DeckBoard({
    required this.id,
    required this.title,
    required this.color,
    required this.archived,
    required this.deletedAt,
    required this.shared,
    required this.lastModified,
    required this.etag,
    required this.owner,
    required this.labels,
    required this.permissionRead,
    required this.permissionEdit,
    required this.permissionManage,
    required this.permissionShare,
  });

  final int id;
  final String title;
  final String color;
  final bool archived;

  /// Unix timestamp (seconds) when the board was soft-deleted, or 0 if active.
  final int deletedAt;
  final int shared;
  final int lastModified;
  final String etag;
  final DeckUser? owner;
  final List<DeckLabel> labels;
  final bool permissionRead;
  final bool permissionEdit;
  final bool permissionManage;
  final bool permissionShare;

  Color get flutterColor => AppColors.fromHex(color);
  bool get isDeleted => deletedAt > 0;

  factory DeckBoard.fromJson(Map<String, dynamic> json) {
    final ownerJson = json['owner'];
    final labelsRaw = json['labels'] as List<dynamic>? ?? [];
    return DeckBoard(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      color: json['color'] as String? ?? '0082C9',
      archived: json['archived'] as bool? ?? false,
      deletedAt: json['deletedAt'] as int? ?? 0,
      shared: json['shared'] as int? ?? 0,
      lastModified: json['lastModified'] as int? ?? 0,
      etag: json['ETag'] as String? ?? '',
      owner: ownerJson != null
          ? DeckUser.fromJson(ownerJson as Map<String, dynamic>)
          : null,
      labels: labelsRaw
          .map((l) => DeckLabel.fromJson(l as Map<String, dynamic>))
          .toList(),
      permissionRead:
          (json['permissions']?['PERMISSION_READ'] as bool?) ?? true,
      permissionEdit:
          (json['permissions']?['PERMISSION_EDIT'] as bool?) ?? false,
      permissionManage:
          (json['permissions']?['PERMISSION_MANAGE'] as bool?) ?? false,
      permissionShare:
          (json['permissions']?['PERMISSION_SHARE'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'color': color,
    'archived': archived,
    'deletedAt': deletedAt,
    'shared': shared,
    'lastModified': lastModified,
    'ETag': etag,
    if (owner != null) 'owner': owner!.toJson(),
    'labels': labels.map((l) => l.toJson()).toList(),
    'permissions': {
      'PERMISSION_READ': permissionRead,
      'PERMISSION_EDIT': permissionEdit,
      'PERMISSION_MANAGE': permissionManage,
      'PERMISSION_SHARE': permissionShare,
    },
  };

  DeckBoard copyWith({
    String? title,
    String? color,
    bool? archived,
    int? deletedAt,
    List<DeckLabel>? labels,
  }) => DeckBoard(
    id: id,
    title: title ?? this.title,
    color: color ?? this.color,
    archived: archived ?? this.archived,
    deletedAt: deletedAt ?? this.deletedAt,
    shared: shared,
    lastModified: lastModified,
    etag: etag,
    owner: owner,
    labels: labels ?? this.labels,
    permissionRead: permissionRead,
    permissionEdit: permissionEdit,
    permissionManage: permissionManage,
    permissionShare: permissionShare,
  );
}

// STACK

class DeckStack {
  const DeckStack({
    required this.id,
    required this.title,
    required this.boardId,
    required this.order,
    required this.lastModified,
    required this.deletedAt,
    required this.cards,
  });

  final int id;
  final String title;
  final int boardId;
  final int order;
  final int lastModified;
  final int deletedAt;
  final List<DeckCard> cards;

  bool get isDeleted => deletedAt > 0;

  factory DeckStack.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'] as List<dynamic>? ?? [];
    return DeckStack(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      boardId: json['boardId'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      lastModified: json['lastModified'] as int? ?? 0,
      deletedAt: json['deletedAt'] as int? ?? 0,
      cards: cardsRaw
          .map((c) => DeckCard.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'boardId': boardId,
    'order': order,
    'lastModified': lastModified,
    'deletedAt': deletedAt,
    'cards': cards.map((c) => c.toJson()).toList(),
  };

  DeckStack copyWith({String? title, int? order, List<DeckCard>? cards}) =>
      DeckStack(
        id: id,
        title: title ?? this.title,
        boardId: boardId,
        order: order ?? this.order,
        lastModified: lastModified,
        deletedAt: deletedAt,
        cards: cards ?? this.cards,
      );
}

// CARD

class DeckCard {
  const DeckCard({
    required this.id,
    required this.title,
    required this.description,
    required this.stackId,
    required this.boardId,
    required this.order,
    required this.archived,
    required this.createdAt,
    required this.lastModified,
    required this.deletedAt,
    required this.duedate,
    required this.labels,
    required this.assignedUsers,
    required this.owner,
    required this.type,
  });

  final int id;
  final String title;
  final String description;
  final int stackId;
  final int boardId;
  final int order;
  final bool archived;
  final int createdAt;
  final int lastModified;
  final int deletedAt;
  final String? duedate; // ISO 8601 or null
  final List<DeckLabel> labels;
  final List<DeckUser> assignedUsers;
  final DeckUser? owner;
  final String type;

  bool get isDeleted => deletedAt > 0;
  bool get hasDueDate => duedate != null && duedate!.isNotEmpty;

  DateTime? get dueDateParsed {
    if (!hasDueDate) return null;
    try {
      return DateTime.parse(duedate!).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool get isOverdue {
    final d = dueDateParsed;
    if (d == null) return false;
    return d.isBefore(DateTime.now());
  }

  bool get isDueToday {
    final d = dueDateParsed;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  factory DeckCard.fromJson(Map<String, dynamic> json) {
    final labelsRaw = json['labels'] as List<dynamic>? ?? [];
    final assigneesRaw = json['assignedUsers'] as List<dynamic>? ?? [];
    return DeckCard(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stackId: json['stackId'] as int? ?? 0,
      boardId: json['boardId'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      archived: json['archived'] as bool? ?? false,
      createdAt: json['createdAt'] as int? ?? 0,
      lastModified: json['lastModified'] as int? ?? 0,
      deletedAt: json['deletedAt'] as int? ?? 0,
      duedate: json['duedate'] as String?,
      labels: labelsRaw
          .map((l) => DeckLabel.fromJson(l as Map<String, dynamic>))
          .toList(),
      assignedUsers: assigneesRaw.map((a) {
        final participant = (a as Map<String, dynamic>)['participant'];
        return participant != null
            ? DeckUser.fromJson(participant as Map<String, dynamic>)
            : DeckUser.fromJson(a);
      }).toList(),
      // Deck API v1.0 returns owner as a plain string ("admin"),
      // v1.1+ may return a user object. Handle both gracefully.
      owner: () {
        final o = json['owner'];
        if (o == null) return null;
        if (o is String) return DeckUser(uid: o, displayName: o, type: 0);
        if (o is Map<String, dynamic>) return DeckUser.fromJson(o);
        return null;
      }(),
      type: json['type'] as String? ?? 'plain',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'stackId': stackId,
    'boardId': boardId,
    'order': order,
    'archived': archived,
    'createdAt': createdAt,
    'lastModified': lastModified,
    'deletedAt': deletedAt,
    if (duedate != null) 'duedate': duedate,
    'labels': labels.map((l) => l.toJson()).toList(),
    'assignedUsers': assignedUsers.map((u) => u.toJson()).toList(),
    if (owner != null) 'owner': owner!.toJson(),
    'type': type,
  };

  DeckCard copyWith({
    String? title,
    String? description,
    int? stackId,
    int? order,
    bool? archived,
    String? duedate,
    List<DeckLabel>? labels,
    List<DeckUser>? assignedUsers,
    bool clearDueDate = false,
  }) => DeckCard(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    stackId: stackId ?? this.stackId,
    boardId: boardId,
    order: order ?? this.order,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    lastModified: lastModified,
    deletedAt: deletedAt,
    duedate: clearDueDate ? null : (duedate ?? this.duedate),
    labels: labels ?? this.labels,
    assignedUsers: assignedUsers ?? this.assignedUsers,
    owner: owner,
    type: type,
  );
}

// SYNC

enum SyncOperation { create, update, delete }

enum SyncEntityType { board, stack, card }

enum SyncStatus { success, failed }

class SyncQueueItem {
  const SyncQueueItem({
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

  final String localId;
  final SyncOperation operation;
  final SyncEntityType entityType;
  final int entityId;
  final int boardId;
  final int stackId;
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final String lastError;
}

class SyncLogEntry {
  const SyncLogEntry({
    required this.id,
    required this.timestamp,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.status,
    required this.errorMessage,
  });

  final String id;
  final DateTime timestamp;
  final String operation;
  final String entityType;
  final int entityId;
  final SyncStatus status;
  final String errorMessage;
}

class ConflictItem {
  const ConflictItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.boardId,
    required this.stackId,
    required this.localPayload,
    required this.serverPayload,
    required this.detectedAt,
  });

  final String id;
  final SyncEntityType entityType;
  final int entityId;
  final int boardId;
  final int stackId;
  final String localPayload;
  final String serverPayload;
  final DateTime detectedAt;
}

enum ConflictResolutionPreference { ask, keepLocal, keepServer }
