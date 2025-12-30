import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      image:
          (json['image'] as String?) ??
          (json['logo'] as String?) ??
          (json['icon'] as String?),
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
      image:
          (json['image'] as String?) ??
          (json['logo'] as String?) ??
          (json['icon'] as String?),
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
      image:
          (json['image'] as String?) ??
          (json['logo'] as String?) ??
          (json['icon'] as String?),
    );
  }
}

class VehiclesApi {
  final Dio _dio;

  VehiclesApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: backendBase,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ) {
    assert(() {
      _dio.interceptors.add(
        LogInterceptor(request: true, responseBody: false, error: true),
      );
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            debugPrint('➡️ ${o.method} ${o.uri}');
            h.next(o);
          },
          onResponse: (r, h) {
            debugPrint(
              '✅ ${r.requestOptions.method} ${r.requestOptions.uri} -> ${r.statusCode}',
            );
            h.next(r);
          },
          onError: (e, h) {
            debugPrint(
              '❌ ${e.requestOptions.method} ${e.requestOptions.uri} -> ${e.message}',
            );
            h.next(e);
          },
        ),
      );
      return true;
    }());
  }

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

  Future<Map<String, dynamic>> addUserVehicle({
    required String sessionToken,
    required int vehicleModelId,
  }) async {
    final res = await _dio.post(
      '/api/vehicles/user-vehicles/',
      data: {'vehicle_model_id': vehicleModelId, 'is_default': true},
      options: Options(headers: {'Authorization': 'Bearer $sessionToken'}),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response shape for add user vehicle');
  }

  Future<List<Map<String, dynamic>>> getUserVehicles({
    required String sessionToken,
  }) async {
    final res = await _dio.get(
      '/api/vehicles/user-vehicles/',
      options: Options(headers: {'Authorization': 'Bearer $sessionToken'}),
    );
    final body = res.data;
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }
    // Pagination check
    if (body is Map<String, dynamic>) {
      if (body['results'] is List) {
        return (body['results'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }
    throw Exception('Unexpected response shape for user vehicles');
  }
}
