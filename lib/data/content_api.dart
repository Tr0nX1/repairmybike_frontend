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
    // BUG 3 FIX: Return static support info as the backend endpoint is missing
    return [
      SupportOption(
        id: 1, 
        title: 'Call Us', 
        type: SupportType.call, 
        value: '+91 8168121711', 
        order: 1,
        bgColor: '0xFF1BBE7B', // Neon Green
      ),
      SupportOption(
        id: 2, 
        title: 'Email Us', 
        type: SupportType.email, 
        value: 'support@repairmybike.in', 
        order: 2,
        bgColor: '0xFF01C9F5', // Neon Blue
      ),
      SupportOption(
        id: 3, 
        title: 'WhatsApp', 
        type: SupportType.whatsapp, 
        value: '+91 8168121711', 
        order: 3,
        bgColor: '0xFF25D366', // WhatsApp Green
      ),
    ];
  }

  Future<Policy?> getPolicy(String slug) async {
    try {
      final response = await _client.get('api/content/pages/$slug/');
      return Policy.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }
}
