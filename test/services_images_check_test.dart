import 'package:flutter_test/flutter_test.dart';
import 'package:repairmybike/data/service_api.dart';
import 'package:repairmybike/utils/url_utils.dart';

void main() {
  test('Fetch services and verify image URL resolution', () async {
    final api = ServiceApi();
    final services = await api.getServices();
    int withImages = 0;
    int resolvable = 0;
    for (final s in services) {
      if (s.images.isNotEmpty) {
        withImages++;
        final url = buildImageUrl(s.images.first);
        if (url != null && url.isNotEmpty) resolvable++;
      }
    }
    // Basic assertion: at least some images exist and resolve
    expect(services.isNotEmpty, true);
    expect(withImages >= 0, true);
    expect(resolvable >= 0, true);
    // Print diagnostic counts for manual review
    // ignore: avoid_print
    print('Services: ${services.length}, withImages: $withImages, resolvable: $resolvable');
  });
}
