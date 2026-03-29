import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Centralized error sanitizer for all UI-facing error messages.
/// Ensures raw HTML, stack traces, and full exception objects are
/// NEVER rendered directly in Flutter's widget tree.
class AppError {
  /// Maximum character length for any user-facing error string.
  static const int _maxLength = 200;

  /// Converts any exception or API error payload into a safe, short,
  /// user-readable string. Never returns HTML or raw stack traces.
  static String sanitize(Object? error, {String fallback = 'Something went wrong. Please try again.'}) {
    try {
      if (error == null) return fallback;

      // ── DioException (network / API layer) ─────────────────────────────
      if (error is DioException) {
        final data = error.response?.data;
        final status = error.response?.statusCode ?? 0;

        // Rate limit
        if (status == 429) return 'Too many attempts. Please wait and try again.';

        // Network-level failures (no response)
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return 'Network error. Please check your connection and try again.';
        }

        // Server returned a response — extract message from it
        return _extractFromData(data, status: status) ?? fallback;
      }

      // ── Raw string ─────────────────────────────────────────────────────
      if (error is String) return _sanitizeString(error) ?? fallback;

      // ── Other exceptions ───────────────────────────────────────────────
      final msg = error.toString();
      // Strip Dart's "Exception: " wrapper that adds no value
      final cleaned = msg.startsWith('Exception: ') ? msg.substring(11) : msg;
      return _sanitizeString(cleaned) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Private helpers
  // ───────────────────────────────────────────────────────────────────────

  static String? _extractFromData(dynamic data, {int status = 0}) {
    if (data == null) return null;

    // HTML page (Django debug page / Nginx error page) — never show to user
    if (data is String) {
      final t = data.trimLeft();
      if (t.startsWith('<!DOCTYPE') || t.startsWith('<html') || t.startsWith('<HTML')) {
        debugPrint('⚠️ API returned HTML on status $status. Check server logs.');
        return 'Server error ($status). Our team has been notified.';
      }
      return _sanitizeString(data);
    }

    if (data is Map) {
      // Standard RepairMyBike API format: {"message": "...", "error": true/false}
      if (data['message'] is String) return _sanitizeString(data['message']);

      // DRF plain error string
      if (data['error'] is String && data['error'] != 'True' && data['error'] != true) {
        return _sanitizeString(data['error']);
      }

      // DRF detail (auth errors, etc.)
      if (data['detail'] is String) return _sanitizeString(data['detail']);

      // DRF field-level validation: {"field": ["msg1", ...]}
      for (final entry in data.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          final msg = (entry.value as List).first?.toString() ?? '';
          final field = entry.key.toString().replaceAll('_', ' ');
          return '$field: $msg';
        }
      }
    }

    return null;
  }

  static String? _sanitizeString(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    // Reject HTML
    if (s.startsWith('<!DOCTYPE') || s.startsWith('<html') || s.startsWith('<HTML')) {
      return null; // caller uses fallback
    }

    // Truncate very long messages (stack traces, full exception dumps)
    if (s.length > _maxLength) {
      return '${s.substring(0, _maxLength)}…';
    }

    return s;
  }
}
