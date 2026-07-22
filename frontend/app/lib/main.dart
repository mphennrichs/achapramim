import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/login_screen.dart';
import 'features/watches/new_watch_screen.dart';
import 'features/watches/watch_detail_screen.dart';
import 'features/watches/watch_list_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: AchapramimApp()));
}

class AchapramimApp extends StatelessWidget {
  const AchapramimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Achapramim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const _EntryPoint(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';

    if (name == '/login') {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
    if (name == '/watches') {
      return MaterialPageRoute(builder: (_) => const WatchListScreen());
    }
    if (name == '/watches/new') {
      return MaterialPageRoute(builder: (_) => const NewWatchScreen());
    }
    final watchDetailMatch = RegExp(r'^/watches/([^/]+)$').firstMatch(name);
    if (watchDetailMatch != null) {
      final watchId = watchDetailMatch.group(1)!;
      return MaterialPageRoute(
        builder: (_) => WatchDetailScreen(watchId: watchId),
      );
    }
    return null;
  }
}

/// Decide a rota inicial com base em uma sessão já existente (token salvo).
class _EntryPoint extends ConsumerWidget {
  const _EntryPoint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    return FutureBuilder<bool>(
      future: authService.hasSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true ? const _RedirectToWatches() : const LoginScreen();
      },
    );
  }
}

class _RedirectToWatches extends StatefulWidget {
  const _RedirectToWatches();

  @override
  State<_RedirectToWatches> createState() => _RedirectToWatchesState();
}

class _RedirectToWatchesState extends State<_RedirectToWatches> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/watches');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
