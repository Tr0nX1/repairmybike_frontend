import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../data/spare_parts_api.dart';
import '../models/spare_part.dart';
import '../providers/saved_parts_provider.dart';
import 'spare_parts_page.dart';
import 'spare_part_detail_page.dart';
import '../utils/url_utils.dart';
import '../providers/cart_provider.dart';

final sparePartsProvider = FutureProvider.autoDispose<List<SparePartListItem>>((ref) async {
  final api = SparePartsApi();
  return api.getParts();
});

class SparePartsSection extends ConsumerWidget {
  const SparePartsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncParts = ref.watch(sparePartsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Parts',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: isPhone ? 20 : 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        asyncParts.when(
          loading: () => const _SparePartsGridSkeleton(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Failed to load parts: ${e.toString()}', 
              style: const TextStyle(color: Colors.redAccent)),
          ),
          data: (parts) {
            if (parts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No parts available for your vehicle', 
                  style: TextStyle(color: Colors.white70)),
              );
            }
            // Limit to 4 items as requested
            final show = parts.take(4).toList();
            
            final width = MediaQuery.of(context).size.width;
            int crossAxisCount = 2; // Fixed 2x2 for mobile/Android
            if (width >= 600) crossAxisCount = 4;
            
            final isPhone = width < 600;
            // Industry Standard: 0.62 - 0.65 is the "Sweet Spot" for 2-column e-commerce cards.
            final tileRatio = isPhone ? 0.64 : 0.85;

            return Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: tileRatio,
                  ),
                  itemCount: show.length,
                  itemBuilder: (context, i) => _PartCard(part: show[i]),
                ),
                if (parts.length > 4) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 48,
                      child: OutlinedButton(
                         style: OutlinedButton.styleFrom(
                           foregroundColor: cs.primary,
                           side: BorderSide(color: cs.primary.withOpacity(0.5), width: 1.5),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                         ),
                         onPressed: () {
                           Navigator.of(context).push(
                             MaterialPageRoute(builder: (_) => const SparePartsPage()),
                           );
                         },
                         child: const Text('View More', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ]
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PartCard extends ConsumerWidget {
  final SparePartListItem part;
  const _PartCard({required this.part});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final symbol = part.currency.toUpperCase() == 'INR' ? '₹' : part.currency;
    
    final bool hasDiscount = part.salePrice > 0 && part.salePrice < part.mrp;
    final double discountPercent = hasDiscount 
        ? ((part.mrp - part.salePrice) / part.mrp * 100) 
        : 0;

    const cardColor = Color(0xFF181818);
    final accentColor = cs.primary.withAlpha(20);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SparePartDetailPage(item: part)),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          
          return Opacity(
            opacity: part.inStock ? 1.0 : 0.65,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.primary.withOpacity(0.25), width: 1.2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cardColor, accentColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Image with consistent aspect ratio
                  AspectRatio(
                    aspectRatio: 1.4, // Shorter image height to yield space to info
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: part.thumbnail != null && part.thumbnail!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: buildImageUrl(part.thumbnail)!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[800]!,
                                    highlightColor: Colors.grey[700]!,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.black38,
                                    child: Center(child: Icon(Icons.build, size: w * 0.25, color: Colors.white10)),
                                  ),
                                )
                              : Container(
                                  color: Colors.black38,
                                  child: Center(
                                    child: Icon(Icons.build, size: w * 0.25, color: Colors.white10),
                                  ),
                                ),
                        ),
                        // Premium Discount Badge
                        if (hasDiscount)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${discountPercent.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 9, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        // Favorite/Save Icon
                        Positioned(
                          right: 8, top: 8,
                          child: Consumer(
                            builder: (context, ref, _) {
                              final saved = ref.watch(savedPartsProvider).contains(part.id);
                              return InkWell(
                                onTap: () => ref.read(savedPartsProvider.notifier).toggle(part.id),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    saved ? Icons.favorite : Icons.favorite_border,
                                    color: saved ? Colors.redAccent : Colors.white,
                                    size: 14,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!part.inStock)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white54, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 2. Information Region (Flexible)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Brand
                          Text(
                            part.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              height: 1.25,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            part.brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white38, 
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Price & CTA Row (The "Money" area)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$symbol${hasDiscount ? part.salePrice : part.mrp}',
                                        style: TextStyle(
                                          color: cs.primary, 
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ),
                                    if (hasDiscount)
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '$symbol${part.mrp}',
                                          style: const TextStyle(
                                            color: Colors.white10,
                                            decoration: TextDecoration.lineThrough,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                               ),
                               const SizedBox(width: 8),
                              if (part.inStock)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      try {
                                        await ref.read(cartProvider.notifier).addItem(partId: part.id, quantity: 1);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Added to Cart'), behavior: SnackBarBehavior.floating),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: cs.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: cs.primary.withOpacity(0.2)),
                                      ),
                                      child: Icon(Icons.add_shopping_cart_rounded, size: 18, color: cs.primary),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class _SparePartsGridSkeleton extends StatelessWidget {
  const _SparePartsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 4;
    if (width >= 600) crossAxisCount = 6;
    if (width >= 1000) crossAxisCount = 8;
    if (width >= 1400) crossAxisCount = 10;
    
    final isPhone = width < 600;
    final tileRatio = isPhone ? 0.62 : 0.85;

    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: tileRatio,
        ),
        itemCount: crossAxisCount,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

