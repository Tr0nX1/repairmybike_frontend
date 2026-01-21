import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/category_provider.dart';
import '../models/service.dart';
import 'service_detail_page.dart';
import '../utils/url_utils.dart';
import '../data/app_state.dart';

class ServicesPage extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;
  const ServicesPage({super.key, required this.categoryId, required this.categoryName});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  int? selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.categoryId; // start with tapped category
  }

  @override
  Widget build(BuildContext context) {
    final asyncCategories = ref.watch(categoriesProvider);
    final asyncServices = selectedCategoryId == null
        ? ref.watch(allServicesProvider)
        : ref.watch(servicesByCategoryProvider(selectedCategoryId!));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        title: const Text('All Services'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white70),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search services...',
                        hintStyle: TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const Icon(Icons.mic_none, color: Colors.white70),
                ],
              ),
            ),
          ),

          // Category chips
          SizedBox(
            height: 52,
            child: asyncCategories.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
              data: (cats) {
                final items = [
                  const _ChipItem(id: null, label: 'All'),
                  ...cats.map((c) => _ChipItem(id: c.id, label: c.name)),
                ];
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final selected = selectedCategoryId == item.id;
                    return ChoiceChip(
                      label: Text(item.label),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        selectedCategoryId = item.id;
                      }),
                      selectedColor: const Color(0xFF01C9F5),
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: const Color(0xFF1C1C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Services grid
          Expanded(
            child: asyncServices.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load services: ${err.toString()}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (services) {
                // Local search filter
                final q = _searchController.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? services
                    : services
                        .where((s) => s.name.toLowerCase().contains(q))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No services', style: TextStyle(color: Colors.white70)),
                  );
                }

                // Responsive grid
                final width = MediaQuery.of(context).size.width;
                int cols = 2;
                if (width >= 600) cols = 4;
                if (width >= 1000) cols = 5;
                if (width >= 1400) cols = 6;
                // Adjust aspect ratio for wider cards to not look stretched
                final ratio = width < 600 ? 0.78 : 0.85;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: ratio,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final s = filtered[idx];
                    return _ServiceCard(service: s);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipItem {
  final int? id;
  final String label;
  const _ChipItem({required this.id, required this.label});
}

class _ServiceCard extends StatefulWidget {
  final Service service;
  const _ServiceCard({required this.service});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF1C1C1C);
    const borderColor = Color(0xFF2A2A2A);

    final s = widget.service;
    final rating = double.tryParse(s.rating) ?? 0.0;
    final imageUrl = buildImageUrl(s.images.isNotEmpty ? s.images.first : null);
    final liked = AppState.isServiceLiked(s.id);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceDetailPage(service: s),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
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
            child: Column(
              children: [
                // Thumbnail area
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF202020),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: imageUrl == null
                      ? Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFF01C9F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.build_rounded, color: Colors.black, size: 32),
                          ),
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
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF01C9F5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.build_rounded,
                                    color: Colors.black, size: 32),
                              ),
                            ),
                          ),
                        ),
                ),
                const Spacer(),
                // content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${s.price}.00',
                            style: const TextStyle(color: Color(0xFF00D0FF), fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          // favorite icon
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: () async {
                await AppState.toggleLikeService(s.id);
                if (mounted) setState(() {});
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? const Color(0xFFFF6B6B) : Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
