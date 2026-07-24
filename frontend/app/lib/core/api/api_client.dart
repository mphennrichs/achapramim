import 'package:dio/dio.dart';

import 'auth_storage.dart';

/// Lançada quando o refresh token também expirou/foi revogado — o app deve
/// derrubar a sessão e voltar para a tela de login.
class SessionExpiredException implements Exception {}

/// Wrapper fino sobre Dio: injeta o access token em toda requisição
/// autenticada e tenta um refresh automático (uma vez) em respostas 401.
class ApiClient {
  final Dio dio;
  final AuthStorage authStorage;

  ApiClient({required String baseUrl, AuthStorage? authStorage})
    : dio = Dio(BaseOptions(baseUrl: baseUrl)),
      authStorage = authStorage ?? AuthStorage() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.extra.containsKey('skipAuth')) {
            final token = await this.authStorage.readAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          if (isUnauthorized && !alreadyRetried) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final retryOptions = error.requestOptions;
              retryOptions.extra['retried'] = true;
              try {
                final response = await dio.fetch(retryOptions);
                handler.resolve(response);
                return;
              } on DioException catch (retryError) {
                handler.next(retryError);
                return;
              }
            }
            await this.authStorage.clear();
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: SessionExpiredException(),
              ),
            );
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await authStorage.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await dio.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      await authStorage.saveTokens(
        accessToken: response.data['access_token'] as String,
        refreshToken: response.data['refresh_token'] as String,
      );
      return true;
    } on DioException {
      return false;
    }
  }
}
