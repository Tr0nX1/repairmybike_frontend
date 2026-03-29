import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/secure_api_client.dart';
import 'idempotency_provider.dart';
import '../repositories/profile_repository.dart';
import 'package:dio/dio.dart';

class CheckoutState {
  final bool isSubmitting;
  final String? error;
  final int? selectedAddressId;

  const CheckoutState({
    this.isSubmitting = false,
    this.error,
    this.selectedAddressId,
  });

  CheckoutState copyWith({
    bool? isSubmitting,
    String? error,
    int? selectedAddressId,
    bool clearError = false,
    bool clearAddressId = false,
  }) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      selectedAddressId: clearAddressId ? null : (selectedAddressId ?? this.selectedAddressId),
    );
  }
}

/// The unified orchestrator for all ecommerce and service transactions.
class CheckoutManager extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    // Attempt to automatically select the user's default address on init
    final profileData = ref.watch(profileProvider).value;
    final defaultId = profileData?.defaultAddress?['id'];
    int? parsedId;
    if (defaultId is int) {
      parsedId = defaultId;
    } else if (defaultId != null) {
      parsedId = int.tryParse(defaultId.toString());
    }
    
    return CheckoutState(selectedAddressId: parsedId);
  }

  /// Sets the active address ID. If null, the checkout flow will fallback to
  /// a guest address or the localized structured snapshot.
  void selectAddress(int? addressId) {
    if (addressId == null) {
      state = state.copyWith(clearAddressId: true, clearError: true);
    } else {
      state = state.copyWith(selectedAddressId: addressId, clearError: true);
    }
  }

  Map<String, dynamic> _buildPayload(Map<String, dynamic> baseData) {
    final payload = Map<String, dynamic>.from(baseData);
    
    // 1. Inject Idempotency Key
    payload['idempotency_key'] = ref.read(idempotencyKeyProvider);
    
    // 2. Inject Address Pointer
    if (state.selectedAddressId != null) {
      payload['user_address_id'] = state.selectedAddressId;
    }
    
    return payload;
  }

  String _extractErrorMessage(dynamic errorData) {
    if (errorData is Map) {
      if (errorData['message'] is String) return errorData['message'];
      if (errorData['error'] is String) return errorData['error'];
    }
    if (errorData is String && errorData.isNotEmpty) return errorData;
    return 'Transaction failed. Please try again.';
  }

  /// Orchestrates a Service Booking transaction.
  Future<Map<String, dynamic>> submitServiceBooking({
    required Map<String, dynamic> bookingData,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final dio = ref.read(secureApiClientProvider);
      final payload = _buildPayload(bookingData);

      final res = await dio.post('api/bookings/', data: payload);
      
      // ROTATE IDEMPOTENCY KEY ON SUCCESS
      ref.read(idempotencyKeyProvider.notifier).refreshKey();
      
      state = state.copyWith(isSubmitting: false);
      return res.data;
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e.response?.data);
      state = state.copyWith(isSubmitting: false, error: msg);
      throw Exception(msg);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      throw Exception(e.toString());
    }
  }

  /// Orchestrates a Spare Parts Cart checkout transaction.
  Future<Map<String, dynamic>> submitPartsCheckout({
    required Map<String, dynamic> cartData,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final dio = ref.read(secureApiClientProvider);
      final payload = _buildPayload(cartData);

      final res = await dio.post('api/spare-parts/cart/checkout/', data: payload);
      
      // ROTATE IDEMPOTENCY KEY ON SUCCESS
      ref.read(idempotencyKeyProvider.notifier).refreshKey();
      
      state = state.copyWith(isSubmitting: false);
      return res.data;
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e.response?.data);
      state = state.copyWith(isSubmitting: false, error: msg);
      throw Exception(msg);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      throw Exception(e.toString());
    }
  }
}

final checkoutManagerProvider = NotifierProvider<CheckoutManager, CheckoutState>(CheckoutManager.new);
