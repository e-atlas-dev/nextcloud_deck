abstract final class ApiConstants {
  // Deck REST API base path (relative to server URL)
  static const String deckApiPath = '/index.php/apps/deck/api/v1.1';

  // OCS (user info, capabilities) base path
  static const String ocsPath = '/ocs/v2.php';

  // Login Flow v2
  static const String loginV2Initiate = '/index.php/login/v2';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Polling
  static const Duration pollInterval = Duration(seconds: 3);
  static const int pollMaxAttempts = 60; // 3 min

  // Deck API version this client targets
  static const String deckApiVersion = '1.1';
}

abstract final class HiveBoxNames {
  static const String boards = 'boards_v1';
  static const String stacks = 'stacks_v1';
  static const String cards = 'cards_v1';
  static const String labels = 'labels_v1';
  static const String syncQueue = 'sync_queue_v1';
  static const String syncLogs = 'sync_logs_v1';
  static const String conflicts = 'conflicts_v1';
  static const String settings = 'settings_v1';
}

abstract final class HiveTypeIds {
  static const int board = 0;
  static const int stack = 1;
  static const int card = 2;
  static const int label = 3;
  static const int aclItem = 4;
  static const int syncQueueItem = 5;
  static const int syncLogEntry = 6;
  static const int conflictItem = 7;
  static const int deckUser = 8;
}

abstract final class SecureStorageKeys {
  static const String serverUrl = 'nc_server_url';
  static const String username = 'nc_username';
  static const String appPassword = 'nc_app_password';
}

abstract final class SettingsKeys {
  static const String conflictResolution = 'conflict_resolution';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String serverVersion = 'server_version';
  static const String deckVersion = 'deck_version';
}
