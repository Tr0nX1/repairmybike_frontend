import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
// import 'categories_page.dart';
import 'services_page.dart';
import 'subscription_section.dart';
import 'search_page.dart';
import 'qr_scanner_page.dart';
import 'spare_parts_page.dart';
import 'spare_parts_section.dart';
import 'service_detail_page.dart';
import '../data/app_state.dart';
import '../providers/category_provider.dart' as providers;
import '../models/service.dart';
import '../utils/url_utils.dart';

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
              const _HeroBanner(),
              const SizedBox(height: 12),
              const _QuickActionsRow(),
              const SizedBox(height: 24),
              _LikedServicesSection(),
              const SizedBox(height: 24),
              Text(
                'Explore Services',
                style: TextStyle(color: Colors.white, fontSize: isPhone ? 24 : 28, fontWeight: FontWeight.w800),
              ),
            const SizedBox(height: 8),
            const Text(
              'Professional Scooter repair at your doorstep',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 20),
            Text(
              'Categories',
              style: TextStyle(color: Colors.white, fontSize: isPhone ? 20 : 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            asyncCategories.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Text('Failed to load: ${err.toString()}',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text('No categories', style: TextStyle(color: Colors.white70));
                }
                // Force 4 columns grid per requirement
                const crossAxisCount = 4;
                final visible = _showAllCategories
                    ? categories
                    : categories.take(8).toList();
                // Make tiles taller on phones to avoid vertical overflow
                final isPhone = MediaQuery.of(context).size.width < 600;
                final tileRatio = isPhone ? 0.75 : 0.95; // width/height
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: tileRatio,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final category = visible[index];
                    return _CategoryCard(category: category);
                  },
                );
              },
            ),

            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: const BorderSide(color: accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAllCategories = !_showAllCategories;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_showAllCategories ? 'Show Less' : 'Show More',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Icon(_showAllCategories ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const SubscriptionSection(),

            const SizedBox(height: 24),
            if (_loadPartsSection) const SparePartsSection(),
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
    const cardColor = Color(0xFF1C1C1C);
    const borderColor = Color(0xFF2A2A2A);
    // Derive a pleasant accent color per category for subtle colorization
    Color accentFor(Category c) {
      const palette = <Color>[
        Color(0xFF00E5FF), // cyan
        Color(0xFF8A2BE2), // blue violet
        Color(0xFFFFA726), // orange
        Color(0xFF66BB6A), // green
        Color(0xFFEF5350), // red
        Color(0xFF42A5F5), // blue
      ];
      final idx = (c.id % palette.length).abs();
      return palette[idx];
    }

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
        final scale = isAndroid ? 0.95 : 1.0; // slightly reduce text on Android to fit
        final accentColor = accentFor(category);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.55)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor,
                accentColor.withOpacity(0.20),
              ],
            ),
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
              Icon(_iconForCategory(category), size: iconSize, color: accentColor),
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

  IconData _iconForCategory(Category c) {
    final n = c.name.toLowerCase();
    if (n.contains('air') && n.contains('filter')) return Icons.filter_alt;
    if (n.contains('oil') && n.contains('filter')) return Icons.oil_barrel;
    if (n.contains('spark') && n.contains('plug')) return Icons.electrical_services;
    if (n.contains('clutch')) return Icons.settings_input_component;
    if (n.contains('suspension') || n.contains('shock')) return Icons.compress;
    if (n.contains('mirror')) return Icons.flip_camera_android;
    if (n.contains('light') || n.contains('lamp') || n.contains('head')) return Icons.lightbulb;
    if (n.contains('indicator')) return Icons.priority_high;
    if (n.contains('horn')) return Icons.volume_up;
    if (n.contains('cable')) return Icons.cable;
    if (n.contains('carb') || n.contains('fuel')) return Icons.local_gas_station;
    if (n.contains('radiator') || n.contains('cool')) return Icons.ac_unit;
    if (n.contains('exhaust') || n.contains('silencer')) return Icons.cloud;
    if (n.contains('body') || n.contains('paint')) return Icons.color_lens;
    if (n.contains('tyre') || n.contains('tire')) return Icons.circle;
    if (n.contains('brake')) return Icons.stop_circle;
    if (n.contains('drive') || n.contains('gear')) return Icons.settings;
    if (n.contains('battery')) return Icons.battery_full;
    if (n.contains('wash') || n.contains('clean')) return Icons.cleaning_services;
    if (n.contains('engine') || n.contains('motor')) return Icons.precision_manufacturing;
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
            cs.primary.withOpacity(0.45),
            cs.secondary.withOpacity(0.35),
            const Color(0xFF01C9F5).withOpacity(0.25),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
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
      (
        icon: Icons.qr_code_scanner,
        label: 'Scan QR',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => QrScannerPage()),
          );
        },
      ),
      (
        icon: Icons.search,
        label: 'Search Parts',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SearchPage()),
          );
        },
      ),
      (
        icon: Icons.construction,
        label: 'View Parts',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SparePartsPage()),
          );
        },
      ),
      (
        icon: Icons.subscriptions,
        label: 'Subscriptions',
        onTap: () {
          // Scroll intent could be added; for now, open Search as placeholder
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SearchPage()),
          );
        },
      ),
    ];

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
              foregroundColor: Colors.white,
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    final likedIds = AppState.getLikedServiceIds();
    if (likedIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final asyncAll = ref.watch(providers.allServicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Likes',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        asyncAll.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => const SizedBox.shrink(),
          data: (services) {
            final liked = services.where((s) => likedIds.contains(s.id)).toList();
            if (liked.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 160,
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
    final imageUrl = buildImageUrl(service.images.isNotEmpty ? service.images.first : null);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ServiceDetailPage(service: service)),
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
                  ? const Center(child: Icon(Icons.handyman, color: Colors.white54))
                  : ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        width: double.infinity,
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text('₹${service.price}.00', style: const TextStyle(color: Color(0xFF01C9F5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}