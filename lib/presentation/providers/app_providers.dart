import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/network/api_client.dart';
import 'package:nextcloud_deck/core/storage/hive_service.dart';
import 'package:nextcloud_deck/core/storage/secure_storage_service.dart';
import 'package:nextcloud_deck/core/utils/connectivity_service.dart';
import 'package:nextcloud_deck/data/repositories/boards_repository.dart';
import 'package:nextcloud_deck/data/services/auth_service.dart';
import 'package:nextcloud_deck/data/services/sync_queue_service.dart';
import 'package:nextcloud_deck/data/services/deck_api_service.dart';

// Infrastructure

final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

final hiveServiceProvider = Provider<HiveService>((_) => HiveService.instance);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService(),
);

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});

// Network

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(secureStorage: ref.watch(secureStorageProvider));
});

/// Server URL provider - reads from SecureStorage at startup.
final serverUrlProvider = FutureProvider<String?>((ref) async {
  return ref.watch(secureStorageProvider).getServerUrl();
});

final deckApiServiceProvider = Provider<DeckApiService?>((ref) {
  final urlAsync = ref.watch(serverUrlProvider);
  return urlAsync.when(
    data: (url) => url == null
        ? null
        : DeckApiService(
            apiClient: ref.watch(apiClientProvider),
            serverUrl: url,
          ),
    loading: () => null,
    error: (_, __) => null,
  );
});

// Auth

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(secureStorage: ref.watch(secureStorageProvider));
});

// Sync Queue

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final service = SyncQueueService(
    hive: ref.watch(hiveServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
  service.start();
  ref.onDispose(service.stop);
  return service;
});

// Repository

final boardsRepositoryProvider = Provider<BoardsRepository?>((ref) {
  final api = ref.watch(deckApiServiceProvider);
  if (api == null) return null;
  return BoardsRepository(
    apiService: api,
    hive: ref.watch(hiveServiceProvider),
    syncQueue: ref.watch(syncQueueServiceProvider),
  );
});
