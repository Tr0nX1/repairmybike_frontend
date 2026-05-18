import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_state.dart';
import 'vehicles_provider.dart';

class CurrentVehicle {
  final int? modelId;
  final String? name;
  final String? brandName;
  final String? typeName;
  final String? imageUrl;

  const CurrentVehicle({
    this.modelId,
    this.name,
    this.brandName,
    this.typeName,
    this.imageUrl,
  });

  bool get isSet => modelId != null;

  CurrentVehicle copyWith({
    int? modelId,
    String? name,
    String? brandName,
    String? typeName,
    String? imageUrl,
  }) =>
      CurrentVehicle(
        modelId: modelId ?? this.modelId,
        name: name ?? this.name,
        brandName: brandName ?? this.brandName,
        typeName: typeName ?? this.typeName,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}

class CurrentVehicleNotifier extends Notifier<CurrentVehicle> {
  @override
  CurrentVehicle build() {
    return _hydrateFromLocal();
  }

  CurrentVehicle _hydrateFromLocal() {
    if (AppState.vehicleModelId == null) {
      return const CurrentVehicle();
    }
    return CurrentVehicle(
      modelId: AppState.vehicleModelId,
      name: AppState.vehicleName,
      brandName: AppState.vehicleBrand,
      typeName: AppState.vehicleType,
      imageUrl: AppState.vehicleImageUrl,
    );
  }

  void hydrateFromProfile(Map<String, dynamic>? defaultVehicle) {
    if (defaultVehicle == null) {
      state = const CurrentVehicle();
      return;
    }
    final id = (defaultVehicle['id'] as num?)?.toInt();
    if (id == null) return;
    state = CurrentVehicle(
      modelId: id,
      name: defaultVehicle['name']?.toString(),
      brandName: defaultVehicle['brand_name']?.toString(),
      typeName: defaultVehicle['type_name']?.toString(),
      imageUrl: defaultVehicle['image']?.toString(),
    );
  }

  Future<void> setVehicle({
    required int modelId,
    required String name,
    String? brandName,
    String? typeName,
    String? imageUrl,
    bool syncToBackend = true,
  }) async {
    await AppState.setVehicle(
      name: name,
      type: typeName,
      brand: brandName,
      modelId: modelId,
      imageUrl: imageUrl,
      syncToBackend: syncToBackend,
    );

    state = CurrentVehicle(
      modelId: modelId,
      name: name,
      brandName: brandName,
      typeName: typeName,
      imageUrl: imageUrl,
    );

    if (syncToBackend) {
      ref.invalidate(userVehiclesProvider);
    }
  }

  void clear() => state = const CurrentVehicle();
}

final currentVehicleProvider =
    NotifierProvider<CurrentVehicleNotifier, CurrentVehicle>(
  CurrentVehicleNotifier.new,
);
