import 'package:dio/dio.dart';

import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<void> login({required String email, required String password}) async {
    final response = await _client.dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
      options: Options(extra: {'skipAuth': true}),
    );
    await _client.authStorage.saveTokens(
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
  }

  Future<void> logout() => _client.authStorage.clear();

  Future<bool> hasSession() async {
    final token = await _client.authStorage.readAccessToken();
    return token != null;
  }
}
