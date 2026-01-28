import 'package:dio/dio.dart';
import 'api_client.dart';
import '../utils/api_config.dart';

class FeedbackApi {
  final Dio _dio;
  final String baseUrl;

  FeedbackApi({Dio? dio, String? base})
      : _dio = dio ?? ApiClient().dio,
        baseUrl = base ?? '$apiBaseUrl/feedback';

  Future<Map<String, dynamic>> submitReview({
    required String reviewType, // 'SERVICE', 'PRODUCT', 'APP'
    required int targetId,
    required int rating,
    int? qualityRating,
    int? behaviorRating,
    int? appRating,
    String? comment,
    List<String>? chips,
    int? bookingId,
    int? orderId,
  }) async {
    final payload = {
      'review_type': reviewType,
      'target_id': targetId,
      'rating': rating,
      'quality_rating': qualityRating,
      'behavior_rating': behaviorRating,
      'app_rating': appRating,
      'comment': comment ?? '',
      'chips': chips ?? [],
      'booking': bookingId,
      'order': orderId,
    };

    final response = await _dio.post('$baseUrl/reviews/', data: payload);
    return response.data;
  }

  Future<void> uploadReviewPhoto(int reviewId, dynamic imageFile) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
    });

    await _dio.post('$baseUrl/reviews/$reviewId/upload-photo/', data: formData);
  }

  Future<List<Map<String, dynamic>>> getReviews({String? type, int? targetId}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    if (targetId != null) params['target_id'] = targetId;

    final response = await _dio.get('$baseUrl/reviews/', queryParameters: params);
    if (response.data is List) {
      return (response.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
