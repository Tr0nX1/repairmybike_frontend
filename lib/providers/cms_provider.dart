import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cms_api.dart';
import '../models/banner.dart';

final bannersProvider = FutureProvider<List<BannerItem>>((ref) async {
  final api = ref.read(cmsApiProvider);
  return api.getBanners();
});
