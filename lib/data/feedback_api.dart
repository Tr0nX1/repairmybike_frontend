import 'api_client.dart';
import '../utils/api_config.dart';

class FeedbackApi {
  final Dio _dio;
  final String baseUrl;

  FeedbackApi({Dio? dio, String? base})
      : _dio = dio ?? ApiClient().dio,
        baseUrl = base ?? apiBaseFeedback;

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

    final response = await _dio.post('api/feedback/', data: payload);
    return response.data;
  }

  Future<void> uploadReviewPhoto(int reviewId, dynamic imageFile) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
    });

    await _dio.post('api/feedback/$reviewId/upload-photo/', data: formData);
  }

  Future<List<Map<String, dynamic>>> getReviews({int? bookingId}) async {
    final params = <String, dynamic>{};
    if (bookingId != null) params['booking_id'] = bookingId;

    final response = await _dio.get('api/feedback/', queryParameters: params);
    if (response.data is List) {
      return (response.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// New implementation for Phase C5
  Future<void> submitFeedback({
    required int bookingId,
    required int rating,
    required String comment,
    required String category, // 'service' | 'app' | 'complaint' | 'suggestion'
  }) async {
    final payload = {
      'booking': bookingId,
      'rating': rating,
      'comment': comment,
      'category': category,
    };

    try {
      final res = await _dio.post('api/feedback/', data: payload);
      if (res.data?['error'] == true) {
         throw Exception(res.data?['message'] ?? 'Failed to submit feedback');
      }
    } catch (e) {
      throw Exception('Feedback error: $e');
    }
  }
}
