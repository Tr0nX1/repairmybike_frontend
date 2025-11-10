import 'package:flutter/material.dart';
import '../models/spare_part.dart';
import '../utils/url_utils.dart';

class SparePartDetailPage extends StatelessWidget {
  final SparePartListItem item;
  const SparePartDetailPage({super.key, required this.item});

  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  String get priceLabel => '${item.currency == 'INR' ? '₹' : item.currency} ${item.salePrice > 0 ? item.salePrice : item.mrp}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.thumbnail != null && item.thumbnail!.isNotEmpty
                    ? Image.network(
                        buildImageUrl(item.thumbnail)!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 240,
                      )
                    : Container(
                        height: 240,
                        color: Colors.black,
                        child: const Center(child: Icon(Icons.handyman, color: accent, size: 42)),
                      ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(priceLabel, style: const TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Brand: ${item.brandName}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('Category: ${item.categoryName}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    if (item.shortDescription.isNotEmpty)
                      Text(item.shortDescription, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(item.inStock ? Icons.check_circle : Icons.cancel, color: item.inStock ? accent : Colors.redAccent),
                        const SizedBox(width: 6),
                        Text(item.inStock ? 'In Stock (${item.stockQty})' : 'Out of Stock',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}