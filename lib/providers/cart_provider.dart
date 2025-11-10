import 'dart:math';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/cart_api.dart';
import '../data/order_api.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../data/app_state.dart';

// Persistence keys
const String _kCartJson = 'cart_json_v1';
const String _kCartKey = 'cart_key_v1';

String _generateCartKey() {
  final millis = DateTime.now().millisecondsSinceEpoch;
  final rand = Random().nextInt(1 << 31);
  return 'ck_${millis}_$rand';
}

final cartApiProvider = Provider<CartApi>((ref) => CartApi());
final orderApiProvider = Provider<OrderApi>((ref) => OrderApi());

class CartNotifier extends StateNotifier<Cart> {
  final CartApi _api;

  CartNotifier(this._api) : super(Cart.empty());

  Future<String> _ensureCartKey() async {
    final prefs = await SharedPreferences.getInstance();
    var key = prefs.getString(_kCartKey);
    if (key == null || key.isEmpty) {
      key = _generateCartKey();
      await prefs.setString(_kCartKey, key);
    }
    return key;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kCartJson);
    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          state = Cart.fromJson(decoded);
        }
      } catch (_) {
        // ignore decode errors and fetch from server
      }
    }
    final cartKey = await _ensureCartKey();
    final session = AppState.sessionToken;
    final latest = await _api.getCart(cartKey: cartKey, sessionToken: session);
    state = latest;
    await _persist(latest);
  }

  Future<void> addItem({required int partId, int quantity = 1}) async {
    final cartKey = await _ensureCartKey();
    final session = AppState.sessionToken;
    final updated = await _api.addItem(
      partId: partId,
      quantity: quantity,
      cartKey: cartKey,
      sessionToken: session,
    );
    state = updated;
    await _persist(updated);
  }

  Future<void> updateItem({required int itemId, required int quantity}) async {
    final cartKey = await _ensureCartKey();
    final session = AppState.sessionToken;
    final updated = await _api.updateItem(
      itemId: itemId,
      quantity: quantity,
      cartKey: cartKey,
      sessionToken: session,
    );
    state = updated;
    await _persist(updated);
  }

  Future<void> removeItem({required int itemId}) async {
    final cartKey = await _ensureCartKey();
    final session = AppState.sessionToken;
    final updated = await _api.removeItem(
      itemId: itemId,
      cartKey: cartKey,
      sessionToken: session,
    );
    state = updated;
    await _persist(updated);
  }

  Future<Order> checkoutCash({required String shippingAddress, required String phone}) async {
    final prefs = await SharedPreferences.getInstance();
    final cartKey = await _ensureCartKey();
    final session = AppState.sessionToken;
    final idemKey = 'idem_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}';
    final orderApi = OrderApi();
    final order = await orderApi.checkoutCash(
      shippingAddress: shippingAddress,
      phone: phone,
      cartKey: cartKey,
      sessionToken: session,
      idempotencyKey: idemKey,
    );
    // Clear cart on successful checkout
    state = Cart.empty();
    await prefs.remove(_kCartJson);
    return order;
  }

  Future<void> _persist(Cart cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCartJson, jsonEncode(cart.toJson()));
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  final api = ref.read(cartApiProvider);
  final notifier = CartNotifier(api);
  // Fire-and-forget initial load
  notifier.load();
  return notifier;
});