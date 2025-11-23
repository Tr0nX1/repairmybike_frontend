import 'package:flutter/material.dart';
import '../models/service.dart';
import 'booking_form_page.dart';
import 'booking_list_page.dart';
import '../utils/url_utils.dart';
import '../data/app_state.dart';

class ServiceDetailPage extends StatefulWidget {
  final Service service;
  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {

  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  String? _selectedLocation; // 'home' or 'shop'
  late TextEditingController _feedbackCtrl;
  int _myRating = 0; // 0-5
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = TextEditingController();
    _liked = AppState.isServiceLiked(widget.service.id);
    final fb = AppState.getServiceFeedback(widget.service.id);
    if (fb != null) {
      _myRating = (fb['rating'] as int?) ?? 0;
      _feedbackCtrl.text = (fb['text'] as String?) ?? '';
    }
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _openLocationSelector() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select Service Location',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white70),
                title: const Text('Home Service', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('home'),
              ),
              ListTile(
                leading: const Icon(Icons.storefront, color: Colors.white70),
                title: const Text('Workshop', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('shop'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (choice == 'home' || choice == 'shop') {
      setState(() => _selectedLocation = choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(widget.service.rating) ?? 0.0;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        elevation: 0,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.favorite_border),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BookingListPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header image (uses first service image if available)
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Builder(builder: (context) {
                    final String? img = widget.service.images.isNotEmpty
                        ? widget.service.images.first?.toString()
                        : null;
                    final url = buildImageUrl(img);
                    if (url == null) {
                      return Container(
                        color: const Color(0xFF202020),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.build_rounded, size: 48, color: Colors.black),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            )
                          ],
                        ),
                      );
                    }
                    return Image.network(url, fit: BoxFit.cover);
                  }),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.service.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '₹${widget.service.price}.00',
                                style: const TextStyle(
                                  color: accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () async {
                                  await AppState.toggleLikeService(widget.service.id);
                                  if (mounted) setState(() => _liked = AppState.isServiceLiked(widget.service.id));
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1C),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: border),
                                  ),
                                  child: Icon(
                                    _liked ? Icons.favorite : Icons.favorite_border,
                                    color: _liked ? const Color(0xFFFF6B6B) : Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Meta chips: rating, reviews, category
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _metaChip(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          if (widget.service.reviewsCount > 0)
                            _metaChip(
                              child: Text(
                                '${widget.service.reviewsCount} reviews',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          if (widget.service.categoryName.isNotEmpty)
                            _metaChip(
                              child: Text(
                                widget.service.categoryName,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Description',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.service.description.isEmpty
                            ? 'No description available.'
                            : widget.service.description,
                        style: const TextStyle(color: Colors.white70, height: 1.5),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Service Includes',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _IncludesList(
                        items: widget.service.specifications.map((e) => e.toString()).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Service Location card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Service Location',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedLocation == null
                                        ? 'Home Service / Workshop'
                                        : (_selectedLocation == 'home' ? 'Home Service' : 'Workshop'),
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _openLocationSelector,
                              child: const Text('Change',
                                  style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Your Feedback',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      _RatingRow(
                        current: _myRating,
                        onChanged: (v) => setState(() => _myRating = v),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _feedbackCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Share your experience...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: accent),
                            foregroundColor: accent,
                          ),
                          onPressed: () async {
                            await AppState.setServiceFeedback(
                              serviceId: widget.service.id,
                              rating: _myRating,
                              text: _feedbackCtrl.text.trim(),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Feedback saved')));
                          },
                          child: const Text('Save Feedback'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                color: bg,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookingFormPage(
                            service: widget.service,
                            initialLocation: _selectedLocation,
                          ),
                        ),
                      );
                    },
                    child: const Text('Book Service Now',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _metaChip({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

}

class _RatingRow extends StatelessWidget {
  final int current; // 0-5
  final ValueChanged<int> onChanged;
  const _RatingRow({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = idx <= current;
        return GestureDetector(
          onTap: () => onChanged(idx),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.star,
              color: filled ? Colors.amber : Colors.white24,
              size: 24,
            ),
          ),
        );
      }),
    );
  }
}

class _IncludesList extends StatelessWidget {
  final List<String> items;
  const _IncludesList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No items available', style: TextStyle(color: Colors.white54));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final text = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2E32),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF01C9F5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
