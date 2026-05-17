import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/category_provider.dart';
import '../models/category.dart';
import 'subscription_section.dart';
import 'spare_parts_section.dart';
import '../data/app_state.dart';
import '../providers/category_provider.dart' as providers;
import '../providers/saved_services_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/vehicles_provider.dart';
import '../models/service.dart';
import '../utils/url_utils.dart';

import 'widgets/dynamic_hero_carousel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _showAllCategories = false;
  bool _loadPartsSection = false;

  static const Color card = Color(0xFF1C1C1C);

  static const Color accent = Color(0xFF01C9F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _loadPartsSection = true);
      }
    });
  }

  void _showVehiclePicker(BuildContext context, WidgetRef ref, List<dynamic> vehicles) {
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Switch Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...vehicles.map((v) {
              final details = v['vehicle_model_details'];
              if (details == null) return const SizedBox.shrink();
              final isSelected = AppState.vehicleModelId == details['id'];
              return ListTile(
                leading: Icon(Icons.two_wheeler, color: isSelected ? accent : Colors.white54),
                title: Text(details['name'] ?? 'Vehicle', style: TextStyle(color: isSelected ? accent : Colors.white)),
                subtitle: Text(details['brand_name'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: isSelected ? const Icon(Icons.check, color: accent) : null,
                onTap: () {
                  AppState.setVehicle(
                    name: details['name'],
                    modelId: details['id'],
                    brand: details['brand_name'],
                    type: details['vehicle_type_name'],
                    syncToBackend: false,
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                },
              );
            }),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: accent),
              title: const Text('Add New Vehicle', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/vehicle-type');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        border: Border.all(color: Theme.of(context).colorScheme.primary),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/launcher icon/transparent repairmybike launcher.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final asyncVehicles = ref.watch(userVehiclesProvider);
                        return asyncVehicles.when(
                          data: (vehicles) {
                            if (vehicles.isEmpty) {
                              return GestureDetector(
                                onTap: () => context.push('/vehicle-type'),
                                child: const Text(
                                  'Add Vehicle +',
                                  style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              );
                            }
                            
                            if (vehicles.length == 1 && !AppState.hasVehicle) {
                               final v = vehicles.first;
                               final details = v['vehicle_model_details'];
                               if (details != null) {
                                  Future.microtask(() => AppState.setVehicle(
                                    name: details['name'],
                                    modelId: details['id'],
                                    brand: details['brand_name'],
                                    type: details['vehicle_type_name'],
                                    syncToBackend: false,
                                  ));
                               }
                            }

                            final b = AppState.vehicleBrand;
                            final m = AppState.vehicleName;
                            final display = (b == null || b.isEmpty) 
                                ? (m ?? 'Select Vehicle') 
                                : "$b ${m ?? ''}";

                            return GestureDetector(
                              onTap: () => _showVehiclePicker(context, ref, vehicles),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    display,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (vehicles.length > 1)
                                     const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white54),
                                ],
                              ),
                            );
                          },
                          loading: () => const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => const Text('Error', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                        );
                      }
                    ),
                    const Spacer(),
                    Consumer(
                      builder: (context, ref, _) {
                        final asyncCount = ref.watch(unreadNotificationsCountProvider);
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: () => context.push('/notifications'),
                            ),
                            asyncCount.maybeWhen(
                              data: (count) => count > 0 
                                ? Positioned(
                                    right: 8, top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const DynamicHeroCarousel(),
                const SizedBox(height: 12),
                const _QuickActionsRow(),
                const SizedBox(height: 24),

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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                  data: (categories) {
                    if (categories.isEmpty) return const Text('No categories');
                    final width = MediaQuery.of(context).size.width;
                    int crossAxisCount = width >= 600 ? 5 : 3;
                    final visible = _showAllCategories ? categories : categories.take(6).toList();
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: isPhone ? 0.85 : 1.0,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) => _CategoryCard(category: visible[index]),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showAllCategories = !_showAllCategories),
                    child: Text(_showAllCategories ? 'Show Less' : 'Show More'),
                  ),
                ),
                const SizedBox(height: 24),
                const SubscriptionSection(),
                const SizedBox(height: 32),
                if (_loadPartsSection) const SparePartsSection(),
                const SizedBox(height: 32),
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
    final accentColor = Color(0xFF00E5FF); // simplified

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/services?id=${category.id}&name=${category.name}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.2),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cardColor, accentColor.withValues(alpha: 0.08)]),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: SizedBox(
                width: 54, height: 54,
                child: category.image != null
                    ? CachedNetworkImage(imageUrl: category.image!, fit: BoxFit.cover)
                    : Icon(Icons.handyman, color: accentColor, size: 34),
              ),
            ),
            const SizedBox(height: 8),
            Text(category.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();
  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _btn(context, Icons.search, 'Search Parts', () => context.push('/search')),
          const SizedBox(width: 8),
          _btn(context, Icons.flash_on, 'Quick Service', () => context.push('/quick-service')),
          const SizedBox(width: 8),
          _btn(context, Icons.construction, 'View Parts', () => context.push('/spare-parts')),
        ],
      ),
    );
  }
  Widget _btn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
    );
  }
}

class _LikedServicesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedIds = ref.watch(savedServicesProvider);
    if (likedIds.isEmpty) return const SizedBox.shrink();
    final asyncAll = ref.watch(providers.allServicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Likes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        asyncAll.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => const SizedBox.shrink(),
          data: (services) {
            final liked = services.where((s) => likedIds.contains(s.id)).toList();
            if (liked.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 185,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: liked.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _LikedCard(service: liked[i]),
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
    final imageUrl = buildImageUrl(service.images.isNotEmpty ? service.images.first : null);
    return InkWell(
      onTap: () => context.push('/service-detail', extra: service),
      child: Container(
        width: 220,
        decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2A2A))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: imageUrl != null ? CachedNetworkImage(imageUrl: imageUrl, width: double.infinity, fit: BoxFit.cover) : const Center(child: Icon(Icons.handyman))),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(service.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('₹${service.price}', style: const TextStyle(color: Color(0xFF01C9F5))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
