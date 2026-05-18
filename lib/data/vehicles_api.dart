import 'api_client.dart';

class VehicleTypeItem {
  final int id;
  final String name;
  final String? image;

  VehicleTypeItem({required this.id, required this.name, this.image});

  factory VehicleTypeItem.fromJson(Map<String, dynamic> json) {
    String? extractUrl(dynamic v) {
      if (v == null) return null;
      if (v is Map) return (v['original'] ?? v['thumbnail'])?.toString();
      return v.toString();
    }
    return VehicleTypeItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      image: extractUrl(json['image'] ?? json['logo'] ?? json['icon']),
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
    String? extractUrl(dynamic v) {
      if (v == null) return null;
      if (v is Map) return (v['original'] ?? v['thumbnail'])?.toString();
      return v.toString();
    }
    return VehicleBrandItem(
      id: (json['id'] as num).toInt(),
      vehicleTypeId: (json['vehicle_type'] as num).toInt(),
      vehicleTypeName: json['vehicle_type_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: extractUrl(json['image'] ?? json['logo'] ?? json['icon']),
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
    String? extractUrl(dynamic v) {
      if (v == null) return null;
      if (v is Map) return (v['original'] ?? v['thumbnail'])?.toString();
      return v.toString();
    }
    int extractBrandId() {
      final rawBrand = json['vehicle_brand'];
      if (rawBrand is num) return rawBrand.toInt();
      if (rawBrand is Map && rawBrand['id'] is num) {
        return (rawBrand['id'] as num).toInt();
      }
      final fallback = json['vehicle_brand_id'] ?? json['brand_id'];
      if (fallback is num) return fallback.toInt();
      return 0;
    }
    return VehicleModelItem(
      id: (json['id'] as num).toInt(),
      vehicleBrandId: extractBrandId(),
      brandName: json['brand_name'] as String? ?? '',
      vehicleTypeName:
          json['vehicle_type_name'] as String? ?? json['type_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: extractUrl(json['image'] ?? json['logo'] ?? json['icon']),
    );
  }
}

class VehiclesApi {
  final Dio _dio;
  VehiclesApi() : _dio = ApiClient().dio;


  Future<List<VehicleTypeItem>> getVehicleTypes() async {
    final res = await _dio.get('api/vehicles/vehicle-types/');
    final body = res.data;
    
    // DRF Standard Pagination or Wrapped Data
    if (body is Map<String, dynamic>) {
      if (body['error'] == true) {
        throw Exception(body['message'] ?? 'Failed to load vehicle types');
      }
      final data = body['results'] ?? body['data'] ?? body;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(VehicleTypeItem.fromJson)
            .toList();
      }
    }
    
    // Direct List
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(VehicleTypeItem.fromJson)
          .toList();
    }
    
    throw Exception('Unexpected response shape for vehicle types');
  }

  Future<List<VehicleBrandItem>> getVehicleBrands(int vehicleTypeId) async {
    final res = await _dio.get(
      'api/vehicles/vehicle-brands/',
      queryParameters: {'vehicle_type': vehicleTypeId},
    );
    final body = res.data;
    
    if (body is Map<String, dynamic>) {
      if (body['error'] == true) {
        throw Exception(body['message'] ?? 'Failed to load vehicle brands');
      }
      final data = body['results'] ?? body['data'] ?? body;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(VehicleBrandItem.fromJson)
            .toList();
      }
    }

    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(VehicleBrandItem.fromJson)
          .toList();
    }

    throw Exception('Unexpected response shape for vehicle brands');
  }

  Future<List<VehicleModelItem>> getVehicleModels(int vehicleBrandId) async {
    final res = await _dio.get(
      'api/vehicles/vehicle-models/',
      queryParameters: {'vehicle_brand': vehicleBrandId},
    );
    final body = res.data;

    if (body is Map<String, dynamic>) {
      if (body['error'] == true) {
        throw Exception(body['message'] ?? 'Failed to load vehicle models');
      }
      final data = body['results'] ?? body['data'] ?? body;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(VehicleModelItem.fromJson)
            .toList();
      }
    }

    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(VehicleModelItem.fromJson)
          .toList();
    }

    throw Exception('Unexpected response shape for vehicle models');
  }

  Future<VehicleModelItem> getVehicleModelById(int modelId) async {
    final res = await _dio.get('api/vehicles/vehicle-models/$modelId/');
    final body = res.data;
    if (body is Map<String, dynamic>) {
      if (body['error'] == true) {
        throw Exception(body['message'] ?? 'Failed to load vehicle model');
      }
      return VehicleModelItem.fromJson(body);
    }
    throw Exception('Unexpected response shape for vehicle model $modelId');
  }

  Future<Map<String, dynamic>> addUserVehicle({
    required String sessionToken,
    required int vehicleModelId,
  }) async {
    final res = await _dio.post(
      'api/vehicles/user-vehicles/',
      data: {'vehicle_model_id': vehicleModelId, 'is_default': true},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response shape for add user vehicle');
  }

  Future<List<Map<String, dynamic>>> getUserVehicles({
    required String sessionToken,
  }) async {
    final res = await _dio.get('api/vehicles/user-vehicles/');
    final body = res.data;

    if (body is Map<String, dynamic>) {
      if (body['error'] == true) {
         throw Exception(body['message'] ?? 'Failed to load user vehicles');
      }
      final data = body['results'] ?? body['data'] ?? body;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }

    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }

    throw Exception('Unexpected response shape for user vehicles');
  }
}
