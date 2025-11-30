// Centralized backend base for APIs and media URLs (fixed to production)
// No environment overrides to ensure consistent interaction with production API.
const String backendBase = 'https://repairmybikebackend-production.up.railway.app';

String resolveBackendBase() => backendBase;

// Convenience bases for common API groups (fixed to production base)
String get apiBaseSpareParts => '$backendBase/api/spare-parts';
String get apiBaseVehicles => '$backendBase/api/vehicles';
String get apiBaseServices => '$backendBase/api/services';
