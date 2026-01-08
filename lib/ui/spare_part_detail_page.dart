import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/spare_part.dart';
import '../utils/url_utils.dart';
import 'widgets/rm_app_bar.dart';
import '../utils/api_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../data/app_state.dart';
import 'widgets/customer_details_sheet.dart';
import 'widgets/login_required_dialog.dart';
import 'cart_page.dart';

class SparePartDetailPage extends StatelessWidget {
  final SparePartListItem item;
  const SparePartDetailPage({super.key, required this.item});

  String get priceLabel => '${item.currency == 'INR' ? '₹' : item.currency} ${item.salePrice > 0 ? item.salePrice : item.mrp}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final images = <String>[];
    if ((item.thumbnail ?? '').isNotEmpty) {
      images.add(buildImageUrl(item.thumbnail!)!);
    }
    for (final img in item.images) {
      final u = buildImageUrl(img);
      if (u != null) images.add(u);
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: RMAppBar(title: item.name, actions: [
        IconButton(
          tooltip: 'Share',
          onPressed: () {
            final details = '${item.name} • ${item.brandName} • SKU ${item.sku}';
            Clipboard.setData(ClipboardData(text: details));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied details')));
          },
          icon: const Icon(Icons.share),
        )
      ]),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Gallery(images: images),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: SelectableText(
                      item.categoryName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    item.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    item.brandName,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.85), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    'SKU: ${item.sku}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 8),
                  _RatingStars(avg: item.ratingAverage, count: item.ratingCount),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          '${item.currency} ${item.salePrice}',
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.2),
                        ),
                        if (item.mrp > item.salePrice)
                          Text(
                            '${item.currency} ${item.mrp}',
                            style: TextStyle(decoration: TextDecoration.lineThrough, color: cs.onSurfaceVariant),
                          ),
                        _StockBadge(inStock: item.inStock, qty: item.stockQty),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    item.shortDescription.isNotEmpty ? item.shortDescription : 'No description',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(height: 16),
                  _SpecsGrid(items: {
                    'Brand': item.brandName,
                    'SKU': item.sku,
                    'Category': item.categoryName,
                    ...item.specs.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
                    'Warranty': item.warrantyMonthsTotal > 0 ? '${item.warrantyMonthsTotal} months' : '—',
                    'Free service': item.warrantyFreeMonths > 0 ? '${item.warrantyFreeMonths} months' : '—',
                    'Pro-rata': item.warrantyProRataMonths > 0 ? '${item.warrantyProRataMonths} months' : '—',
                  }),
                  const SizedBox(height: 16),
                  _FitmentCard(item: item),
                  const SizedBox(height: 16),
                  _CartActions(partId: item.id),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartActions extends ConsumerWidget {
  final int partId;
  const _CartActions({required this.partId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    Future.microtask(() async {
      if (AppState.isAuthenticated) {
        final action = await AppState.takePendingAction();
        if (action != null) {
          final type = action['type'] as String?;
          final partId = action['partId'] as int?;
          final qty = (action['qty'] as int?) ?? 1;
          if (type == 'add_to_cart' && partId != null) {
            try {
              await ref.read(cartProvider.notifier).addItem(partId: partId, quantity: qty);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
              }
            } catch (_) {}
          } else if (type == 'buy_now' && partId != null) {
            try {
              String phone = AppState.phoneNumber ?? '';
              String address = AppState.address ?? '';
              final hasAll = (AppState.fullName?.isNotEmpty ?? false) && (phone.isNotEmpty) && (address.isNotEmpty);
              if (!hasAll) {
                final res = await showCustomerDetailsSheet(context);
                if (res == null) return;
                phone = res.phone;
                address = res.address;
              }
              await ref.read(cartProvider.notifier).buyNow(sparePartId: partId, quantity: qty, shippingAddress: address, phone: phone);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order confirmed')));
              }
            } catch (_) {}
          }
        }
      }
    });
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            try {
              // Guest CAN add to cart without login
              await ref
                  .read(cartProvider.notifier)
                  .addItem(partId: partId, quantity: 1);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to cart')),
              );
              _showAddAnimation(context);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Add to cart failed: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Add to Cart'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () async {
            try {
              if (!(AppState.isAuthenticated)) {
                await AppState.setPendingAction({
                  'type': 'buy_now',
                  'partId': partId,
                  'qty': 1,
                });
                await showLoginRequiredDialog(context);
                return;
              }
              await ref
                  .read(cartProvider.notifier)
                  .addItem(partId: partId, quantity: 1);
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Purchase failed: $e')),
                );
              }
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary),
          ),
          child: const Text('Buy Now'),
        )
      ],
    );
  }

  void _showAddAnimation(BuildContext context) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                onEnd: () => entry.remove(),
                builder: (context, v, child) {
                  return Opacity(
                    opacity: 1.0 - (v * 0.8),
                    child: Transform.scale(
                      scale: 0.8 + v * 0.4,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_shopping_cart, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
  }
}

class _RatingStars extends StatelessWidget {
  final num avg; final int count;
  const _RatingStars({required this.avg, required this.count});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stars = List.generate(5, (i) => Icon(i + 1 <= avg.round() ? Icons.star : Icons.star_border, color: cs.secondary));
    return Row(children: [
      ...stars,
      const SizedBox(width: 8),
      Text('(${count})', style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 12)),
    ]);
  }
}

