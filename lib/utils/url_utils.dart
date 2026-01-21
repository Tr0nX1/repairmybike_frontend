import 'api_config.dart';

bool _looksImageLike(String s) {
  final t = s.trim().toLowerCase();
  if (t.isEmpty) return false;
  if (t.startsWith('http://') || t.startsWith('https://') || t.startsWith('data:image/')) {
    return true;
  }
  if (t.startsWith('/') || t.startsWith('media/')) {
    return true;
  }
  for (final ext in ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.tiff']) {
    if (t.endsWith(ext)) return true;
  }
  return false;
}

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
