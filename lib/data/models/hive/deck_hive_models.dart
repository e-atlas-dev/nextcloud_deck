import 'package:hive_ce/hive.dart';

import 'package:nextcloud_deck/core/constants/api_constants.dart';

// DECK USER

class DeckUserHiveModel extends HiveObject {
  DeckUserHiveModel({
    required this.uid,
    required this.displayName,
    required this.type,
  });

  String uid;
  String displayName;
  int type; // 0 = user, 1 = group
}

class DeckUserHiveAdapter extends TypeAdapter<DeckUserHiveModel> {
  @override
  int get typeId => HiveTypeIds.deckUser;

  @override
  DeckUserHiveModel read(BinaryReader reader) {
    return DeckUserHiveModel(
      uid: reader.readString(),
      displayName: reader.readString(),
      type: reader.readByte(),
    );
  }

  @override
  void write(BinaryWriter writer, DeckUserHiveModel obj) {
    writer
      ..writeString(obj.uid)
      ..writeString(obj.displayName)
      ..writeByte(obj.type);
  }
}

// LABEL

class LabelHiveModel extends HiveObject {
  LabelHiveModel({
    required this.id,
    required this.title,
    required this.color,
    required this.boardId,
    required this.cardId,
  });

  int id;
  String title;
  String color; // hex without #
  int boardId;
  int cardId; // 0 if this is a board-level label not yet associated
}

class LabelHiveAdapter extends TypeAdapter<LabelHiveModel> {
  @override
  int get typeId => HiveTypeIds.label;

  @override
  LabelHiveModel read(BinaryReader reader) {
    return LabelHiveModel(
      id: reader.readInt(),
      title: reader.readString(),
      color: reader.readString(),
      boardId: reader.readInt(),
      cardId: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, LabelHiveModel obj) {
    writer
      ..writeInt(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.color)
      ..writeInt(obj.boardId)
      ..writeInt(obj.cardId);
  }
}

// ACL ITEM

class AclItemHiveModel extends HiveObject {
  AclItemHiveModel({
    required this.id,
    required this.participantUid,
    required this.participantDisplayName,
    required this.participantType,
    required this.boardId,
    required this.permissionRead,
    required this.permissionEdit,
    required this.permissionManage,
    required this.owner,
  });

  int id;
  String participantUid;
  String participantDisplayName;
  int participantType;
  int boardId;
  bool permissionRead;
  bool permissionEdit;
  bool permissionManage;
  bool owner;
}

class AclItemHiveAdapter extends TypeAdapter<AclItemHiveModel> {
  @override
  int get typeId => HiveTypeIds.aclItem;

  @override
  AclItemHiveModel read(BinaryReader reader) {
    return AclItemHiveModel(
      id: reader.readInt(),
      participantUid: reader.readString(),
      participantDisplayName: reader.readString(),
      participantType: reader.readByte(),
      boardId: reader.readInt(),
      permissionRead: reader.readBool(),
      permissionEdit: reader.readBool(),
      permissionManage: reader.readBool(),
      owner: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, AclItemHiveModel obj) {
    writer
      ..writeInt(obj.id)
      ..writeString(obj.participantUid)
      ..writeString(obj.participantDisplayName)
      ..writeByte(obj.participantType)
      ..writeInt(obj.boardId)
      ..writeBool(obj.permissionRead)
      ..writeBool(obj.permissionEdit)
      ..writeBool(obj.permissionManage)
      ..writeBool(obj.owner);
  }
}

// BOARD

class BoardHiveModel extends HiveObject {
  BoardHiveModel({
    required this.id,
    required this.title,
    required this.color,
    required this.archived,
    required this.shared,
    required this.deletedAt,
    required this.lastModified,
    required this.etag,
    required this.ownerUid,
    required this.ownerDisplayName,
    required this.permissionRead,
    required this.permissionEdit,
    required this.permissionManage,
    required this.permissionShare,
  });

  int id;
  String title;
  String color;
  bool archived;
  int shared;
  int deletedAt;
  int lastModified;
  String etag;
  String ownerUid;
  String ownerDisplayName;
  bool permissionRead;
  bool permissionEdit;
  bool permissionManage;
  bool permissionShare;
}

class BoardHiveAdapter extends TypeAdapter<BoardHiveModel> {
  @override
  int get typeId => HiveTypeIds.board;

