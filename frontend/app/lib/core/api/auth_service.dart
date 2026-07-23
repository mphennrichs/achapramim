import 'package:dio/dio.dart';

import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  /// [emailOrUsername] aceita indistintamente o email ou o Username do User
  /// (ver CONTEXT.md) no mesmo campo. Retorna se o Username ainda está
  /// pendente de definição (Primeiro Acesso).
  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final response = await _client.dio.post(
      '/api/auth/login',
      data: {'email_or_username': emailOrUsername, 'password': password},
      options: Options(extra: {'skipAuth': true}),
    );
    await _client.authStorage.saveTokens(
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
    return response.data['username_pending'] as bool? ?? false;
  }

  Future<void> logout() => _client.authStorage.clear();

  Future<bool> hasSession() async {
    final token = await _client.authStorage.readAccessToken();
    return token != null;
  }
}
