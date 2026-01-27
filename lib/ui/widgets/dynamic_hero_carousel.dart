import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // v5.0.0
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/content_api.dart';
import '../../models/content.dart';

class DynamicHeroCarousel extends StatefulWidget {
  const DynamicHeroCarousel({super.key});

  @override
  State<DynamicHeroCarousel> createState() => _DynamicHeroCarouselState();
}

class _DynamicHeroCarouselState extends State<DynamicHeroCarousel> {
  List<CarouselItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final items = await ContentApi().getCarousel();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  void _onTap(CarouselItem item) {
    if (item.actionLink != null && item.actionLink!.isNotEmpty) {
      // Simple logic: if http opens external, else treated as route?
      // For now, let's assume external or internal handled by simple check
      if (item.actionLink!.startsWith('http')) {
        launchUrl(Uri.parse(item.actionLink!), mode: LaunchMode.externalApplication);
      } else {
        // Maybe route navigation? 
        // For strict MVP, we might log or just ignore if not valid URL
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _ShimmerBanner();
    }

    if (_items.isEmpty) {
      return const _StaticFallbackBanner();
    }

    // If only 1 item, don't auto-scroll
    final isMulti = _items.length > 1;

    return CarouselSlider(
      options: CarouselOptions(
        height: 200, // standard height
        autoPlay: isMulti,
        autoPlayInterval: const Duration(seconds: 5),
        enlargeCenterPage: true,
        viewportFraction: 0.92,
        enableInfiniteScroll: isMulti,
      ),
      items: _items.map((item) {
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
                      imageUrl: item.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _ShimmerBanner(isInner: true),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                    // Gradient overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                    // Text
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
                          if (item.subtitle != null && item.subtitle!.isNotEmpty)
                            Text(
                              item.subtitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
      margin: const EdgeInsets.symmetric(horizontal: 5), // match carousel margin
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
