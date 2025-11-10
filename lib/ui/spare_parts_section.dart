import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/spare_parts_api.dart';
import '../models/spare_part.dart';
import 'spare_parts_page.dart';
import 'spare_part_detail_page.dart';
import '../utils/url_utils.dart';

final sparePartsProvider = FutureProvider.autoDispose<List<SparePartListItem>>((ref) async {
  final api = SparePartsApi();
  // Show a small curated set on home; fetch first page in stock
  return api.getParts();
});

class SparePartsSection extends ConsumerWidget {
  const SparePartsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncParts = ref.watch(sparePartsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Featured Parts',
                style: TextStyle(
                  color: cs.onBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SparePartsPage()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: asyncParts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Failed to load parts: ${e.toString()}', style: const TextStyle(color: Colors.redAccent)),
            ),
            data: (parts) {
              if (parts.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('No parts available', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text('Tip: Ensure backend has parts; filters removed for visibility.',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                );
              }
              final show = parts.take(10).toList();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: show.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: 220,
                  child: _PartCard(part: show[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PartCard extends StatelessWidget {
  final SparePartListItem part;
  const _PartCard({required this.part});

  // Colors are driven by Theme.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final symbol = part.currency.toUpperCase() == 'INR' ? '₹' : part.currency;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SparePartDetailPage(item: part)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay badges
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: part.thumbnail != null && part.thumbnail!.isNotEmpty
                        ? Image.network(
                            buildImageUrl(part.thumbnail)!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: cs.surface,
                              child: const Center(child: Icon(Icons.image_not_supported)),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: cs.surface,
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                          )
                        : Container(
                            color: cs.surface,
                            child: const Center(
                              child: Icon(Icons.build, size: 28),
                            ),
                          ),
                  ),
                  // Gradient fade for text legibility
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Price badge
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$symbol ${part.salePrice > 0 ? part.salePrice : part.mrp}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  // Rating chip
                  if (part.ratingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${part.ratingAverage.toStringAsFixed(1)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          part.brandName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        part.inStock ? Icons.check_circle : Icons.remove_circle,
                        color: part.inStock ? Colors.greenAccent : Colors.redAccent,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Future: integrate add-to-cart
                      },
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: const Text('Add'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.onSurface,
                        side: BorderSide(color: theme.dividerColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}