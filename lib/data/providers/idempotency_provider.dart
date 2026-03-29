import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Implements a simple, dependency-free UUID v4 generator for transaction idempotency.
String _generateUuidV4() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  
  // Set version to 4
  values[6] = (values[6] & 0x0f) | 0x40;
  // Set variant to 1
  values[8] = (values[8] & 0x3f) | 0x80;
  
  final hexStr = values.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
  return '${hexStr.sublist(0, 4).join()}-${hexStr.sublist(4, 6).join()}-${hexStr.sublist(6, 8).join()}-${hexStr.sublist(8, 10).join()}-${hexStr.sublist(10, 16).join()}';
}

class IdempotencyNotifier extends Notifier<String> {
  @override
  String build() {
    return _generateUuidV4();
  }

  /// Regenerate the idempotency key after a successful transaction.
  void refreshKey() {
    state = _generateUuidV4();
  }
}

/// A provider that holds the active idempotency key for the current checkout session.
final idempotencyKeyProvider = NotifierProvider<IdempotencyNotifier, String>(IdempotencyNotifier.new);
