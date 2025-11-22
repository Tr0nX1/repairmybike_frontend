import 'package:flutter_test/flutter_test.dart';
import 'package:repairmybike/utils/url_utils.dart';
import 'package:repairmybike/data/vehicles_api.dart';

void main() {
  test('Analyze images for vehicle type/brand/model', () async {
    final api = VehiclesApi();
    final types = await api.getVehicleTypes();
    int typesWithImages = 0;
    for (final t in types) {
      final u = buildImageUrl(t.image);
      if (u != null) typesWithImages++;
    }
    // Print summary for terminal analysis
    // ignore: avoid_print
    print('VehicleTypes: total=${types.length}, withImages=$typesWithImages');

    int brandsTotal = 0;
    int brandsWithImages = 0;
    int modelsTotal = 0;
    int modelsWithImages = 0;

    for (final t in types.take(3)) { // limit for speed
      final brands = await api.getVehicleBrands(t.id);
      brandsTotal += brands.length;
      for (final b in brands) {
        final ub = buildImageUrl(b.image);
        if (ub != null) brandsWithImages++;
        // sample few models per brand
        try {
          final models = await api.getVehicleModels(b.id);
          modelsTotal += models.length;
          for (final m in models.take(5)) {
            final um = buildImageUrl(m.image);
            if (um != null) modelsWithImages++;
          }
        } catch (_) {}
      }
    }

    // ignore: avoid_print
    print('VehicleBrands: total=$brandsTotal, withImages=$brandsWithImages');
    // ignore: avoid_print
    print('VehicleModels: total=$modelsTotal, withImages=$modelsWithImages');

    expect(types.isNotEmpty, true); // basic sanity so test shows as passed
  });
}