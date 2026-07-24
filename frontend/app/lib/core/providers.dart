import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/admin_service.dart';
import 'api/api_client.dart';
import 'api/auth_service.dart';
import 'api/link_preview_service.dart';
import 'api/me_service.dart';
import 'api/watch_service.dart';
import 'models/scan_settings.dart';
import 'models/user_profile.dart';

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

final meServiceProvider = Provider<MeService>((ref) {
  return MeService(ref.watch(apiClientProvider));
});

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(apiClientProvider));
});

/// Perfil do User autenticado — usado pela sidebar para decidir se mostra os
/// itens de admin (role) e pela tela de Perfil para exibir/editar os dados.
/// Não é autoDispose: precisa persistir durante toda a sessão, não só
/// enquanto uma tela específica está montada.
final currentUserProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(meServiceProvider).get();
});

/// Configuração global de Scan (região padrão, palavras bloqueadas seed,
/// intervalo) — GET é liberado a qualquer User autenticado (só o PUT é
/// admin-only, ver router.go); autoDispose porque só é usado por telas
/// pontuais (Novo Alerta, Configurações Globais), não pela sessão inteira.
final scanSettingsProvider = FutureProvider.autoDispose<ScanSettings>((ref) {
  return ref.watch(adminServiceProvider).getScanSettings();
});

/// Histórico de custo da conta Apify (usada pelo FacebookMarketplaceFetcher,
/// ver ADR 0006) — consulta a API do Apify ao vivo via backend, sem
/// persistência própria; autoDispose porque só a tela de Configurações
/// Globais usa.
final apifyUsageProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminServiceProvider).getApifyUsage();
});
