import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/bb_theme.dart';
import 'data/settings_repository.dart';
import 'l10n/app_localizations.dart';
import 'state/providers.dart';
import 'ui/screens/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only. The arena is a fixed 100x160 logical space with no landscape
  // composition, and the parent project shipped portrait-only too.
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_karstSystemUi);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BanBuaTuongApp(),
    ),
  );
}

class BanBuaTuongApp extends ConsumerWidget {
  const BanBuaTuongApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    return MaterialApp(
      onGenerateTitle: (BuildContext ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      // The whole product shares the arcade-night shell; gameplay remains the
      // darkest layer so cyan trajectories and armed targets stay dominant.
      theme: BbTheme.light(),
      locale: Locale(settings.localeCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) =>
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: _karstSystemUi,
            child: child ?? const SizedBox.shrink(),
          ),
      home: const MenuScreen(),
    );
  }
}

const SystemUiOverlayStyle _karstSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarContrastEnforced: false,
);
