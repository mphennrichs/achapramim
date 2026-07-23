import '../models/user_profile.dart';
import 'api_client.dart';

class MeService {
  final ApiClient _client;

  MeService(this._client);

  Future<UserProfile> get() async {
    final response = await _client.dio.get('/api/me');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Define o Username do usuário no Primeiro Acesso (ver CONTEXT.md). Só
  /// funciona uma vez — o backend rejeita com 409 se já houver um username.
  Future<UserProfile> setUsername(String username) async {
    final response = await _client.dio.put(
      '/api/me/username',
      data: {'username': username},
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.put(
      '/api/me/password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Atualiza nome e/ou username do perfil. Campos omitidos não são
  /// alterados (diferente do Primeiro Acesso, o username pode ser trocado
  /// livremente aqui — só a unicidade é garantida pelo backend).
  Future<UserProfile> updateProfile({String? name, String? username}) async {
    final response = await _client.dio.put(
      '/api/me/profile',
      data: {
        'name': name,
        'username': username,
      }..removeWhere((_, value) => value == null),
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
