import 'package:dio/dio.dart';
import '../utils/api_config.dart';

class VehicleTypeItem {
  final int id;
  final String name;
  final String? image;

  VehicleTypeItem({required this.id, required this.name, this.image});

  factory VehicleTypeItem.fromJson(Map<String, dynamic> json) {
    return VehicleTypeItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      image: (json['image'] as String?) ?? (json['logo'] as String?) ?? (json['icon'] as String?),
    );
  }
}

class VehicleBrandItem {
  final int id;
  final int vehicleTypeId;
  final String vehicleTypeName;
  final String name;
  final String? image;

  VehicleBrandItem({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.name,
    this.image,
  });

  factory VehicleBrandItem.fromJson(Map<String, dynamic> json) {
    return VehicleBrandItem(
      id: (json['id'] as num).toInt(),
      vehicleTypeId: (json['vehicle_type'] as num).toInt(),
      vehicleTypeName: json['vehicle_type_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: (json['image'] as String?) ?? (json['logo'] as String?) ?? (json['icon'] as String?),
    );
  }
}

class VehicleModelItem {
  final int id;
  final int vehicleBrandId;
  final String brandName;
  final String vehicleTypeName;
  final String name;
  final String? image;

  VehicleModelItem({
    required this.id,
    required this.vehicleBrandId,
    required this.brandName,
    required this.vehicleTypeName,
    required this.name,
    this.image,
  });

  factory VehicleModelItem.fromJson(Map<String, dynamic> json) {
    return VehicleModelItem(
      id: (json['id'] as num).toInt(),
      vehicleBrandId: (json['vehicle_brand'] as num).toInt(),
      brandName: json['brand_name'] as String? ?? '',
      vehicleTypeName: json['vehicle_type_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: (json['image'] as String?) ?? (json['logo'] as String?) ?? (json['icon'] as String?),
    );
  }
}

class VehiclesApi {
  final Dio _dio;

  VehiclesApi()
      : _dio = Dio(
          BaseOptions(
            baseUrl: resolveBackendBase(),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  Future<List<VehicleTypeItem>> getVehicleTypes() async {
    final res = await _dio.get('/api/vehicles/vehicle-types/');
    final body = res.data;
    if (body is Map<String, dynamic>) {
      if (body['error'] == true) {
        throw Exception(body['message'] ?? 'Failed to load vehicle types');
      }
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(VehicleTypeItem.fromJson)
            .toList();
      }
    }
    throw Exception('Unexpected response shape for vehicle types');
  }

  Future<List<VehicleBrandItem>> getVehicleBrands(int vehicleTypeId) async {
    final res = await _dio.get(
      '/api/vehicles/vehicle-brands/',
      queryParameters: {'vehicle_type': vehicleTypeId},
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      if (body['error'] == true) {
        throw Exception(body['message'] ?? 'Failed to load vehicle brands');
      }
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(VehicleBrandItem.fromJson)
            .toList();
      }
    }
    throw Exception('Unexpected response shape for vehicle brands');
  }

  Future<List<VehicleModelItem>> getVehicleModels(int vehicleBrandId) async {
    final res = await _dio.get(
      '/api/vehicles/vehicle-models/',
      queryParameters: {'vehicle_brand': vehicleBrandId},
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      if (body['error'] == true) {
        throw Exception(body['message'] ?? 'Failed to load vehicle models');
      }
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(VehicleModelItem.fromJson)
            .toList();
      }
    }
    throw Exception('Unexpected response shape for vehicle models');
  }
}