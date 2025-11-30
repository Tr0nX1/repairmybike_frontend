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
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  final _phoneCtrl = TextEditingController();
  final _bookingApi = BookingApi();
  bool _loading = false;
  List<Map<String, dynamic>> _bookings = [];
  // Future sections: subscription and spare parts bookings. These will be
  // populated when corresponding APIs are available. For now, only services
  // bookings are shown, and section dividers appear conditionally.
  List<Map<String, dynamic>> _subscriptionBookings = [];
  List<Map<String, dynamic>> _sparePartsBookings = [];
  Timer? _autoRefreshTimer;
  DateTime? _backoffUntil;

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
      final items = await _bookingApi.getBookingsByPhone(
        phone,
        sessionToken: AppState.sessionToken,
      );
      setState(() => _bookings = items);
      await _loadSparePartsOrders();
      // NOTE: When subscription/spare parts endpoints are added, fetch and
      // assign to _subscriptionBookings and _sparePartsBookings similarly.
      // Start/refresh auto polling after a successful search.
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

  Future<void> _loadSparePartsOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id_v1');
      if (sessionId == null || sessionId.isEmpty) {
        setState(() => _sparePartsBookings = []);
        return;
      }
      final api = OrderApi();
      final orders = await api.listOrders(sessionId: sessionId);
      final mapped = orders
          .map(
            (o) => {
              'id': o.id,
              'total_amount': o.total,
              'booking_status': o.status,
              'payment_status': o.paymentStatus,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': null,
              'customer': {'name': o.customerName},
              'services': o.items.map((i) => {'name': i.name}).toList(),
              'service_location': 'processing',
              'appointment_date': null,
              'appointment_time': null,
            },
          )
          .toList();
      setState(() => _sparePartsBookings = mapped);
    } catch (e) {
      // Ignore; just don’t show spare parts section on failure
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
      children.add(_sectionDivider('Request for Services Booking'));
      children.add(const SizedBox(height: 12));
      for (final b in _bookings) {
        children.add(_bookingCard(b));
        children.add(const SizedBox(height: 12));
      }
    }
    if (hasSubscriptions) {
      children.add(_sectionDivider('Request for Subscription Booking'));
      children.add(const SizedBox(height: 12));
      for (final b in _subscriptionBookings) {
        children.add(_bookingCard(b));
        children.add(const SizedBox(height: 12));
      }
    }
    if (hasSpareParts) {
      children.add(_sectionDivider('Request for Spare Parts Booking'));
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

  // Unified booking card renderer used by all sections.
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

    final requestedLine = 'Requested: ${_fmtDateTime(createdAt)}';
    final updatedLine = (updatedAt != null && updatedAt.toString().isNotEmpty)
        ? 'Updated: ${_fmtDateTime(updatedAt)}'
        : '';
    final scheduleLine = (apptDate != null || apptTime != null)
        ? 'Schedule: ${_fmtDate(apptDate)}${apptTime != null ? ' · ${_fmtTime(apptTime)}' : ''}'
        : '';
    final locationLine = location.isNotEmpty
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
                  'Booking #$id',
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
              _chip('services: ${services.length}', Colors.white54),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
    // Only load when authenticated; no manual phone entry allowed.
    final authPhone = AppState.phoneNumber;
    if (authPhone != null && authPhone.isNotEmpty) {
      _phoneCtrl.text = authPhone;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
      _startAutoRefresh();
    }
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
