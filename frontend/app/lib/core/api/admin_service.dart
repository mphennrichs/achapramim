import '../models/apify_usage.dart';
import '../models/scan_settings.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

/// Ações restritas a admin: gestão de Users e configuração global de Scan.
/// O backend já garante autorização (auth.RequireAdmin) — este service não
/// duplica essa checagem, só chama as rotas.
class AdminService {
  final ApiClient _client;

  AdminService(this._client);

  Future<List<UserProfile>> listUsers() async {
    final response = await _client.dio.get('/api/users');
    return (response.data as List<dynamic>)
        .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? username,
  }) async {
    final response = await _client.dio.post(
      '/api/users',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'username': username,
      },
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> setUserRole(String userId, String role) async {
    final response = await _client.dio.patch(
      '/api/users/$userId/role',
      data: {'role': role},
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> setUsername(String userId, String username) async {
    final response = await _client.dio.patch(
      '/api/users/$userId/username',
      data: {'username': username},
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Checagem de disponibilidade em tempo real (criação/edição de username
  /// pelo admin) — evita depender só do 409 do backend pra dar feedback.
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _client.dio.get(
      '/api/users/username-available',
      queryParameters: {'u': username},
    );
    return (response.data as Map<String, dynamic>)['available'] as bool;
  }

  Future<UserProfile> setUserActive(String userId, bool active) async {
    final response = await _client.dio.patch(
      '/api/users/$userId/active',
      data: {'active': active},
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ScanSettings> getScanSettings() async {
    final response = await _client.dio.get('/api/scan-settings');
    return ScanSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ScanSettings> updateScanSettings(ScanSettings settings) async {
    final response = await _client.dio.put(
      '/api/scan-settings',
      data: settings.toRequestJson(),
    );
    return ScanSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApifyUsage> getApifyUsage() async {
    final response = await _client.dio.get('/api/admin/apify-usage');
    return ApifyUsage.fromJson(response.data as Map<String, dynamic>);
  }
}
