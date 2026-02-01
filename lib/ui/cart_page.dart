import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../data/app_state.dart';
import 'checkout_page.dart';
import 'widgets/login_required_dialog.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cs = Theme.of(context).colorScheme;
    Future.microtask(() async {
      if (AppState.isAuthenticated) {
        final action = await AppState.takePendingAction();
        if (action != null) {
          final type = action['type'] as String?;
          if (type == 'checkout') {
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CheckoutPage()));
          }
        }
      }
    });
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? cs.surface,
        foregroundColor:
            Theme.of(context).appBarTheme.foregroundColor ?? cs.onSurface,
        title: const Text('Your Cart'),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == cart.items.length) {
                  return _SummaryCard(
                    subtotal: cart.subtotal,
                    tax: cart.tax,
                    shipping: cart.shippingFee,
                    total: cart.total,
                    onCheckout: () async {
                      if (!(AppState.isAuthenticated)) {
                        await AppState.setPendingAction({'type': 'checkout'});
                        if (!context.mounted) return;
                        await showLoginRequiredDialog(context);
                        return;
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CheckoutPage()),
                      );
                    },
                  );
                }
                final item = cart.items[index];
                return _CartItemTile(item: item);
              },
            ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.mrp > item.price) ...[
                      Text(
                        '₹${item.mrp}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '₹${item.price}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease',
                onPressed: item.quantity > 1
                    ? () => ref
                          .read(cartProvider.notifier)
                          .updateItem(
                            itemId: item.id,
                            quantity: item.quantity - 1,
                          )
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: cs.onSurface,
              ),
              Text(
                '${item.quantity}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                tooltip: 'Increase',
                onPressed: () => ref
                    .read(cartProvider.notifier)
                    .updateItem(itemId: item.id, quantity: item.quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: cs.onSurface,
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () =>
                    ref.read(cartProvider.notifier).removeItem(itemId: item.id),
                icon: const Icon(Icons.delete_outline),
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int subtotal;
  final int tax;
  final int shipping;
  final int total;
  final VoidCallback onCheckout;
  const _SummaryCard({
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.onCheckout,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Subtotal', '₹$subtotal', cs),
          const SizedBox(height: 6),
          _row('Tax', '₹$tax', cs),
          const SizedBox(height: 6),
          _row('Shipping', '₹$shipping', cs),
          const Divider(),
          _row('Total', '₹$total', cs, bold: true),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Proceed to Checkout'),
          ),
        ],
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

// Providers to read address/phone from AppState
final addressProvider = Provider<String?>((ref) => AppState.fullAddress);
final phoneProvider = Provider<String?>((ref) => AppState.phoneNumber);
