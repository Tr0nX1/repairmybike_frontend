import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/booking_api.dart';
import '../utils/app_error.dart';
import 'widgets/booking_timeline.dart';

class BookingDetailPage extends ConsumerStatefulWidget {
  final int bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends ConsumerState<BookingDetailPage> {
  late Future<Map<String, dynamic>> _bookingFuture;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    _bookingFuture = BookingApi().getBookingDetail(widget.bookingId);
  }

  Future<void> _approveParts(List<int> partIds) async {
    setState(() => _actionLoading = true);
    try {
      await BookingApi().approveParts(widget.bookingId, partIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parts approved successfully')));
      setState(() => _fetch());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppError.sanitize(e))));
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text('Booking #${widget.bookingId}'),
        backgroundColor: const Color(0xFF071A1D),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load details', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => setState(() => _fetch()), child: const Text('Retry')),
                ],
              ),
            );
          }

          final b = snapshot.data!;
          final status = b['booking_status'] ?? 'pending';
          final payStatus = b['payment_status'] ?? 'pending';
          final parts = (b['booking_parts'] as List?) ?? [];
          final pendingParts = parts.where((p) => p['approval_status'] == 'pending').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Card(
                  color: const Color(0xFF1C1C1C),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: BookingTimeline(status: status),
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Status
                _sectionHeader('Payment Information'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: payStatus == 'completed' ? Colors.green.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        payStatus == 'completed' ? Icons.check_circle : Icons.pending_actions,
                        color: payStatus == 'completed' ? Colors.green : Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payStatus == 'completed' ? 'Cash payment received ✓' : 'Cash payment due at shop',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: payStatus == 'completed' ? Colors.green : Colors.amber,
                              ),
                            ),
                            if (payStatus != 'completed')
                              Text(
                                '₹${b['total_amount']} to be paid in cash',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Pending Parts
                if (status == 'in_progress' && pendingParts.isNotEmpty) ...[
                  _sectionHeader('Action Required: New Parts Added'),
                  ...pendingParts.map((p) => _pendingPartCard(p)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _actionLoading ? null : () => _approveParts(pendingParts.map((p) => p['id'] as int).toList()),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: _actionLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Approve All New Parts'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // All Parts
                if (parts.isNotEmpty) ...[
                  _sectionHeader('Spare Parts'),
                  ...parts.where((p) => p['approval_status'] != 'pending').map((p) => _partTile(p)),
                  const SizedBox(height: 24),
                ],

                // Services
                _sectionHeader('Services'),
                Card(
                  color: const Color(0xFF1C1C1C),
                  child: Column(
                    children: [
                      for (var s in (b['booking_services'] as List))
                        ListTile(
                          title: Text(s['service_name'] ?? 'Service', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          trailing: Text('₹${s['price']}', style: const TextStyle(color: Color(0xFF01C9F5), fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2),
      ),
    );
  }

  Widget _pendingPartCard(Map<String, dynamic> p) {
    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.amber, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (p['part_image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: p['part_image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['part_name'] ?? 'Part', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Qty: ${p['quantity']} × ₹${p['unit_price']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Text('₹${p['total_price']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _partTile(Map<String, dynamic> p) {
    final status = p['approval_status'];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(p['part_name'] ?? 'Part', style: const TextStyle(color: Colors.white70, fontSize: 13)),
      subtitle: Text('Status: $status', style: TextStyle(color: status == 'approved' ? Colors.green : Colors.red, fontSize: 10)),
      trailing: Text('₹${p['total_price']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }
}
