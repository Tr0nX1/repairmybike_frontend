import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/staff_provider.dart';
import '../../../models/spare_part.dart';
import '../widgets/status_chip.dart';
import '../widgets/cash_collection_dialog.dart';
import '../widgets/part_picker_dialog.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const JobDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Timer? _notesDebounce;

  void _onNotesChanged(String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(
      const Duration(milliseconds: 800),
      () => _saveNotes(value),
    );
  }

  Future<void> _saveNotes(String notes) async {
    try {
      final api = ref.read(staffApiProvider);
      await api.updateBookingNotes(widget.bookingId, notes);
    } catch (e) {
      debugPrint('Failed to save notes: $e');
    }
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(staffBookingsProvider(null));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Job #${widget.bookingId}'),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final booking = bookings.firstWhere(
            (b) => b['id'] == widget.bookingId,
            orElse: () => null,
          );

          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }

          final customer = booking['customer'] ?? {};
          final services = booking['booking_services'] as List<dynamic>? ?? [];
          final parts = booking['booking_parts'] as List<dynamic>? ?? [];
          final currentStatus = booking['booking_status'] ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusChip(status: currentStatus),
                    Text(
                      '₹${booking['total_amount']}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _SectionHeader(title: 'Vehicle Details', icon: Icons.motorcycle),
                Card(
                  child: ListTile(
                    title: Text('${booking['vehicle_brand_name']} ${booking['vehicle_model_name']}'),
                    subtitle: Text(booking['vehicle_type_name'] ?? 'Bike'),
                  ),
                ),
                const SizedBox(height: 16),

                _SectionHeader(title: 'Customer Info', icon: Icons.person_outline),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Name', value: customer['name'] ?? 'N/A'),
                        const Divider(),
                        _InfoRow(label: 'Phone', value: customer['phone'] ?? 'N/A'),
                        if (booking['service_location'] == 'home') ...[
                          const Divider(),
                          _InfoRow(label: 'Address', value: booking['address'] ?? 'N/A'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _SectionHeader(title: 'Services', icon: Icons.list_alt),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = services[index];
                      return ListTile(
                        dense: true,
                        title: Text(s['service_name'] ?? 'Service'),
                        subtitle: Text(s['category_name'] ?? ''),
                        trailing: Text('₹${s['price']}'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                _SectionHeader(
                  title: 'Spare Parts', 
                  icon: Icons.inventory_2_outlined,
                  action: currentStatus == 'in_progress' ? TextButton.icon(
                    onPressed: () => _addPart(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Part'),
                  ) : null,
                ),
                Card(
                  child: parts.isEmpty 
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No parts added yet', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: parts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = parts[index];
                          return ListTile(
                            dense: true,
                            title: Text(p['part_name'] ?? 'Part'),
                            subtitle: Text('Qty: ${p['quantity']} • SKU: ${p['sku']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('₹${p['total_price']}'),
                                if (currentStatus == 'in_progress')
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                    onPressed: () => _removePart(p['id']),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 24),

                if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
                  _SectionHeader(title: 'Customer Notes', icon: Icons.note_outlined),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(booking['notes']),
                  ),
                  const SizedBox(height: 24),
                ],

                _SectionHeader(title: 'Internal Staff Notes', icon: Icons.lock_outline),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add internal observation...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(8),
                      ),
                      onChanged: _onNotesChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: bookingsAsync.maybeWhen(
        data: (bookings) {
          final booking = bookings.firstWhere((b) => b['id'] == widget.bookingId, orElse: () => null);
          if (booking == null) return null;
          return _buildBottomActions(context, ref, widget.bookingId, booking['booking_status'], booking);
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, int id, String currentStatus, Map<String, dynamic> booking) {
    final payStatus = booking['payment_status'] ?? 'pending';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Evidence'),
            ),
          ),
          const SizedBox(width: 12),
          if (payStatus == 'pending' && (currentStatus == 'completed' || currentStatus == 'in_progress'))
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCollectionDialog(booking),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Collect Cash'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          if (currentStatus != 'completed')
            const SizedBox(width: 12),
          if (currentStatus != 'completed')
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(id, currentStatus), 
                child: const Text('Update Status'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(int id, String currentStatus) async {
    String nextStatus;
    if (currentStatus == 'pending') { nextStatus = 'confirmed'; }
    else if (currentStatus == 'confirmed') { nextStatus = 'in_progress'; }
    else if (currentStatus == 'in_progress') { nextStatus = 'completed'; }
    else { return; }

    try {
      final api = ref.read(staffApiProvider);
      await api.updateBookingStatus(id, nextStatus);
      ref.invalidate(staffBookingsProvider(null));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $nextStatus')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showCollectionDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => CashCollectionDialog(
        booking: booking,
        onSuccess: () => ref.invalidate(staffBookingsProvider(null)),
      ),
    );
  }

  Future<void> _addPart() async {
    final SparePartListItem? part = await showDialog<SparePartListItem>(
      context: context,
      builder: (context) => const PartPickerDialog(),
    );

    if (part != null) {
      try {
        final api = ref.read(staffApiProvider);
        await api.addPartToBooking(widget.bookingId, part.id, 1);
        ref.invalidate(staffBookingsProvider(null));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Part added to job')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add part: $e')));
      }
    }
  }

  Future<void> _removePart(int bookingPartId) async {
    try {
      final api = ref.read(staffApiProvider);
      await api.removePartFromBooking(widget.bookingId, bookingPartId);
      ref.invalidate(staffBookingsProvider(null));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Part removed from job')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove part: $e')));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? action;

  const _SectionHeader({required this.title, required this.icon, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
