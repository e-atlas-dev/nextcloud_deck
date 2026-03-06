import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:nextcloud_deck/core/constants/api_constants.dart';
import 'package:nextcloud_deck/data/models/hive/deck_hive_models.dart';
import 'package:nextcloud_deck/data/models/hive/sync_hive_models.dart';

class HiveService {
  HiveService._();
  static final HiveService _instance = HiveService._();
  static HiveService get instance => _instance;

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;

    await Hive.initFlutter();

    // Register all adapters (order matters - must match typeId assignment)
    Hive
      ..registerAdapter(DeckUserHiveAdapter())
      ..registerAdapter(LabelHiveAdapter())
      ..registerAdapter(AclItemHiveAdapter())
      ..registerAdapter(BoardHiveAdapter())
      ..registerAdapter(StackHiveAdapter())
      ..registerAdapter(CardHiveAdapter())
      ..registerAdapter(SyncQueueItemHiveAdapter())
      ..registerAdapter(SyncLogEntryHiveAdapter())
      ..registerAdapter(ConflictItemHiveAdapter());

    // Open all boxes eagerly on startup
    await Future.wait([
      Hive.openBox<BoardHiveModel>(HiveBoxNames.boards),
      Hive.openBox<StackHiveModel>(HiveBoxNames.stacks),
      Hive.openBox<CardHiveModel>(HiveBoxNames.cards),
      Hive.openBox<LabelHiveModel>(HiveBoxNames.labels),
      Hive.openBox<SyncQueueItemHiveModel>(HiveBoxNames.syncQueue),
      Hive.openBox<SyncLogEntryHiveModel>(HiveBoxNames.syncLogs),
      Hive.openBox<ConflictItemHiveModel>(HiveBoxNames.conflicts),
      Hive.openBox<dynamic>(HiveBoxNames.settings),
    ]);

    _initialised = true;
  }

  // Typed box accessors

  Box<BoardHiveModel> get boardsBox =>
      Hive.box<BoardHiveModel>(HiveBoxNames.boards);

  Box<StackHiveModel> get stacksBox =>
      Hive.box<StackHiveModel>(HiveBoxNames.stacks);

  Box<CardHiveModel> get cardsBox =>
      Hive.box<CardHiveModel>(HiveBoxNames.cards);

  Box<LabelHiveModel> get labelsBox =>
      Hive.box<LabelHiveModel>(HiveBoxNames.labels);

  Box<SyncQueueItemHiveModel> get syncQueueBox =>
      Hive.box<SyncQueueItemHiveModel>(HiveBoxNames.syncQueue);

  Box<SyncLogEntryHiveModel> get syncLogsBox =>
      Hive.box<SyncLogEntryHiveModel>(HiveBoxNames.syncLogs);

  Box<ConflictItemHiveModel> get conflictsBox =>
      Hive.box<ConflictItemHiveModel>(HiveBoxNames.conflicts);

  Box<dynamic> get settingsBox => Hive.box<dynamic>(HiveBoxNames.settings);

  // Settings helpers

  T? getSetting<T>(String key) => settingsBox.get(key) as T?;

  Future<void> setSetting<T>(String key, T value) =>
      settingsBox.put(key, value);

  // Clear helpers

  /// Clears all entity data caches but leaves settings intact.
  Future<void> clearEntityData() async {
    await Future.wait([
      boardsBox.clear(),
      stacksBox.clear(),
      cardsBox.clear(),
      labelsBox.clear(),
    ]);
  }

  /// Clears the sync queue (e.g., after logout).
  Future<void> clearSyncData() async {
    await Future.wait([
      syncQueueBox.clear(),
      syncLogsBox.clear(),
      conflictsBox.clear(),
    ]);
  }
}