class _Gallery extends StatefulWidget {
  final List<String> images;
  const _Gallery({required this.images});
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImages = widget.images.isNotEmpty;
    String? _resolve(String src) {
      final b = buildImageUrl(src);
      if (b != null) return b;
      if (src.isEmpty) return null;
      final s = src.trim();
      if (s.startsWith('http://') || s.startsWith('https://') || s.startsWith('data:')) return s;
      return '${resolveBackendBase()}/${s.startsWith('/') ? s.substring(1) : s}';
    }
    return Column(children: [
      AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: hasImages
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => _openFullscreen(_resolve(widget.images[index]) ?? ''),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: InteractiveViewer(
                            key: ValueKey(index),
                            child: Image(
                              image: NetworkImage(_resolve(widget.images[index]) ?? ''),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: cs.surfaceVariant,
                                child: const Center(child: Icon(Icons.image_not_supported)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.zoom_in, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  color: cs.surfaceVariant,
                  child: const Center(child: Icon(Icons.handyman, size: 42)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.images.isNotEmpty ? widget.images.length : 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final thumbUrl = hasImages ? (_resolve(widget.images[i]) ?? '') : '';
            final selected = i == index;
            return InkWell(
              onTap: () => setState(() => index = i),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: selected ? 1.05 : 1.0,
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? cs.primary : cs.outline),
                  ),
                  child: hasImages
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: NetworkImage(thumbUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
                          ),
                        )
                      : const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  void _openFullscreen(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: Center(
            child: InteractiveViewer(
              child: Image(
                image: NetworkImage(url),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool inStock; final int qty;
  const _StockBadge({required this.inStock, required this.qty});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = inStock ? Colors.green : Colors.red;
    final label = inStock ? 'In Stock • $qty' : 'Out of Stock';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: inStock ? cs.onTertiary : cs.onError)),
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  final Map<String, String> items;
  const _SpecsGrid({required this.items});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = items.entries.where((e) => (e.value).isNotEmpty && e.value != '—').toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outline)),
          child: Row(children: [
            Expanded(child: SelectableText(e.key, style: TextStyle(color: cs.onSurfaceVariant))),
            const SizedBox(width: 8),
            Expanded(child: SelectableText(e.value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600))),
          ]),
        );
      },
    );
  }
}

class _FitmentCard extends StatelessWidget {
  final SparePartListItem item;
  const _FitmentCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Compatibility', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _row('Brand', item.brandName, cs),
        _row('Type', item.categoryName, cs),
        _row('Model', '—', cs),
        _row('Notes', 'Installation by certified mechanic recommended.', cs),
      ]),
    );
  }
  Widget _row(String k, String v, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: SelectableText(k, style: TextStyle(color: cs.onSurfaceVariant))),
        Expanded(child: SelectableText(v, style: TextStyle(color: cs.onSurface))),
      ]),
    );
  }
}
