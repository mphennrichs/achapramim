import '../models/link_preview.dart';
import 'api_client.dart';

class LinkPreviewService {
  final ApiClient _client;

  LinkPreviewService(this._client);

  Future<LinkPreviewProposal> preview(String url) async {
    final response = await _client.dio.post(
      '/api/watches/link-preview',
      data: {'url': url},
    );
    return LinkPreviewProposal.fromJson(response.data as Map<String, dynamic>);
  }
}
