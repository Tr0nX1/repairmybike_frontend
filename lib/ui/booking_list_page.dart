import 'package:flutter/material.dart';
import 'dart:async';
import '../data/booking_api.dart';
import '../data/order_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_state.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  // Theme colors
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  // State
  // Future sections: subscription and spare parts bookings.
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _subscriptionBookings = [];
  List<Map<String, dynamic>> _sparePartsBookings = [];
  bool _loading = false;
  final BookingApi _bookingApi = BookingApi();
  final TextEditingController _phoneCtrl = TextEditingController();

  Timer? _autoRefreshTimer;
  DateTime? _backoffUntil;
  DateTime? _lastSync;
  bool _loadedFromCache = false;

  String _monthName(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  String _fmtDateTime(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    final d = dt.toLocal();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}, '
        '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    final dt = DateTime.tryParse(s);
    if (dt != null) {
      final d = dt.toLocal();
      return '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';
    }
    // Fallback: expect YYYY-MM-DD
    final parts = s.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return '${d.toString().padLeft(2, '0')} ${_monthName(m)} $y';
      }
    }
    return s;
  }

  String _fmtTime(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    // Expect HH:MM:SS or HH:MM
    final parts = s.split(':');
    if (parts.length >= 2) {
      final hh = int.tryParse(parts[0]) ?? 0;
      final mm = int.tryParse(parts[1]) ?? 0;
      final h = hh % 12 == 0 ? 12 : hh % 12;
      final ampm = hh >= 12 ? 'PM' : 'AM';
      return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')} $ampm';
    }
    return s;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatTimeSince(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _loadFromCache() async {
    // Load cached data immediately for offline support
    final cachedBookings = await AppState.getCachedBookings();
    final cachedOrders = await AppState.getCachedOrders();
    final lastSyncBookings = await AppState.getLastSyncBookings();
    final lastSyncOrders = await AppState.getLastSyncOrders();
    
    if (cachedBookings.isNotEmpty || cachedOrders.isNotEmpty) {
      setState(() {
        _bookings = cachedBookings;
        _sparePartsBookings = cachedOrders;
        _loadedFromCache = true;
        // Use the most recent sync time
        if (lastSyncBookings != null && lastSyncOrders != null) {
          _lastSync = lastSyncBookings.isAfter(lastSyncOrders) 
              ? lastSyncBookings 
              : lastSyncOrders;
        } else {
          _lastSync = lastSyncBookings ?? lastSyncOrders;
        }
      });
    }
  }

  Future<void> _search() async {
    final phone = (AppState.phoneNumber ?? '').trim();
    if (phone.isEmpty) {
      _showSnack('Please login via OTP to view your bookings');
      return;
    }
    if (_backoffUntil != null && DateTime.now().isBefore(_backoffUntil!)) {
      final remaining = _backoffUntil!.difference(DateTime.now()).inSeconds;
      _showSnack('Paused due to rate limit. Retrying in ${remaining}s');
      return;
    }
    setState(() => _loading = true);
    try {
      // Fetch both service bookings and spare parts orders in parallel
      final results = await Future.wait([
        _bookingApi.getBookings(),
        _fetchSparePartsOrders(),
      ]);

      final bookings = results[0];
      final spareParts = results[1];

      if (mounted) {
        setState(() {
          _bookings = bookings;
          _sparePartsBookings = spareParts;
          _lastSync = DateTime.now();
        });
      }

      // Persist to local cache for offline/instant access
      await AppState.cacheBookings(bookings);
      await AppState.cacheOrders(spareParts);

      _startAutoRefresh();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('429')) {
        _backoffUntil = DateTime.now().add(const Duration(minutes: 2));
      }
      _showSnack('Failed to fetch bookings: $msg');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmCancelOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('Cancel Order?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      final success = await OrderApi().cancelOrder(orderId);
      if (success) {
        _showSnack('Order cancelled successfully');
        _search(); // Refresh list
      } else {
        _showSnack('Failed to cancel order');
        setState(() => _loading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSparePartsOrders() async {
    try {
      final phone = AppState.phoneNumber;
      final sessionId = await AppState.getCartSessionId();
      
      // Prefer phone if authenticated, otherwise use session_id
      if (phone == null || phone.isEmpty) {
        if (sessionId == null || sessionId.isEmpty) {
          return [];
        }
      }
      
      final api = OrderApi();
      final orders = await api.listOrders(
        sessionId: sessionId,
      );
      return orders
          .map(
            (o) => {
              'id': o.id,
              'total_amount': o.total,
              'booking_status': o.status,
              'payment_status': o.paymentStatus,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': null,
              'customer': {'name': o.customerName},
              'services': o.items.map((i) => {
                'name': i.name,
                'sku': i.sku,
                'quantity': i.quantity,
                'price': i.unitPrice,
              }).toList(),
              'isSparePartOrder': true,
              'tracking_number': o.trackingNumber,
              'courier_name': o.courierName,
              'estimated_delivery': o.estimatedDelivery?.toIso8601String(),
              'delivered_at': o.deliveredAt?.toIso8601String(),
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    // Poll every 60 seconds to avoid DRF throttle (429).
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final inBackoff =
          _backoffUntil != null && DateTime.now().isBefore(_backoffUntil!);
      if (!_loading &&
          !inBackoff &&
          ((AppState.phoneNumber ?? '').trim().isNotEmpty)) {
        _search();
      }
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _search,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!AppState.isCustomerAuthenticated) ...[
              _loginPrompt(),
              const SizedBox(height: 16),
            ],
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  Widget _loginPrompt() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.white70),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please login via OTP to view your bookings. Your phone number is used automatically after login.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    final hasServices = _bookings.isNotEmpty;
    final hasSubscriptions = _subscriptionBookings.isNotEmpty;
    final hasSpareParts = _sparePartsBookings.isNotEmpty;

    if (!hasServices && !hasSubscriptions && !hasSpareParts) {
      return const Center(
        child: Text('No bookings yet', style: TextStyle(color: Colors.white54)),
      );
    }

    final children = <Widget>[];

    if (hasServices) {
      children.add(_sectionDivider('Service Bookings'));
      children.add(const SizedBox(height: 12));
      for (final b in _bookings) {
        children.add(_bookingCard(b));
        children.add(const SizedBox(height: 12));
      }
    }
    if (hasSubscriptions) {
      children.add(_sectionDivider('Subscription Bookings'));
      children.add(const SizedBox(height: 12));
      for (final b in _subscriptionBookings) {
        children.add(_bookingCard(b));
        children.add(const SizedBox(height: 12));
      }
    }
    if (hasSpareParts) {
      children.add(_sectionDivider('Spare Parts Orders'));
      children.add(const SizedBox(height: 12));
      for (final b in _sparePartsBookings) {
        children.add(_bookingCard(b));
        children.add(const SizedBox(height: 12));
      }
    }

    return ListView(children: children);
  }

  Widget _chip(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }

  // Color-coded status chip for clearer state after status changes.
  Widget _statusChip(String status) {
    Color textColor = Colors.white70;
    Color outline = border;
    switch (status.toLowerCase()) {
      case 'pending':
        outline = const Color(0xFF8A8A8A);
        textColor = Colors.white70;
        break;
      case 'confirmed':
        outline = const Color(0xFF3CB371); // greenish
        textColor = const Color(0xFF9BE7C4);
        break;
      case 'in_progress':
      case 'processing':
        outline = const Color(0xFFFFA500); // orange
        textColor = const Color(0xFFFFD7A1);
        break;
      case 'completed':
        outline = const Color(0xFF01C9F5);
        textColor = const Color(0xFF9BE7FF);
        break;
      case 'cancelled':
      case 'canceled':
        outline = const Color(0xFFB22222); // red
        textColor = const Color(0xFFFFB3B3);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline),
      ),
      child: Text(status, style: TextStyle(color: textColor)),
    );
  }

  // Section divider with label, rendered only when that section has items.
  Widget _sectionDivider(String label) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: border)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: border)),
      ],
    );
  }

  // Unified booking/order card renderer used by all sections.
  Widget _bookingCard(Map<String, dynamic> b) {
    final id = b['id'];
    final total = b['total_amount'];
    final status = (b['booking_status'] ?? 'unknown').toString();
    final payStatus = (b['payment_status'] ?? 'unknown').toString();
    final createdAt = b['created_at'];
    final updatedAt = b['updated_at'];
    final customer = b['customer'] as Map<String, dynamic>?;
    final custName = customer?['name'] ?? '';
    final services = (b['services'] as List?) ?? const [];
    final apptDate = b['appointment_date'];
    final apptTime = b['appointment_time'];
    final location = (b['service_location'] ?? '').toString();
    final isSparePartOrder = b['isSparePartOrder'] == true;

    final requestedLine = isSparePartOrder
        ? 'Ordered: ${_fmtDateTime(createdAt)}'
        : 'Requested: ${_fmtDateTime(createdAt)}';
    final updatedLine = (updatedAt != null && updatedAt.toString().isNotEmpty)
        ? 'Updated: ${_fmtDateTime(updatedAt)}'
        : '';
    final scheduleLine = (apptDate != null || apptTime != null)
        ? 'Schedule: ${_fmtDate(apptDate)}${apptTime != null ? ' · ${_fmtTime(apptTime)}' : ''}'
        : '';
    final locationLine = location.isNotEmpty && !isSparePartOrder
        ? 'Location: ${location == 'home' ? 'Home' : 'Workshop'}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSparePartOrder ? 'Order #$id' : 'Booking #$id',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '₹$total',
                style: const TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (custName.isNotEmpty)
            Text(
              custName,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                requestedLine,
                style: const TextStyle(color: Colors.white70),
              ),
              if (updatedLine.isNotEmpty)
                Text(
                  updatedLine,
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
          if (scheduleLine.isNotEmpty || locationLine.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (scheduleLine.isNotEmpty)
                  Text(
                    scheduleLine,
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (locationLine.isNotEmpty)
                  Text(
                    locationLine,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip(status),
              _chip('payment: $payStatus', Colors.white54),
              _chip(
                isSparePartOrder
                    ? 'items: ${services.length}'
                    : 'services: ${services.length}',
                Colors.white54,
              ),
            ],
          ),
          
          if (isSparePartOrder && services.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                     'Items Ordered:', 
                     style: TextStyle(color: Colors.white54, fontSize: 12)
                   ),
                   const SizedBox(height: 8),
                   ...services.map((s) {
                     final name = s['name'] ?? 'Unknown';
                     final sku = s['sku'] ?? '';
                     final qty = s['quantity'] ?? 1;
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 4),
                       child: Row(
                         children: [
                           Expanded(
                             child: Text(
                               sku.toString().isNotEmpty ? '$name ($sku)' : name,
                               style: const TextStyle(color: Colors.white),
                             ),
                           ),
                           Text(
                             'x$qty', 
                             style: const TextStyle(color: Colors.white70),
                           ),
                         ],
                       ),
                     );
                   }),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          // Cancel button for cancellable orders
          if (isSparePartOrder && !['cancelled', 'fulfilled', 'delivered', 'shipped'].contains(status.toLowerCase())) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirmCancelOrder(id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                child: const Text('Cancel Order'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Tracking Timeline
          if (isSparePartOrder)
            OrderTrackingTimeline(order: b),
            
          const SizedBox(height: 12),

          Row(
            children: [
              // Only show Edit Schedule for service bookings, not spare parts orders
              if (!isSparePartOrder) ...[
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: border),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _editScheduleDialog(b),
                      child: const Text('Edit Schedule'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (AppState.isStaffAuthenticated) ...[
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _changeStatusDialog(id, status),
                    child: const Text('Change Status'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (!isSparePartOrder)
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: border),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading ? null : _search,
                    child: const Text('Refresh'),
                  ),
                ),
              if (isSparePartOrder)
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: border),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _loading ? null : _search,
                      child: const Text('Refresh'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editScheduleDialog(Map<String, dynamic> b) async {
    final id = b['id'];
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Edit Schedule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        selectedDate == null
                            ? 'Select date'
                            : '${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}',
                      ),
                      onPressed: () async {
                        final res = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 0),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (res != null) setState(() => selectedDate = res);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        selectedTime == null
                            ? 'Select time'
                            : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                      ),
                      onPressed: () async {
                        final res = await showTimePicker(
                          context: ctx,
                          initialTime:
                              selectedTime ??
                              const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (res != null) setState(() => selectedTime = res);
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedDate == null || selectedTime == null) {
                      _showSnack('Please select date and time');
                      return;
                    }
                    final date =
                        '${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                    final time =
                        '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';
                    try {
                      await _bookingApi.updateBookingSchedule(
                        bookingId: id,
                        appointmentDate: date,
                        appointmentTime: time,
                      );
                      if (mounted) Navigator.of(ctx).pop();
                      _showSnack('Schedule updated');
                      _search();
                    } catch (e) {
                      _showSnack('Failed to update: $e');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Load from cache immediately, then fetch fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFromCache();
      final authPhone = AppState.phoneNumber;
      if (authPhone != null && authPhone.isNotEmpty) {
        _phoneCtrl.text = authPhone;
        _search();  // Fetch fresh data in background
        _startAutoRefresh();
      }
    });
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _changeStatusDialog(int bookingId, String currentStatus) async {
    final statuses = [
      'pending',
      'confirmed',
      'in_progress',
      'completed',
      'cancelled',
    ];
    String selected = currentStatus;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Change Booking Status'),
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in statuses)
                    ChoiceChip(
                      label: Text(s),
                      selected: selected == s,
                      onSelected: (_) => setState(() => selected = s),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final updated = await _bookingApi.staffUpdateStatus(
                        bookingId: bookingId,
                        status: selected,
                        sessionToken: AppState.sessionToken ?? '',
                      );
                      Navigator.of(ctx).pop();
                      _showSnack(
                        'Status updated to ${updated['booking_status'] ?? selected}',
                      );
                      _search();
                    } catch (e) {
                      _showSnack('Failed to update status: $e');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class OrderTrackingTimeline extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTrackingTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] as String? ?? 'pending').toLowerCase();
    
    // Determine tracking state
    int currentStep = 0;
    if (status == 'confirmed') currentStep = 1;
    if (status == 'shipped') currentStep = 2;
    if (status == 'out_for_delivery') currentStep = 3;
    if (status == 'delivered') currentStep = 4;
    
    // If cancelled, show red state
    if (status == 'cancelled') {
       return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text('Order Cancelled', style: TextStyle(color: Colors.red[300])),
          ],
        ),
      );
    }

    final trackingNumber = order['tracking_number'] as String?;
    final courierName = order['courier_name'] as String?;
    final estimatedDelivery = order['estimated_delivery'] as String?;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trackingNumber != null) ...[
            Row(
              children: [
                Icon(Icons.local_shipping, size: 16, color: Colors.blue[300]),
                const SizedBox(width: 8),
                Text(
                  'Shipped with ${courierName ?? "Courier"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              'Tracking ID: $trackingNumber',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Divider(color: Colors.white10),
          ],
          
          // Timeline
          const SizedBox(height: 8),
          Row(
            children: [
              _step(0, currentStep, 'Placed', Icons.shopping_cart),
              _line(0, currentStep),
              _step(1, currentStep, 'Confirmed', Icons.check_circle),
              _line(1, currentStep),
              _step(2, currentStep, 'Shipped', Icons.local_shipping),
              _line(2, currentStep),
              _step(4, currentStep, 'Delivered', Icons.home),
            ],
          ),
          
          if (estimatedDelivery != null && status != 'delivered') ...[
            const SizedBox(height: 12),
            Text(
              'Expected Delivery: $estimatedDelivery',
              style: TextStyle(color: Colors.green[300], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step(int distinctStep, int currentStep, String label, IconData icon) {
    // 0=placed, 1=confirmed, 2=shipped, 3=out_for_deliery, 4=delivered
    // Mapping simplified: 
    // Placed (0) -> Confirmed (1) -> Shipped (2) -> Delivered (4)
    
    final isActive = currentStep >= distinctStep;
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(int stepIndex, int currentStep) {
    // stepIndex: 0 (placed->confirmed), 1 (confirmed->shipped), 2 (shipped->delivered)
    // Thresholds: 1, 2, 4
    bool isActive = false;
    if (stepIndex == 0) isActive = currentStep >= 1;
    if (stepIndex == 1) isActive = currentStep >= 2;
    if (stepIndex == 2) isActive = currentStep >= 4;

    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.blue : Colors.grey[800],
      ),
    );
  }
}
