import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/constants/api_constants.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/presentation/providers/app_providers.dart';

class SettingsState {
  const SettingsState({
    this.conflictResolution = ConflictResolutionPreference.ask,
    this.hasSeenOnboarding = false,
    this.serverVersion = '',
    this.deckVersion = '',
  });

  final ConflictResolutionPreference conflictResolution;
  final bool hasSeenOnboarding;
  final String serverVersion;
  final String deckVersion;

  SettingsState copyWith({
    ConflictResolutionPreference? conflictResolution,
    bool? hasSeenOnboarding,
    String? serverVersion,
    String? deckVersion,
  }) => SettingsState(
    conflictResolution: conflictResolution ?? this.conflictResolution,
    hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    serverVersion: serverVersion ?? this.serverVersion,
    deckVersion: deckVersion ?? this.deckVersion,
  );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final hive = ref.read(hiveServiceProvider);
    final prefStr =
        hive.getSetting<String>(SettingsKeys.conflictResolution) ?? 'ask';
    final pref = switch (prefStr) {
      'keepLocal' => ConflictResolutionPreference.keepLocal,
      'keepServer' => ConflictResolutionPreference.keepServer,
      _ => ConflictResolutionPreference.ask,
    };
    return SettingsState(
      conflictResolution: pref,
      hasSeenOnboarding:
          hive.getSetting<bool>(SettingsKeys.hasSeenOnboarding) ?? false,
      serverVersion: hive.getSetting<String>(SettingsKeys.serverVersion) ?? '',
      deckVersion: hive.getSetting<String>(SettingsKeys.deckVersion) ?? '',
    );
  }

  Future<void> setConflictResolution(ConflictResolutionPreference pref) async {
    final hive = ref.read(hiveServiceProvider);
    final str = switch (pref) {
      ConflictResolutionPreference.keepLocal => 'keepLocal',
      ConflictResolutionPreference.keepServer => 'keepServer',
      ConflictResolutionPreference.ask => 'ask',
    };
    await hive.setSetting(SettingsKeys.conflictResolution, str);
    state = state.copyWith(conflictResolution: pref);
  }

  Future<void> setHasSeenOnboarding(bool seen) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.setSetting(SettingsKeys.hasSeenOnboarding, seen);
    state = state.copyWith(hasSeenOnboarding: seen);
  }

  Future<void> updateVersionInfo({
    required String serverVersion,
    required String deckVersion,
  }) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.setSetting(SettingsKeys.serverVersion, serverVersion);
    await hive.setSetting(SettingsKeys.deckVersion, deckVersion);
    state = state.copyWith(
      serverVersion: serverVersion,
      deckVersion: deckVersion,
    );
  }

  Future<void> clearCache() async {
    final hive = ref.read(hiveServiceProvider);
    await hive.clearEntityData();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
