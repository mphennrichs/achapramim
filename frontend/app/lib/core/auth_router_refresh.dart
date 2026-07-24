import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'providers.dart';

/// Ponte entre [authStateProvider]/[currentUserProfileProvider] e
/// `GoRouter.refreshListenable`: só notifica quando o status de sessão muda
/// ou o perfil termina de carregar/muda de role — não a cada rebuild
/// intermediário — evitando que o router remonte a página atual à toa.
/// Reavaliar quando o perfil resolve é o que permite ao redirect (ver
/// router_provider.dart) bloquear /admin/* assim que souber a role real,
/// mesmo que a navegação para lá tenha acontecido antes do perfil carregar.
class AuthRouterRefresh extends ChangeNotifier {
  SessionStatus? _lastStatus;
  String? _lastRole;

  AuthRouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (previous, next) {
      if (next.status != _lastStatus) {
        _lastStatus = next.status;
        notifyListeners();
      }
    });
    ref.listen(currentUserProfileProvider, (previous, next) {
      final role = next.valueOrNull?.role;
      if (role != _lastRole) {
        _lastRole = role;
        notifyListeners();
      }
    });
  }
}

final authRouterRefreshProvider = Provider<AuthRouterRefresh>((ref) {
  return AuthRouterRefresh(ref);
});
