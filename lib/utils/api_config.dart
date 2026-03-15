import 'package:flutter/foundation.dart';
import 'dart:io';

// Centralized backend base for APIs and media URLs
// In debug mode, we point to the local backend. In release, we use production.
const String _prodBase = 'https://repairmybikebackend-production.up.railway.app/';
const String _localBaseAndroid = 'http://10.0.2.2:8000/';
const String _localBaseOther = 'http://localhost:8000/';

String resolveBackendBase() {
  // Always use the production URL for APK testing as per user request
  return _prodBase;
}

final String backendBase = resolveBackendBase();

// Convenience bases for common API groups
String get apiBaseSpareParts => '${backendBase}api/spare-parts';
String get apiBaseVehicles => '${backendBase}api/vehicles';
String get apiBaseServices => '${backendBase}api/services';
String get apiBaseFeedback => '${backendBase}api/feedback';
String get apiBaseUrl => '${backendBase}api';
