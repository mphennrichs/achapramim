import '../models/offer.dart';
import '../models/watch.dart';
import 'api_client.dart';

class WatchService {
  final ApiClient _client;

  WatchService(this._client);

  Future<List<Watch>> list() async {
    final response = await _client.dio.get('/api/watches');
    return (response.data as List<dynamic>)
        .map((json) => Watch.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Alertas de todos os Users (admin) — só tem efeito para quem tem
  /// role=admin; um User comum recebe apenas os próprios Alertas de volta.
  Future<List<Watch>> listAll() async {
    final response = await _client.dio.get(
      '/api/watches',
      queryParameters: {'all': 'true'},
    );
    return (response.data as List<dynamic>)
        .map((json) => Watch.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Watch> get(String id) async {
    final response = await _client.dio.get('/api/watches/$id');
    return Watch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Watch> create(Watch watch) async {
    final response = await _client.dio.post(
      '/api/watches',
      data: watch.toRequestJson(),
    );
    return Watch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Watch> update(String id, Watch watch) async {
    final response = await _client.dio.put(
      '/api/watches/$id',
      data: watch.toRequestJson(),
    );
    return Watch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Watch> setActive(String id, bool active) async {
    final response = await _client.dio.patch(
      '/api/watches/$id/active',
      data: {'active': active},
    );
    return Watch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _client.dio.delete('/api/watches/$id');

  Future<List<Offer>> offers(String watchId) async {
    final response = await _client.dio.get('/api/watches/$watchId/offers');
    return (response.data as List<dynamic>)
        .map((json) => Offer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PricePoint>> priceHistory(String watchId, String offerId) async {
    final response = await _client.dio.get(
      '/api/watches/$watchId/offers/$offerId/price-history',
    );
    return (response.data as List<dynamic>)
        .map((json) => PricePoint.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScanSummary>> scans(String watchId) async {
    final response = await _client.dio.get('/api/watches/$watchId/scans');
    return (response.data as List<dynamic>)
        .map((json) => ScanSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
