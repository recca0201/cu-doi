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
  await SystemChrome.setPreferredOrientations(
    const <DeviceOrientation>[DeviceOrientation.portraitUp],
  );
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
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
      // Menus keep the parent brand's daylight cream theme; only the arena goes
      // to the night stage. That contrast is intentional — the brand stays
      // recognisable in the shell, the game reads as something new.
      theme: BbTheme.light(),
      locale: Locale(settings.localeCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MenuScreen(),
    );
  }
}
