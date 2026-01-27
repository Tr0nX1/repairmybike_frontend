import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/spare_parts_provider.dart';
import '../providers/category_provider.dart';
import '../models/spare_part.dart';
import '../models/service.dart';
import 'service_detail_page.dart';
import 'spare_part_detail_page.dart';
import '../utils/url_utils.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final partsAsync = query.isEmpty
        ? const AsyncValue<List<SparePartListItem>>.data([])
        : ref.watch(sparePartsByFilterProvider(PartsFilter(search: query)));
    final servicesAsync = ref.watch(allServicesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        title: const Text('Search'),
        actions: const [],
      ),
      body: Column(
        children: [
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
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search parts, services, etc.',
                        hintStyle: TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spare parts section
                  _SectionHeader(title: 'Spare Parts'),
                  partsAsync.when(
                    loading: () => const _Loading(),
                    error: (e, _) => _ErrorText('Failed to load parts: ${e.toString()}'),
                    data: (parts) {
                      final list = parts;
                      if (query.isEmpty || list.isEmpty) {
                        return const _EmptyText('No matching parts');
                      }
                      return _PartsList(list: list);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Services section
                  _SectionHeader(title: 'Services'),
                  servicesAsync.when(
                    loading: () => const _Loading(),
                    error: (e, _) => _ErrorText('Failed to load services: ${e.toString()}'),
                    data: (services) {
                      final q = query.toLowerCase();
                      final filtered = q.isEmpty
                          ? <Service>[]
                          : services
                              .where((s) => s.name.toLowerCase().contains(q))
                              .toList();
                      if (filtered.isEmpty) {
                        return const _EmptyText('No matching services');
                      }
                      return _ServicesList(list: filtered);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LinearProgressIndicator(),
      );
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text, style: const TextStyle(color: Colors.redAccent)),
      );
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text, style: const TextStyle(color: Colors.white60)),
      );
}

class _PartsList extends StatelessWidget {
  final List<SparePartListItem> list;
  const _PartsList({required this.list});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2A2A)),
      itemBuilder: (context, i) {
        final p = list[i];
        return ListTile(
          leading: p.thumbnail != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: buildImageUrl(p.thumbnail)!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[800]!,
                      highlightColor: Colors.grey[700]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.handyman, color: Colors.white70),
                  ),
                )
              : const Icon(Icons.handyman, color: Colors.white70),
          title: Text(p.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(p.brandName.isNotEmpty ? p.brandName : p.categoryName, style: const TextStyle(color: Colors.white60)),
          trailing: Text(
            '${p.currency} ${p.salePrice > 0 ? p.salePrice : p.mrp}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => SparePartDetailPage(item: p)));
          },
        );
      },
    );
  }
}

class _ServicesList extends StatelessWidget {
  final List<Service> list;
  const _ServicesList({required this.list});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2A2A)),
      itemBuilder: (context, i) {
        final s = list[i];
        return ListTile(
          leading: const Icon(Icons.build_circle, color: Colors.white70),
          title: Text(s.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(s.categoryName.isNotEmpty ? s.categoryName : 'Service', style: const TextStyle(color: Colors.white60)),
          trailing: s.price > 0
              ? Text('₹ ${s.price}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
              : null,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceDetailPage(service: s)));
          },
        );
      },
    );
  }
}
