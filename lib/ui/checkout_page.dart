import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../data/app_state.dart';
import 'booking_list_page.dart';
import 'main_shell.dart';

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
  bool _submitting = false;
  String? _error;

  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Chandigarh', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: AppState.fullName ?? '');
    _phoneCtrl = TextEditingController(
      text: AppState.phoneNumber ?? AppState.lastCustomerPhone ?? '',
    );
    _flatCtrl = TextEditingController(text: AppState.addrFlat ?? '');
    _areaCtrl = TextEditingController(text: AppState.addrArea ?? '');
    _landmarkCtrl = TextEditingController(text: AppState.addrLandmark ?? '');
    _pincodeCtrl = TextEditingController(text: AppState.addrPincode ?? '');
    _cityCtrl = TextEditingController(text: AppState.addrCity ?? '');
    _selectedState = AppState.addrState;
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
    if (!AppState.isAuthenticated) {
      // Require login before placing orders
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to place orders')),
        );
      }
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final phone = _phoneCtrl.text.trim();
      final flat = _flatCtrl.text.trim();
      final area = _areaCtrl.text.trim();
      final landmark = _landmarkCtrl.text.trim();
      final pincode = _pincodeCtrl.text.trim();
      final city = _cityCtrl.text.trim();
      final state = _selectedState;
      
      await AppState.setLastCustomerPhone(phone);
      await AppState.setProfile(
        name: _nameCtrl.text.trim(),
        mail: AppState.email,
        f: flat,
        a: area,
        l: landmark,
        p: pincode,
        c: city,
        s: state,
      );
      // Build full address for order
      final fullAddress = [flat, area, landmark, city, state ?? '', pincode]
          .where((e) => e.isNotEmpty)
          .join(', ');
      
      await ref
          .read(cartProvider.notifier)
          .checkoutCash(shippingAddress: fullAddress, phone: phone);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order placed')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BookingListPage()));
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _submitting = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    // Add extra padding at bottom to avoid FAB overlap etc if any
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
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) {
                  final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  return s.length < 10 ? 'Enter a valid phone' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _flatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Flat, House no., Building, Company, Apartment',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Area, Street, Sector, Village',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _landmarkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Landmark (optional)',
                  hintText: 'E.g. near apollo hospital',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pincode'),
                      validator: (v) {
                        final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        return s.length < 6 ? 'Enter valid pincode' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'Town/City'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(labelText: 'State'),
                items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedState = v),
                validator: (v) => v == null ? 'Select state' : null,
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
                groupValue: _shippingMethod,
                onChanged: (v) => setState(() => _shippingMethod = v!),
                title: const Text('Standard Delivery (3–5 days)'),
              ),
              RadioListTile<String>(
                value: 'express',
                groupValue: _shippingMethod,
                onChanged: (v) => setState(() => _shippingMethod = v!),
                title: const Text('Express Delivery (1–2 days)'),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.payments),
                title: const Text('Cash on Delivery'),
                subtitle: const Text('Pay in cash upon delivery'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure checkout • Encrypted data • Trusted delivery',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: cs.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _placeOrder,
                  child: const Text('Place Order'),
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Satisfaction guaranteed',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
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
              color: cs.surfaceVariant,
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
