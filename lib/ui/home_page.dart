import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
// import 'categories_page.dart';
import 'services_page.dart';
import 'subscription_section.dart';
import 'search_page.dart';
// QR scanner removed
import 'spare_parts_page.dart';
import 'spare_parts_section.dart';
import 'service_detail_page.dart';
import '../data/app_state.dart';
import '../providers/category_provider.dart' as providers;
import '../providers/saved_services_provider.dart';
import '../models/service.dart';
import '../utils/url_utils.dart';
// Theme toggle removed

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _showAllCategories = false;
  bool _loadPartsSection = false;

  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  @override
  void initState() {
    super.initState();
    // Defer parts section fetch until after first frame to keep home snappy
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _loadPartsSection = true);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final asyncCategories = ref.watch(categoriesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final horizontalPad = isPhone ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo/repairmybike_newlogo.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return Image.asset(
                            'assets/images/logo/repairmybike_newlogo.jpeg',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (() {
                        final b = AppState.vehicleBrand;
                        final m = AppState.vehicleName;
                        if ((b == null || b.isEmpty) &&
                            (m == null || m.isEmpty)) {
                          return 'Select Vehicle';
                        }
                        if (b == null || b.isEmpty) return m!;
                        if (m == null || m.isEmpty) return b!;
                        return "$b - $m";
                      })(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                const _HeroBanner(),
                const SizedBox(height: 12),
                const _QuickActionsRow(),
                const SizedBox(height: 24),

                // 1) Categories
                Text(
                  'Categories',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: isPhone ? 24 : 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                asyncCategories.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      'Failed to load: ${err.toString()}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return Text(
                        'No categories',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      );
                    }
                    // Responsive grid: 3 high-end tiles on mobile instead of 4
                    final width = MediaQuery.of(context).size.width;
                    int crossAxisCount = 3;
                    if (width >= 600) crossAxisCount = 5;
                    if (width >= 1000) crossAxisCount = 7;
                    if (width >= 1400) crossAxisCount = 9;
                    
                    final visible = _showAllCategories
                        ? categories
                        : categories.take(6).toList(); // Show 6 initially (2 rows)

                    final isPhone = width < 600;
                    final tileRatio = isPhone ? 0.85 : 1.0; 

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: tileRatio,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        return _CategoryCard(category: visible[index]);
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showAllCategories = !_showAllCategories;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showAllCategories ? 'Show Less' : 'Show More',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _showAllCategories
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // 2) Membership (Moved up)
                const SubscriptionSection(),
                
                const SizedBox(height: 32),

                // 3) Feature parts
                if (_loadPartsSection) const SparePartsSection(),

                const SizedBox(height: 32),
                // 4) Your likes
                _LikedServicesSection(),

                const SizedBox(height: 24),

              ],
            ),
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
    const cardColor = Color(0xFF181818);
    
    // Premium Palette Logic
    Color accentFor(Category c) {
      const palette = <Color>[
        Color(0xFF00E5FF), // cyan
        Color(0xFF8A2BE2), // blue violet
        Color(0xFFFFA726), // orange
        Color(0xFF01C9F5), // brand blue
        Color(0xFFEF5350), // red
        Color(0xFF66BB6A), // green
      ];
      final idx = (c.id % palette.length).abs();
      return palette[idx];
    }

    final accentColor = accentFor(category);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardColor, accentColor.withValues(alpha: 0.08)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The "Symbol" Container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _iconForCategory(category),
                    size: w < 90 ? 28 : 34,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Scalable Name
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category.serviceCount} services',
                  style: TextStyle(
                    color: Colors.white38, 
                    fontSize: w < 90 ? 9 : 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForCategory(Category c) {
    final n = c.name.toLowerCase();
    if (n.contains('air') && n.contains('filter')) return Icons.filter_alt;
    if (n.contains('oil') && n.contains('filter')) return Icons.oil_barrel;
    if (n.contains('spark') && n.contains('plug'))
      return Icons.electrical_services;
    if (n.contains('clutch')) return Icons.settings_input_component;
    if (n.contains('suspension') || n.contains('shock')) return Icons.compress;
    if (n.contains('mirror')) return Icons.flip_camera_android;
    if (n.contains('light') || n.contains('lamp') || n.contains('head'))
      return Icons.lightbulb;
    if (n.contains('indicator')) return Icons.priority_high;
    if (n.contains('horn')) return Icons.volume_up;
    if (n.contains('cable')) return Icons.cable;
    if (n.contains('carb') || n.contains('fuel'))
      return Icons.local_gas_station;
    if (n.contains('radiator') || n.contains('cool')) return Icons.ac_unit;
    if (n.contains('exhaust') || n.contains('silencer')) return Icons.cloud;
    if (n.contains('body') || n.contains('paint')) return Icons.color_lens;
    if (n.contains('tyre') || n.contains('tire')) return Icons.circle;
    if (n.contains('brake')) return Icons.stop_circle;
    if (n.contains('drive') || n.contains('gear')) return Icons.settings;
    if (n.contains('battery')) return Icons.battery_full;
    if (n.contains('wash') || n.contains('clean'))
      return Icons.cleaning_services;
    if (n.contains('engine') || n.contains('motor'))
      return Icons.precision_manufacturing;
    if (n.contains('inspect') || n.contains('diagn')) return Icons.search;
    if (n.contains('chain')) return Icons.link;
    return Icons.handyman;
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isPhone = w < 600;
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: w < 360 ? 160 : (isPhone ? 190 : 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.45),
            cs.secondary.withValues(alpha: 0.35),
            const Color(0xFF01C9F5).withValues(alpha: 0.25),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Fast scooter repair, right at home',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Book a service or browse parts — no waiting.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.handyman, size: 56, color: Colors.white70),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      // Scan QR removed
      (
        icon: Icons.search,
        label: 'Search Parts',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => SearchPage()));
        },
      ),
      (
        icon: Icons.construction,
        label: 'View Parts',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => SparePartsPage()));
        },
      ),
      (
        icon: Icons.subscriptions,
        label: 'Subscriptions',
        onTap: () {
          // Scroll intent could be added; for now, open Search as placeholder
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => SearchPage()));
        },
      ),
    ];

    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final it = items[i];
          return OutlinedButton.icon(
            onPressed: it.onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(color: cs.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: Icon(it.icon, size: 18),
            label: Text(it.label),
          );
        },
      ),
    );
  }
}

class _LikedServicesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedIds = ref.watch(savedServicesProvider);
    if (likedIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final asyncAll = ref.watch(providers.allServicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Likes',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        asyncAll.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => const SizedBox.shrink(),
          data: (services) {
            final liked = services
                .where((s) => likedIds.contains(s.id))
                .toList();
            if (liked.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 185,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: liked.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final s = liked[i];
                  return _LikedCard(service: s);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LikedCard extends StatelessWidget {
  final Service service;
  const _LikedCard({required this.service});

  @override
  Widget build(BuildContext context) {
    const card = Color(0xFF1C1C1C);
    const border = Color(0xFF2A2A2A);
    final imageUrl = buildImageUrl(
      service.images.isNotEmpty ? service.images.first : null,
    );
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceDetailPage(service: service),
          ),
        );
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: imageUrl == null
                  ? const Center(
                      child: Icon(Icons.handyman, color: Colors.white54),
                    )
                  : ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        width: double.infinity,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[700]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.handyman, color: Colors.white54),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${service.price}.00',
                    style: const TextStyle(color: Color(0xFF01C9F5)),
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

// Theme toggle widget removed
