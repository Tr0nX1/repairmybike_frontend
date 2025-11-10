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

String? buildImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final trimmed = url.trim();
  if (!_looksImageLike(trimmed)) return null; // guard against description text
  // Absolute HTTP(S)
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  // Protocol-relative (rare)
  if (trimmed.startsWith('//')) {
    return 'https:$trimmed';
  }
  // Data URLs (base64 images)
  if (trimmed.startsWith('data:')) {
    return trimmed;
  }
  // Resolve base per platform (handles Android emulator mapping)
  final base = resolveBackendBase();
  // Backend relative path
  if (trimmed.startsWith('/')) {
    return '$base$trimmed';
  }
  // Relative media path without leading slash
  return '$base/$trimmed';
}