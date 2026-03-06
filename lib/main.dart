import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nextcloud_deck/core/storage/hive_service.dart';
import 'package:nextcloud_deck/core/theme/app_theme.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/router/app_router.dart';

/// Global key so any widget - including bottom-sheets that have their own
/// inner Scaffold - can show a snackbar at the root level, in front of everything.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait + upside-down portrait on phones
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialise Hive and open all boxes before widgets mount
  await HiveService.instance.init();

  runApp(const ProviderScope(child: NextcloudDeckApp()));
}

class NextcloudDeckApp extends ConsumerWidget {
  const NextcloudDeckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // App title - localised via onGenerateTitle so the OS task-switcher
      // also shows the translated name.
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,

      // Light / dark theme follows device system setting
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Wrap all screens so content never hides behind the transparent
      // system navigation bar (edgeToEdge is enabled in main()).
      builder: (context, child) => SafeArea(
        top: false, // AppBar/status-bar padding is per-screen
        maintainBottomViewPadding: true,
        child: child ?? const SizedBox.shrink(),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      routerConfig: router,
    );
  }
}
