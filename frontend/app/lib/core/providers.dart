import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'api/auth_service.dart';
import 'api/link_preview_service.dart';
import 'api/watch_service.dart';

/// URL base da API.
///
/// Em release (o build servido em produção, atrás do Traefik no mesmo
/// domínio via PathPrefix(/api)), o padrão é string vazia — Dio resolve
/// caminhos relativos contra a própria origem da página, sem precisar saber
/// o domínio de antemão. Em debug, aponta para o backend local. Pode ser
/// sobrescrito em qualquer build via --dart-define=API_BASE_URL=https://...
const _defaultApiBaseUrl = kReleaseMode ? '' : 'http://localhost:8080';

final apiBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ref.watch(apiBaseUrlProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

final watchServiceProvider = Provider<WatchService>((ref) {
  return WatchService(ref.watch(apiClientProvider));
});

final linkPreviewServiceProvider = Provider<LinkPreviewService>((ref) {
  return LinkPreviewService(ref.watch(apiClientProvider));
});
