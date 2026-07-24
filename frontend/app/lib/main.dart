import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router_provider.dart';
import 'core/theme_mode_provider.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: AchapramimApp()));
}

class AchapramimApp extends ConsumerWidget {
  const AchapramimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Achapramim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
