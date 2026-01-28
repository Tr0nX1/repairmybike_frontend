import 'package:flutter/material.dart';
import '../../data/feedback_api.dart';

class FeedbackBottomSheet extends StatefulWidget {
  final String type; // 'SERVICE' or 'PRODUCT'
  final int targetId;
  final int? bookingId;
  final int? orderId;
  final String title;

  const FeedbackBottomSheet({
    super.key,
    required this.type,
    required this.targetId,
    this.bookingId,
    this.orderId,
    required this.title,
  });

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  int _rating = 0;
  int _qualityRating = 0;
  int _behaviorRating = 0;
  int _appRating = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  final List<String> _selectedChips = [];
  bool _submitting = false;

  final List<String> _serviceChips = ['On-Time', 'Professional', 'Clean Work', 'Good Behavior', 'Reasonable Price'];
  final List<String> _productChips = ['Good Quality', 'Fast Shipping', 'Authentic', 'Well Packed', 'Easy Fitting'];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Widget _buildRatingStars(int current, Function(int) onSelect, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) 
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (i) {
            final starIdx = i + 1;
            return GestureDetector(
              onTap: () => onSelect(starIdx),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  starIdx <= current ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: starIdx <= current ? const Color(0xFF01C9F5) : Colors.white24,
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = widget.type == 'SERVICE' ? _serviceChips : _productChips;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How was your ${widget.type == 'SERVICE' ? 'service' : 'product'}?',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(widget.title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            
            _buildRatingStars(_rating, (v) => setState(() => _rating = v), 'Overall Rating'),
            const SizedBox(height: 20),
            
            if (widget.type == 'SERVICE') ...[
              _buildRatingStars(_qualityRating, (v) => setState(() => _qualityRating = v), 'Work Quality'),
              const SizedBox(height: 16),
              _buildRatingStars(_behaviorRating, (v) => setState(() => _behaviorRating = v), 'Mechanic Behavior'),
            ] else ...[
              _buildRatingStars(_qualityRating, (v) => setState(() => _qualityRating = v), 'Product Quality'),
            ],
            
            const SizedBox(height: 24),
            const Text('What did you like?', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((chip) {
                final selected = _selectedChips.contains(chip);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) _selectedChips.remove(chip);
                      else _selectedChips.add(chip);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF01C9F5).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? const Color(0xFF01C9F5) : Colors.white12),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(color: selected ? const Color(0xFF01C9F5) : Colors.white70, fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a comment (optional)...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _rating == 0 || _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01C9F5),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: _submitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Submit Feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await FeedbackApi().submitReview(
        reviewType: widget.type,
        targetId: widget.targetId,
        rating: _rating,
        qualityRating: _qualityRating > 0 ? _qualityRating : null,
        behaviorRating: _behaviorRating > 0 ? _behaviorRating : null,
        comment: _commentCtrl.text.trim(),
        chips: _selectedChips,
        bookingId: widget.bookingId,
        orderId: widget.orderId,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Color(0xFF01C9F5)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
