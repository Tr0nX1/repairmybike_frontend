import 'package:flutter/material.dart';
import '../../data/feedback_api.dart';

class ReviewsList extends StatelessWidget {
  final String type;
  final int targetId;

  const ReviewsList({super.key, required this.type, required this.targetId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FeedbackApi().getReviews(type: type, targetId: targetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No reviews yet. Be the first to rate!',
                style: TextStyle(color: Colors.white24, fontSize: 14),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Customer Reviews',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF01C9F5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${reviews.length}',
                    style: const TextStyle(color: Color(0xFF01C9F5), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final r = reviews[index];
                final rating = r['rating'] as int? ?? 0;
                final user = r['user_name'] ?? 'Verified Customer';
                final date = DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now();
                final comment = r['comment'] ?? '';
                final chips = (r['chips'] as List?)?.cast<String>() ?? [];
                final verified = r['is_verified'] == true;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF01C9F5).withOpacity(0.1),
                            child: Text(
                              user.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Color(0xFF01C9F5), fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(user, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    if (verified) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified, color: Color(0xFF01C9F5), size: 14),
                                    ],
                                  ],
                                ),
                                Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(color: Colors.white24, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '$rating',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(comment, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                      ],
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: chips.map((c) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(c, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
