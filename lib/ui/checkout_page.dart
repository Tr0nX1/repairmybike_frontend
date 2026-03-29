import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../models/postal_address.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/providers/checkout_manager.dart';
import 'widgets/address_form_fields.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});
  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _flatCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _landmarkCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _cityCtrl;
  String? _selectedState;
  String _shippingMethod = 'standard';

  bool _initializedProfile = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _flatCtrl = TextEditingController();
    _areaCtrl = TextEditingController();
    _landmarkCtrl = TextEditingController();
    _pincodeCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ROOT CAUSE FIX 2: profileProvider.build() starts as null.
      // It only has data if fetchProfile() was explicitly called elsewhere.
      // If profile is null, trigger the fetch now so auto-fill works.
      final currentProfile = ref.read(profileProvider).value;
      if (currentProfile == null) {
        ref.read(profileProvider.notifier).fetchProfile();
      } else {
        _syncWithProfile();
      }
    });
  }

  void _syncWithProfile() {
    if (_initializedProfile) return;
    
    final authData = ref.read(authProvider);
    final profileData = ref.read(profileProvider).value;

    if (authData.phoneNumber != null) {
      _phoneCtrl.text = authData.phoneNumber ?? '';
    }
    if (profileData != null) {
      _nameCtrl.text = profileData.fullName;
      final defaultAddr = profileData.defaultAddress;
      if (defaultAddr != null) {
         final addrIdInfo = defaultAddr['id'];
         int? parsedId;
         if (addrIdInfo is int) {
           parsedId = addrIdInfo;
         } else if (addrIdInfo != null) {
           parsedId = int.tryParse(addrIdInfo.toString());
         }
         if (parsedId != null) {
           _onAddressPicked(parsedId);
         }
      }
    }
    
    // Only lock initialization if the heavy profile data is actually loaded and not null
    if (profileData != null) {
      _initializedProfile = true;
    }
  }

  void _onAddressPicked(int? addressId) {
     ref.read(checkoutManagerProvider.notifier).selectAddress(addressId);
     if (addressId != null) {
        final profile = ref.read(profileProvider).value;
        final addr = profile?.addresses.firstWhere((a) => a['id'] == addressId, orElse: () => {});
        if (addr != null && addr.isNotEmpty) {
           _nameCtrl.text = addr['full_name'] ?? profile?.fullName ?? '';
           _phoneCtrl.text = addr['phone_number'] ?? ref.read(authProvider).phoneNumber ?? '';
           _flatCtrl.text = addr['flat_house_no'] ?? '';
           _areaCtrl.text = addr['area_street'] ?? '';
           _landmarkCtrl.text = addr['landmark'] ?? '';
           _cityCtrl.text = addr['town_city'] ?? '';
           _pincodeCtrl.text = addr['pincode'] ?? '';
           setState(() {
              _selectedState = addr['state'];
           });
        }
     } else {
       _flatCtrl.clear();
       _areaCtrl.clear();
       _landmarkCtrl.clear();
       _cityCtrl.clear();
       _pincodeCtrl.clear();
       setState(() { _selectedState = null; });
     }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _flatCtrl.dispose();
    _areaCtrl.dispose();
    _landmarkCtrl.dispose();
    _pincodeCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (!isAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place orders')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    try {
      // ROOT CAUSE FIX 1: session_id is REQUIRED by CheckoutSerializer on the
      // backend. Without it, the backend returns a 400 validation error which
      // the generic error handler reports as "Transaction failed".
      final sessionId = await ref.read(cartProvider.notifier).getSessionId();

      final address = PostalAddress(
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        flatHouseNo: _flatCtrl.text.trim(),
        areaStreet: _areaCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        townCity: _cityCtrl.text.trim(),
        state: _selectedState ?? '',
      );

      final payload = {
        'session_id': sessionId,            // ← THE CRITICAL MISSING FIELD
        'customer_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': address.toFullString(),
        'shipping_method': _shippingMethod,
        'address_details': address.toJson(),
      };

      await ref.read(checkoutManagerProvider.notifier).submitPartsCheckout(cartData: payload);

      // Successfully bought; purge the cart explicitly
      ref.invalidate(cartProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
      
      context.go('/bookings');
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Continuously listen if profile info resolves lately and we haven't synced yet
    ref.listen(profileProvider, (previous, next) {
      if (!_initializedProfile && next.value != null) {
        _syncWithProfile();
      }
    });

    final cart = ref.watch(cartProvider);
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _buildForm(cs);
          final summary = _OrderSummary(
            items: cart.items,
            subtotal: cart.subtotal,
            tax: cart.tax,
            shipping: cart.shippingFee,
            total: cart.total,
          );
          
          if (wide) {
             return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: form),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: summary),
                  ],
                ),
             );
          } else {
             return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    form, 
                    const SizedBox(height: 16), 
                    summary,
                    const SizedBox(height: 20),
                  ],
                ),
             );
          }
        },
      ),
    );
  }

  Widget _buildForm(ColorScheme cs) {
    final checkoutState = ref.watch(checkoutManagerProvider);
    final profileData = ref.watch(profileProvider).value;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipping Information',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              AddressFormFields(
                nameCtrl: _nameCtrl,
                phoneCtrl: _phoneCtrl,
                flatCtrl: _flatCtrl,
                areaCtrl: _areaCtrl,
                landmarkCtrl: _landmarkCtrl,
                pincodeCtrl: _pincodeCtrl,
                cityCtrl: _cityCtrl,
                selectedState: _selectedState,
                onStateChanged: (v) => setState(() => _selectedState = v),
                savedAddresses: profileData?.addresses,
                selectedAddressId: checkoutState.selectedAddressId,
                onAddressSelected: _onAddressPicked,
              ),
              const SizedBox(height: 16),
              Text(
                'Shipping Method',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              RadioListTile<String>(
                  value: 'standard',
                  // ignore: deprecated_member_use
                  groupValue: _shippingMethod,
                  title: const Text('Standard Delivery (3–5 days)'),
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _shippingMethod = v!),
              ),
              RadioListTile<String>(
                  value: 'express',
                  // ignore: deprecated_member_use
                  groupValue: _shippingMethod,
                  title: const Text('Express Delivery (1–2 days)'),
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _shippingMethod = v!),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const ListTile(
                leading: Icon(Icons.payments),
                title: Text('Cash on Delivery'),
                subtitle: Text('Pay in cash upon delivery'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   const Icon(Icons.lock, color: Colors.green),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'Secure checkout • Encrypted data • Idempotent checks active',
                       style: TextStyle(color: cs.onSurfaceVariant),
                     ),
                   ),
                ],
              ),
              if (checkoutState.error != null) ...[
                const SizedBox(height: 8),
                Text(checkoutState.error!, style: TextStyle(color: cs.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: checkoutState.isSubmitting ? null : _placeOrder,
                  child: checkoutState.isSubmitting 
                     ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator()) 
                     : const Text('Place Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final List<CartItem> items;
  final int subtotal;
  final int tax;
  final int shipping;
  final int total;
  const _OrderSummary({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((e) => _OrderItemTile(item: e)),
            const Divider(),
            _row('Subtotal', '₹$subtotal', cs),
            const SizedBox(height: 6),
            _row('Tax', '₹$tax', cs),
            const SizedBox(height: 6),
            _row('Shipping', '₹$shipping', cs),
            const Divider(),
            _row('Total', '₹$total', cs, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, ColorScheme cs, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(k, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        Text(
          v,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final CartItem item;
  const _OrderItemTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[700]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.build,
                        size: 24,
                        color: Colors.white24,
                      ),
                    )
                  : const Icon(Icons.image, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price} × ${item.quantity}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.price * item.quantity}',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
