import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/spare_part.dart';
import '../models/spare_part_category.dart';
import '../models/spare_part_brand.dart';
import '../providers/spare_parts_provider.dart';
import 'spare_part_detail_page.dart';
import '../utils/url_utils.dart';

class SparePartsPage extends ConsumerStatefulWidget {
  const SparePartsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SparePartsPage> createState() => _SparePartsPageState();
}

class _SparePartsPageState extends ConsumerState<SparePartsPage> {
  int? _selectedCategoryId;
  int? _selectedBrandId;
  bool _inStockOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = PartsFilter(
      categoryId: _selectedCategoryId,
      brandId: _selectedBrandId,
      inStock: _inStockOnly ? true : null,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );

    final partsAsync = ref.watch(sparePartsByFilterProvider(filter));
    final categoriesAsync = ref.watch(sparePartCategoriesProvider);
    final brandsAsync = ref.watch(sparePartBrandsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Spare Parts')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or SKU',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('In Stock'),
                  selected: _inStockOnly,
                  onSelected: (v) => setState(() => _inStockOnly = v),
                )
              ],
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (cats) => _buildCategoryChips(cats),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load categories: $e'),
            ),
            const SizedBox(height: 8),
            brandsAsync.when(
              data: (brands) => _buildBrandChips(brands),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('Failed to load brands: $e'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: partsAsync.when(
                data: (parts) {
                  if (parts.isEmpty) {
                    return const Center(child: Text('No parts available'));
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: parts.length,
                    itemBuilder: (context, index) {
                      final p = parts[index];
                      return _SparePartCard(item: p);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load parts: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<SparePartCategory> cats) {
    if (cats.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All Categories'),
            selected: _selectedCategoryId == null,
            onSelected: (_) => setState(() => _selectedCategoryId = null),
          ),
          const SizedBox(width: 6),
          for (final c in cats) ...[
            ChoiceChip(
              label: Text(c.name),
              selected: _selectedCategoryId == c.id,
              onSelected: (_) => setState(() => _selectedCategoryId = c.id),
            ),
            const SizedBox(width: 6),
          ]
        ],
      ),
    );
  }

  Widget _buildBrandChips(List<SparePartBrand> brands) {
    if (brands.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All Brands'),
            selected: _selectedBrandId == null,
            onSelected: (_) => setState(() => _selectedBrandId = null),
          ),
          const SizedBox(width: 6),
          for (final b in brands) ...[
            ChoiceChip(
              label: Text(b.name),
              selected: _selectedBrandId == b.id,
              onSelected: (_) => setState(() => _selectedBrandId = b.id),
            ),
            const SizedBox(width: 6),
          ]
        ],
      ),
    );
  }
}

class _SparePartCard extends StatelessWidget {
  final SparePartListItem item;
  const _SparePartCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SparePartDetailPage(item: item)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: item.thumbnail != null && item.thumbnail!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: buildImageUrl(item.thumbnail)!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.error_outline),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.handyman, size: 36)),
                    ),
            ),
            const SizedBox(height: 8),
            Text(item.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${item.currency} ${item.salePrice}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
    );
  }
}
