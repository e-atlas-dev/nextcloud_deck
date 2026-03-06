import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/auth_provider.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';
import 'package:nextcloud_deck/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _syncing = false;
  String? _syncMessage;
  bool _syncSuccess = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _appVersion = AppLocalizations.of(context).emptyValue);
      }
    }
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _syncing = true;
      _syncMessage = null;
      _syncSuccess = false;
    });
    try {
      await ref.read(boardsProvider.notifier).refresh();
      if (mounted) {
        setState(() {
          _syncing = false;
          _syncSuccess = true;
          _syncMessage = l10n.settingsSyncSuccess;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncing = false;
          _syncSuccess = false;
          _syncMessage =
              '${l10n.settingsSyncFailed}: ${e is AppException ? (e).userMessage : e}';
        });
      }
    }
  }

  void _confirmLogout(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(l10n.logoutConfirm),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsClearCacheTitle),
        content: Text(l10n.settingsClearCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(settingsProvider.notifier).clearCache();
              // Invalidate providers so next load re-fetches from network
              ref.invalidate(boardsProvider);
              ref.invalidate(boardDetailProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settingsClearCacheSuccess)),
                );
              }
            },
            child: Text(l10n.settingsClearCacheConfirmButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        bottom: true,
        child: ListView(
          children: [
            _SectionHeader(l10n.settingsAccountSection),
            if (auth?.username != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.brandLight,
                  child: Text(
                    auth!.username![0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(auth.username!),
                subtitle: Text(
                  auth.serverUrl ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/settings/account'),
              ),
            const Divider(),
            _SectionHeader(l10n.settingsSyncSection),
            ListTile(
              leading: const Icon(Icons.sync_rounded),
              title: Text(l10n.settingsSyncNow),
              subtitle: _syncMessage != null
                  ? Text(
                      _syncMessage!,
                      style: TextStyle(
                        color: _syncSuccess
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    )
                  : null,
              trailing: _syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: _syncing ? null : _syncNow,
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_rounded),
              title: Text(l10n.settingsViewSyncLogs),
              trailing: const Icon(Icons.chevron_right_rounded),
              // push so the back button returns here, not all the way to /
              onTap: () => context.push('/settings/sync-logs'),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: Text(l10n.settingsConflicts),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings/conflicts'),
            ),
            const Divider(),
            _SectionHeader(l10n.settingsPreferencesSection),
            ListTile(
              leading: const Icon(Icons.merge_type_rounded),
              title: Text(l10n.settingsConflictResolution),
              subtitle: Text(_conflictLabel(l10n, settings.conflictResolution)),
              onTap: () => _showConflictPicker(
                context,
                l10n,
                settings.conflictResolution,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline_rounded),
              title: Text(l10n.settingsShowIntro),
              onTap: () {
                ref.read(settingsProvider.notifier).setHasSeenOnboarding(false);
                context.go('/onboarding');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n.settingsClearCache),
              onTap: () => _confirmClearCache(l10n),
            ),
            const Divider(),
            _SectionHeader(l10n.settingsAboutSection),
            ListTile(
              leading: const Icon(Icons.api_rounded),
              title: Text(l10n.settingsApiVersion),
              trailing: Text(
                settings.deckVersion.isNotEmpty
                    ? settings.deckVersion
                    : l10n.emptyValue,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_rounded),
              title: Text(l10n.settingsServerVersion),
              trailing: Text(
                settings.serverVersion.isNotEmpty
                    ? settings.serverVersion
                    : l10n.emptyValue,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l10n.settingsAppVersion),
              trailing: Text(
                _appVersion.isNotEmpty ? _appVersion : l10n.emptyValue,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(
                l10n.settingsLogout,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () => _confirmLogout(l10n),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.appBuiltBy,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _conflictLabel(
    AppLocalizations l10n,
    ConflictResolutionPreference pref,
  ) => switch (pref) {
    ConflictResolutionPreference.ask => l10n.settingsConflictAsk,
    ConflictResolutionPreference.keepLocal => l10n.settingsConflictKeepLocal,
    ConflictResolutionPreference.keepServer => l10n.settingsConflictKeepServer,
  };

  void _showConflictPicker(
    BuildContext context,
    AppLocalizations l10n,
    ConflictResolutionPreference current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => RadioGroup(
        groupValue: current,
        onChanged: (v) {
          if (v != null) {
            ref.read(settingsProvider.notifier).setConflictResolution(v);
            Navigator.pop(ctx);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l10n.settingsConflictResolutionTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(),
            for (final pref in ConflictResolutionPreference.values)
              RadioListTile<ConflictResolutionPreference>(
                title: Text(_conflictLabel(l10n, pref)),
                value: pref,
                activeColor: AppColors.brand,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );
}