  @override
  BoardHiveModel read(BinaryReader reader) {
    return BoardHiveModel(
      id: reader.readInt(),
      title: reader.readString(),
      color: reader.readString(),
      archived: reader.readBool(),
      shared: reader.readInt(),
      deletedAt: reader.readInt(),
      lastModified: reader.readInt(),
      etag: reader.readString(),
      ownerUid: reader.readString(),
      ownerDisplayName: reader.readString(),
      permissionRead: reader.readBool(),
      permissionEdit: reader.readBool(),
      permissionManage: reader.readBool(),
      permissionShare: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, BoardHiveModel obj) {
    writer
      ..writeInt(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.color)
      ..writeBool(obj.archived)
      ..writeInt(obj.shared)
      ..writeInt(obj.deletedAt)
      ..writeInt(obj.lastModified)
      ..writeString(obj.etag)
      ..writeString(obj.ownerUid)
      ..writeString(obj.ownerDisplayName)
      ..writeBool(obj.permissionRead)
      ..writeBool(obj.permissionEdit)
      ..writeBool(obj.permissionManage)
      ..writeBool(obj.permissionShare);
  }
}

// STACK

class StackHiveModel extends HiveObject {
  StackHiveModel({
    required this.id,
    required this.title,
    required this.boardId,
    required this.order,
    required this.deletedAt,
    required this.lastModified,
  });

  int id;
  String title;
  int boardId;
  int order;
  int deletedAt;
  int lastModified;
}

class StackHiveAdapter extends TypeAdapter<StackHiveModel> {
  @override
  int get typeId => HiveTypeIds.stack;

  @override
  StackHiveModel read(BinaryReader reader) {
    return StackHiveModel(
      id: reader.readInt(),
      title: reader.readString(),
      boardId: reader.readInt(),
      order: reader.readInt(),
      deletedAt: reader.readInt(),
      lastModified: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StackHiveModel obj) {
    writer
      ..writeInt(obj.id)
      ..writeString(obj.title)
      ..writeInt(obj.boardId)
      ..writeInt(obj.order)
      ..writeInt(obj.deletedAt)
      ..writeInt(obj.lastModified);
  }
}

// CARD

class CardHiveModel extends HiveObject {
  CardHiveModel({
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
    required this.labelIds,
    required this.assignedUserUids,
    required this.ownerUid,
    required this.type,
  });

  int id;
  String title;
  String description;
  int stackId;
  int boardId;
  int order;
  bool archived;
  int createdAt;
  int lastModified;
  int deletedAt;
  String duedate; // ISO8601 or empty
  List<int> labelIds;
  List<String> assignedUserUids;
  String ownerUid;
  String type;
}

class CardHiveAdapter extends TypeAdapter<CardHiveModel> {
  @override
  int get typeId => HiveTypeIds.card;

  @override
  CardHiveModel read(BinaryReader reader) {
    return CardHiveModel(
      id: reader.readInt(),
      title: reader.readString(),
      description: reader.readString(),
      stackId: reader.readInt(),
      boardId: reader.readInt(),
      order: reader.readInt(),
      archived: reader.readBool(),
      createdAt: reader.readInt(),
      lastModified: reader.readInt(),
      deletedAt: reader.readInt(),
      duedate: reader.readString(),
      labelIds: reader.readList().cast<int>(),
      assignedUserUids: reader.readList().cast<String>(),
      ownerUid: reader.readString(),
      type: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, CardHiveModel obj) {
    writer
      ..writeInt(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeInt(obj.stackId)
      ..writeInt(obj.boardId)
      ..writeInt(obj.order)
      ..writeBool(obj.archived)
      ..writeInt(obj.createdAt)
      ..writeInt(obj.lastModified)
      ..writeInt(obj.deletedAt)
      ..writeString(obj.duedate)
      ..writeList(obj.labelIds)
      ..writeList(obj.assignedUserUids)
      ..writeString(obj.ownerUid)
      ..writeString(obj.type);
  }
}
