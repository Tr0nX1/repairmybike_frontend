// Centralized backend base for APIs and media URLs
// Override at build time with: --dart-define=BACKEND_BASE=http://localhost:8000
import 'package:flutter/foundation.dart';

const String backendBase = String.fromEnvironment(
  'BACKEND_BASE',
  defaultValue: 'https://repairmybikebackend-production.up.railway.app',
);

// Resolve base URL per platform (fixes Android emulator localhost mapping)
// On Android emulator, 127.0.0.1/localhost should be 10.0.2.2.
String resolveBackendBase() {
  final base = backendBase;
  // Web uses as-is; no dart:io or emulator mapping required
  if (kIsWeb) return base;

  // Detect Android via Flutter foundation instead of dart:io (works on web builds)
  if (defaultTargetPlatform == TargetPlatform.android) {
    final uri = Uri.tryParse(base);
    if (uri != null) {
      final host = uri.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        final mapped = uri.replace(host: '10.0.2.2');
        return mapped.toString();
      }
    }
  }
  return base;
}

// Convenience bases for common API groups
const String apiBaseSpareParts = '$backendBase/api/spare-parts';
const String apiBaseVehicles = '$backendBase/api/vehicles';
const String apiBaseServices = '$backendBase/api/services';