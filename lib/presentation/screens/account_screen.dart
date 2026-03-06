import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/auth_provider.dart';
import 'package:nextcloud_deck/presentation/providers/settings_provider.dart';
import 'package:nextcloud_deck/presentation/widgets/app_icon_widget.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider).value;
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final username = auth?.username ?? l10n.emptyValue;
    final serverUrl = auth?.serverUrl ?? l10n.emptyValue;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAccountSection)),
      body: SafeArea(
        bottom: true,
        child: ListView(
          children: [
            // Profile card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.brandLight,
                    child: Text(
                      username.isNotEmpty
                          ? username[0].toUpperCase()
                          : l10n.unknownValue,
                      style: const TextStyle(
                        color: AppColors.brand,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          serverUrl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Server info
            _SectionHeader(l10n.accountSectionServer),
            _InfoTile(
              icon: Icons.cloud_rounded,
              label: l10n.settingsServerVersion,
              value: settings.serverVersion.isNotEmpty
                  ? settings.serverVersion
                  : l10n.emptyValue,
            ),
            _InfoTile(
              icon: Icons.api_rounded,
              label: l10n.settingsApiVersion,
              value: settings.deckVersion.isNotEmpty
                  ? settings.deckVersion
                  : l10n.emptyValue,
            ),
            _InfoTile(
              icon: Icons.link_rounded,
              label: l10n.accountServerUrl,
              value: serverUrl,
            ),
            const Divider(),

            // App identity
            _SectionHeader(l10n.accountSectionApp),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppIcon(size: 44, fallbackColor: AppColors.brand),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.appBuiltBy,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: Text(
      value,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
