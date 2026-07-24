import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/auth_service.dart';
import 'api/me_service.dart';
import 'providers.dart';

/// Estado de sessão resolvido para fins de roteamento. `unknown` é o estado
/// inicial antes da primeira checagem (evita decidir uma rota errada antes
/// de saber se há sessão); os demais refletem o que a API de fato confirma.
enum SessionStatus { unknown, unauthenticated, usernamePending, authenticated }

class AuthState {
  final SessionStatus status;

  const AuthState(this.status);

  static const unknown = AuthState(SessionStatus.unknown);
  static const unauthenticated = AuthState(SessionStatus.unauthenticated);
  static const usernamePending = AuthState(SessionStatus.usernamePending);
  static const authenticated = AuthState(SessionStatus.authenticated);
}

/// Fonte única de verdade da sessão — GoRouter observa isto (via
/// [authRouterRefreshProvider]) para decidir redirects, e login/logout/
/// set-username atualizam este notifier em vez de navegar imperativamente.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final MeService _meService;

  AuthNotifier(this._authService, this._meService) : super(AuthState.unknown) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (!await _authService.hasSession()) {
      state = AuthState.unauthenticated;
      return;
    }
    try {
      final profile = await _meService.get();
      state = profile.usernamePending ? AuthState.usernamePending : AuthState.authenticated;
    } on DioException {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> login({required String emailOrUsername, required String password}) async {
    final usernamePending = await _authService.login(
      emailOrUsername: emailOrUsername,
      password: password,
    );
    state = usernamePending ? AuthState.usernamePending : AuthState.authenticated;
  }

  void completeUsernameSetup() {
    state = AuthState.authenticated;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.unauthenticated;
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider), ref.watch(meServiceProvider));
});
