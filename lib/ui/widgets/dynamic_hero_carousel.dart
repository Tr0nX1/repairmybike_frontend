import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cms_provider.dart';
import '../../models/banner.dart';

class DynamicHeroCarousel extends ConsumerWidget {
  const DynamicHeroCarousel({super.key});

  void _onTap(BannerItem item) {
    if (item.linkUrl != null && item.linkUrl!.isNotEmpty) {
      if (item.linkUrl!.startsWith('http')) {
        launchUrl(Uri.parse(item.linkUrl!), mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBanners = ref.watch(bannersProvider);

    return asyncBanners.when(
      loading: () => const _ShimmerBanner(),
      error: (err, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const _StaticFallbackBanner();
        }

        final isMulti = items.length > 1;

        return CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: isMulti,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            viewportFraction: 1.0,
            enableInfiniteScroll: isMulti,
          ),
          items: items.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () => _onTap(item),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[900],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const _ShimmerBanner(isInner: true),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _StaticFallbackBanner extends StatelessWidget {
  const _StaticFallbackBanner();

   @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isPhone = w < 600;
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: w < 360 ? 160 : (isPhone ? 190 : 220),
      margin: const EdgeInsets.symmetric(horizontal: 5),
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

class _ShimmerBanner extends StatelessWidget {
  final bool isInner;
  const _ShimmerBanner({this.isInner = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: Container(
        height: 200,
        margin: isInner ? null : const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
