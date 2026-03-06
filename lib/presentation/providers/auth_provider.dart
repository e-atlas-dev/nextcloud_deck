import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/presentation/providers/app_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.serverUrl,
    this.username,
    this.error,
  });

  final AuthStatus status;
  final String? serverUrl;
  final String? username;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    String? serverUrl,
    String? username,
    String? error,
  }) => AuthState(
    status: status ?? this.status,
    serverUrl: serverUrl ?? this.serverUrl,
    username: username ?? this.username,
    error: error,
  );

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(secureStorageProvider);
    final has = await storage.hasCredentials();
    if (has) {
      final url = await storage.getServerUrl();
      final user = await storage.getUsername();
      return AuthState(
        status: AuthStatus.authenticated,
        serverUrl: url,
        username: user,
      );
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> loginComplete({
    required String serverUrl,
    required String username,
    required String appPassword,
  }) async {
    final storage = ref.read(secureStorageProvider);
    await storage.saveCredentials(
      serverUrl: serverUrl,
      username: username,
      appPassword: appPassword,
    );
    ref.invalidate(serverUrlProvider);
    state = AsyncData(
      AuthState(
        status: AuthStatus.authenticated,
        serverUrl: serverUrl,
        username: username,
      ),
    );
  }

  Future<void> logout() async {
    final hive = ref.read(hiveServiceProvider);
    await hive.clearEntityData();
    await hive.clearSyncData();
    await hive.settingsBox.clear();

    final storage = ref.read(secureStorageProvider);
    await storage.clearAll();

    ref.invalidate(serverUrlProvider);
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
