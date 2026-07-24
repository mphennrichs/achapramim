import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';

/// Ponte entre [authStateProvider] e `GoRouter.refreshListenable`: só notifica
/// quando o status de sessão de fato muda, não a cada rebuild do provider —
/// evita que o router remonte a página atual por transições intermediárias.
class AuthRouterRefresh extends ChangeNotifier {
  SessionStatus? _lastStatus;

  AuthRouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (previous, next) {
      if (next.status != _lastStatus) {
        _lastStatus = next.status;
        notifyListeners();
      }
    });
  }
}

final authRouterRefreshProvider = Provider<AuthRouterRefresh>((ref) {
  return AuthRouterRefresh(ref);
});
