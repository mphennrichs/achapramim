import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/set_username_screen.dart';
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
    if (name == '/set-username') {
      return MaterialPageRoute(builder: (_) => const SetUsernameScreen());
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
/// Quando há sessão, confirma o estado atual via GET /api/me em vez de só
/// checar se o token existe — evita depender de um flag local que ficaria
/// dessincronizado se o Primeiro Acesso for concluído em outra sessão.
class _EntryPoint extends ConsumerWidget {
  const _EntryPoint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final meService = ref.watch(meServiceProvider);

    return FutureBuilder<String>(
      future: () async {
        if (!await authService.hasSession()) return '/login';
        try {
          final profile = await meService.get();
          return profile.usernamePending ? '/set-username' : '/watches';
        } on DioException {
          return '/login';
        }
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _Redirect(route: snapshot.data ?? '/login');
      },
    );
  }
}

class _Redirect extends StatefulWidget {
  final String route;

  const _Redirect({required this.route});

  @override
  State<_Redirect> createState() => _RedirectState();
}

class _RedirectState extends State<_Redirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(widget.route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
