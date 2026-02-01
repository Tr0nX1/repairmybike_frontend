import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/category_provider.dart';
import '../../models/service.dart';
import '../service_detail_page.dart';
import '../../utils/url_utils.dart';
import '../../providers/saved_services_provider.dart';
import '../../providers/saved_parts_provider.dart';
import '../spare_parts_section.dart';
import '../spare_part_detail_page.dart';
import '../../models/spare_part.dart';
import '../../providers/cart_provider.dart';

class LandingServicesSection extends ConsumerWidget {
  const LandingServicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncServices = ref.watch(allServicesProvider);
    final width = MediaQuery.of(context).size.width;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to services page or categories
                  },
                  child: const Text('View All', style: TextStyle(color: Color(0xFF01C9F5))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            asyncServices.when(
              loading: () => const _LoadingGrid(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
              data: (services) {
                // Prioritize featured items, but fill up to 4 with non-featured if needed
                final featured = services.where((s) => s.isFeatured).toList();
                final nonFeatured = services.where((s) => !s.isFeatured).toList();
                
                final displayItems = (featured + nonFeatured).take(4).toList();
                
                if (displayItems.isEmpty) {
                  return const Text('No services available', style: TextStyle(color: Colors.white60));
                }
                
                int crossAxisCount = width < 600 ? 2 : (width < 1100 ? 3 : 4);
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: displayItems.length,
                  itemBuilder: (context, i) => _ServiceLandingCard(service: displayItems[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LandingSparePartsSection extends ConsumerWidget {
  const LandingSparePartsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncParts = ref.watch(sparePartsProvider);
    final width = MediaQuery.of(context).size.width;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trending Products',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to spare parts page
                  },
                  child: const Text('View All', style: TextStyle(color: Color(0xFF01C9F5))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            asyncParts.when(
              loading: () => const _LoadingGrid(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
              data: (parts) {
                final displayItems = parts.take(4).toList();
                if (displayItems.isEmpty) {
                  return const Text('No products available', style: TextStyle(color: Colors.white60));
                }
                
                int crossAxisCount = width < 600 ? 2 : (width < 1100 ? 3 : 4);
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: displayItems.length,
                  itemBuilder: (context, i) => _PartLandingCard(part: displayItems[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceLandingCard extends ConsumerWidget {
  final Service service;
  const _ServiceLandingCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const cardColor = Color(0xFF1C1C1C);
    const accent = Color(0xFF01C9F5);
    final imageUrl = buildImageUrl(service.images.isNotEmpty ? service.images.first : null);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceDetailPage(service: service)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl != null 
                      ? CachedNetworkImage(
                          imageUrl: imageUrl, 
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[800]!,
                            highlightColor: Colors.grey[700]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, e) => const Icon(Icons.handyman, color: Colors.white10, size: 40),
                        )
                      : const Center(child: Icon(Icons.handyman, color: Colors.white10, size: 40)),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => ref.read(savedServicesProvider.notifier).toggle(service.id),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                        child: Icon(
                          ref.watch(savedServicesProvider).contains(service.id) ? Icons.favorite : Icons.favorite_border,
                          color: ref.watch(savedServicesProvider).contains(service.id) ? Colors.redAccent : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${service.price}',
                        style: const TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            service.rating,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartLandingCard extends ConsumerWidget {
  final SparePartListItem part;
  const _PartLandingCard({required this.part});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const cardColor = Color(0xFF1C1C1C);
    const accent = Color(0xFF01C9F5);
    final imageUrl = buildImageUrl(part.thumbnail);
    final hasDiscount = part.salePrice > 0 && part.salePrice < part.mrp;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SparePartDetailPage(item: part)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl != null 
                      ? CachedNetworkImage(
                          imageUrl: imageUrl, 
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[800]!,
                            highlightColor: Colors.grey[700]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, e) => const Icon(Icons.build, color: Colors.white10, size: 40),
                        )
                      : const Center(child: Icon(Icons.build, color: Colors.white10, size: 40)),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => ref.read(savedPartsProvider.notifier).toggle(part.id),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                        child: Icon(
                          ref.watch(savedPartsProvider).contains(part.id) ? Icons.favorite : Icons.favorite_border,
                          color: ref.watch(savedPartsProvider).contains(part.id) ? Colors.redAccent : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${hasDiscount ? part.salePrice : part.mrp}',
                        style: const TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      if (hasDiscount)
                        Text(
                          '₹${part.mrp}',
                          style: const TextStyle(color: Colors.white24, decoration: TextDecoration.lineThrough, fontSize: 10),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await ref.read(cartProvider.notifier).addItem(partId: part.id, quantity: 1);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to Cart'), behavior: SnackBarBehavior.floating),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent.withValues(alpha: 0.1),
                        foregroundColor: accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
