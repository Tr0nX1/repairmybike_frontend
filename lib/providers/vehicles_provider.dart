import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/vehicles_api.dart';
import '../data/repositories/auth_repository.dart';

final vehiclesApiProvider = Provider<VehiclesApi>((ref) => VehiclesApi());

final userVehiclesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(vehiclesApiProvider);
  final auth = ref.watch(authProvider);
  if (auth.sessionToken == null) return [];
  return api.getUserVehicles(sessionToken: auth.sessionToken!);
});

final vehicleTypesProvider = FutureProvider<List<VehicleTypeItem>>((ref) async {
  final api = ref.read(vehiclesApiProvider);
  ref.keepAlive();
  return api.getVehicleTypes();
});

final vehicleBrandsProvider =
    FutureProvider.family<List<VehicleBrandItem>, int>((ref, typeId) async {
  final api = ref.read(vehiclesApiProvider);
  ref.keepAlive();
  return api.getVehicleBrands(typeId);
});

final vehicleModelsProvider =
    FutureProvider.family<List<VehicleModelItem>, int>((ref, brandId) async {
  final api = ref.read(vehiclesApiProvider);
  ref.keepAlive();
  return api.getVehicleModels(brandId);
});
