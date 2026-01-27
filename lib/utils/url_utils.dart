import 'api_config.dart';


String? buildImageUrl(dynamic media) {
  if (media == null) return null;
  
  // Handle new standardized media object (Map)
  if (media is Map) {
    return media['original'] ?? media['thumbnail'];
  }
  
  // Handle raw string (backward compatibility / direct URLs)
  if (media is String) {
    if (media.isEmpty) return null;
    if (media.startsWith('http')) return media;
    // Fallback for any remaining relative paths (should be minimal after backend refactor)
    String base = resolveBackendBase();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (media.startsWith('/')) return '$base$media';
    return '$base/media/$media';
  }
  
  return null;
}
