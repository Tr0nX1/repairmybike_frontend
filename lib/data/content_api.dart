import 'api_client.dart';
import '../models/content.dart';

class ContentApi {
  final _client = ApiClient().dio;

  Future<List<CarouselItem>> getCarousel() async {
    try {
      final response = await _client.get('api/content/carousel/');
      final list = (response.data as List).cast<Map<String, dynamic>>();
      return list.map((e) => CarouselItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SupportOption>> getSupportOptions() async {
    try {
      final response = await _client.get('api/content/support/');
      final list = (response.data as List).cast<Map<String, dynamic>>();
      return list.map((e) => SupportOption.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Policy?> getPolicy(String slug) async {
    try {
      final response = await _client.get('api/content/policy/$slug/');
      return Policy.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }
}
