import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network/secure_api_client.dart';
import '../models/banner.dart';

final cmsApiProvider = Provider<CMSApi>((ref) {
  final client = ref.watch(secureApiClientProvider);
  return CMSApi(client);
});

class CMSApi {
  final Dio _client;
  CMSApi(this._client);

  Future<List<BannerItem>> getBanners() async {
    try {
      final response = await _client.get('api/cms/banners/');
      List<dynamic> list = [];
      if (response.data is List) {
        list = response.data;
      } else if (response.data is Map && response.data['data'] is List) {
        list = response.data['data'];
      }
      
      return list.map((e) => BannerItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
