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
const String _kCartKey = 'session_id_v1';

String _generateCartKey() {
  final millis = DateTime.now().millisecondsSinceEpoch;
  final rand = Random().nextInt(1 << 31);
  return 'sess_${millis}_$rand';
}

final cartApiProvider = Provider<CartApi>((ref) => CartApi());
final orderApiProvider = Provider<OrderApi>((ref) => OrderApi());

class CartNotifier extends Notifier<Cart> {
  late final CartApi _api;

  @override
  Cart build() {
    _api = ref.read(cartApiProvider);
    // Kick off async load; keep initial empty state until it arrives
    Future(() async => await load());
    return Cart.empty();
  }

  Future<String> _ensureSessionId() async {
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
    final sessionId = await _ensureSessionId();
    final latest = await _api.getCart(sessionId: sessionId);
    state = latest;
    await _persist(latest);
  }

  Future<void> addItem({required int partId, int quantity = 1}) async {
    final sessionId = await _ensureSessionId();
    final updated = await _api.addItem(partId: partId, quantity: quantity, sessionId: sessionId);
    state = updated;
    await _persist(updated);
  }

  Future<void> updateItem({required int itemId, required int quantity}) async {
    final sessionId = await _ensureSessionId();
    final updated = await _api.updateItem(itemId: itemId, quantity: quantity, sessionId: sessionId);
    state = updated;
    await _persist(updated);
  }

  Future<void> removeItem({required int itemId}) async {
    final sessionId = await _ensureSessionId();
    final updated = await _api.removeItem(itemId: itemId, sessionId: sessionId);
    state = updated;
    await _persist(updated);
  }

  Future<Order> checkoutCash({required String shippingAddress, required String phone}) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = await _ensureSessionId();
    final name = AppState.fullName ?? 'Customer';
    final orderApi = OrderApi();
    final order = await orderApi.checkoutCash(
      sessionId: sessionId,
      customerName: name,
      phone: phone,
      address: shippingAddress,
    );
    // Clear cart on successful checkout
    state = Cart.empty();
    await prefs.remove(_kCartJson);
    return order;
  }

  Future<Order> buyNow({required int sparePartId, int quantity = 1, required String shippingAddress, required String phone}) async {
    final sessionId = await _ensureSessionId();
    final name = AppState.fullName ?? 'Customer';
    final orderApi = OrderApi();
    final order = await orderApi.buyNow(
      sessionId: sessionId,
      sparePartId: sparePartId,
      quantity: quantity,
      customerName: name,
      phone: phone,
      address: shippingAddress,
    );
    return order;
  }

  Future<void> _persist(Cart cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCartJson, jsonEncode(cart.toJson()));
  }
}

final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);
