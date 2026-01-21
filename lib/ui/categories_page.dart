import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import 'services_page.dart';
import '../utils/url_utils.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final asyncCategories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: const Color(0xFF071A1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(_showAll ? 'View Less' : 'View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: asyncCategories.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text(
                      'Failed to load: ${err.toString()}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Center(
                        child: Text('No categories', style: TextStyle(color: Colors.white70)),
                      );
                    }
                    final visibleCount = _showAll ? categories.length : (categories.length >= 8 ? 8 : categories.length);
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(categoriesProvider);
                        await ref.read(categoriesProvider.future);
                      },
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          // Make tiles taller on phones so content fits
                          childAspectRatio: MediaQuery.of(context).size.width < 600 ? 0.75 : 0.95,
                        ),
                        itemCount: visibleCount,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _CategoryCard(category: category);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF1C1C1C);
    const borderColor = Color(0xFF2A2A2A);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServicesPage(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final iconSize = w < 88 ? 28.0 : 36.0;
        final nameSize = w < 88 ? 12.0 : 14.0;
        final countSize = w < 88 ? 10.0 : 12.0;
        final gap = w < 88 ? 8.0 : 12.0;
        final isAndroid = Theme.of(context).platform == TargetPlatform.android;
        final scale = isAndroid ? 0.95 : 1.0;
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: iconSize,
                width: iconSize,
                child: category.image != null && category.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: buildImageUrl(category.image)!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[700]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          _iconForCategoryIcon(category),
                          size: iconSize,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _iconForCategoryIcon(category),
                        size: iconSize,
                        color: Colors.white,
                      ),
              ),
              SizedBox(height: gap),
              Flexible(
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: nameSize,
                  ),
                  textScaleFactor: scale,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.serviceCount} services',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: countSize,
                ),
                textScaleFactor: scale,
              ),
            ],
          ),
        );
      }),
    );
  }

  IconData _iconForCategoryIcon(Category c) {
    final n = c.name.toLowerCase();
    // Specific mappings for common categories
    if (n.contains('air') && n.contains('filter')) return Icons.filter_alt_rounded;
    if (n.contains('body') || n.contains('paint')) return Icons.format_paint_rounded;
    if (n.contains('brake')) return Icons.stop_circle_outlined;
    if (n.contains('chain') || n.contains('drive')) return Icons.settings_input_component_rounded;
    if (n.contains('tyre') || n.contains('tire')) return Icons.circle_outlined;
    if (n.contains('oil') || n.contains('lube')) return Icons.local_gas_station;
    if (n.contains('battery')) return Icons.battery_full;
    if (n.contains('wash') || n.contains('clean')) return Icons.cleaning_services;
    if (n.contains('elect')) return Icons.electric_bolt;
    if (n.contains('engine') || n.contains('motor')) return Icons.precision_manufacturing;
    if (n.contains('inspect') || n.contains('diagn')) return Icons.search;
    // Fallback
    return Icons.handyman;
  }
}
