import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../data/subscription_api.dart';
import '../data/app_state.dart';

const accent = Color(0xFF00E5FF);
const cardColor = Color(0xFF222222);
const borderColor = Color(0xFF3B3B3B);

class SubscriptionCheckoutPage extends StatefulWidget {
  final SubscriptionPlan plan;
  const SubscriptionCheckoutPage({super.key, required this.plan});

  @override
  State<SubscriptionCheckoutPage> createState() => _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _autoRenew = true;
  bool _requestSchedule = false;
  String _location = 'shop';
  DateTime? _date;
  TimeOfDay? _time;
  String _address = '';
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final savedPhone = AppState.phoneNumber;
    if (savedPhone != null && savedPhone.isNotEmpty) {
      _phoneCtrl.text = savedPhone;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text('Checkout'), backgroundColor: const Color(0xFF071A1D)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _planSummary(p),
          const SizedBox(height: 16),
          _contactSection(),
          const SizedBox(height: 16),
          _autoRenewRow(),
          const SizedBox(height: 16),
          _scheduleSection(),
          const SizedBox(height: 16),
          _notesSection(),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
              onPressed: _submitting ? null : _confirm,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Confirm Subscription', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planSummary(SubscriptionPlan p) {
    final months = _periodMonths(p.billingPeriod);
    final symbol = _currencySymbol(p.currency);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('₹${p.price.toStringAsFixed(0)} / $months months', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF0B2E32), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
            child: Text('Max ${p.includedVisits} services', style: const TextStyle(color: accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _contactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if ((AppState.phoneNumber ?? '').isEmpty)
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent))),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(AppState.phoneNumber ?? '', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Email (optional)', labelStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent))),
          ),
        ],
      ),
    );
  }

  Widget _autoRenewRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          const Expanded(child: Text('Auto-renew', style: TextStyle(color: Colors.white))),
          Switch(
            value: _autoRenew,
            activeColor: accent,
            onChanged: (v) => setState(() => _autoRenew = v),
          ),
        ],
      ),
    );
  }

  Widget _scheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Request schedule for first visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              Switch(value: _requestSchedule, activeColor: accent, onChanged: (v) => setState(() => _requestSchedule = v)),
            ],
          ),
          const SizedBox(height: 8),
          if (_requestSchedule) ...[
            Row(
              children: [
                ChoiceChip(
                  label: const Text('At Shop'),
                  selected: _location == 'shop',
                  selectedColor: const Color(0xFF0B2E32),
                  labelStyle: const TextStyle(color: Colors.white),
                  onSelected: (_) => setState(() => _location = 'shop'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('At Home'),
                  selected: _location == 'home',
                  selectedColor: const Color(0xFF0B2E32),
                  labelStyle: const TextStyle(color: Colors.white),
                  onSelected: (_) => setState(() => _location = 'home'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, color: accent),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: borderColor), foregroundColor: Colors.white),
                    onPressed: _pickDate,
                    label: Text(_date == null ? 'Pick date' : _date!.toString().split(' ').first),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, color: accent),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: borderColor), foregroundColor: Colors.white),
                    onPressed: _pickTime,
                    label: Text(_time == null ? 'Pick time' : _time!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_location == 'home')
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent))),
                onChanged: (v) => _address = v,
              ),
            const SizedBox(height: 8),
            const Text('Note: For a full booking, vehicle & service selection is required. We will contact you to finalize.', style: TextStyle(color: Colors.white54)),
          ],
        ],
      ),
    );
  }

  Widget _notesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes (optional)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Any preference, vehicle details, etc.', hintStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent))),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      initialDate: _date ?? now.add(const Duration(days: 1)),
      helpText: 'Select appointment date',
    );
    if (res != null) setState(() => _date = res);
  }

  Future<void> _pickTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Select appointment time',
    );
    if (res != null) setState(() => _time = res);
  }

  Future<void> _confirm() async {
    final phone = ((AppState.phoneNumber ?? '').trim().isNotEmpty)
        ? (AppState.phoneNumber ?? '').trim()
        : _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
      return;
    }
    setState(() { _submitting = true; _errorText = null; });
    final api = SubscriptionApi();
    try {
      final metadata = <String, dynamic>{};
      if (_requestSchedule && _date != null && _time != null) {
        final hh = _time!.hour.toString().padLeft(2, '0');
        final mm = _time!.minute.toString().padLeft(2, '0');
        metadata['schedule_request'] = {
          'service_location': _location,
          'appointment_date': _date!.toIso8601String().split('T').first,
          'appointment_time': '$hh:$mm:00',
          if (_address.isNotEmpty) 'address': _address,
          if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
        };
      } else if (_notesCtrl.text.trim().isNotEmpty) {
        metadata['notes'] = _notesCtrl.text.trim();
      }

      final sub = await api.createSubscription(
        planId: widget.plan.id,
        contactPhone: phone,
        contactEmail: email.isNotEmpty ? email : null,
        autoRenew: _autoRenew,
      );

      // Persist phone for future list lookups
      await AppState.setLastCustomerPhone(phone);

      // If we have a schedule request, update subscription metadata via PATCH.
      if (metadata.isNotEmpty) {
        try {
          await api.updateSubscriptionMetadata(sub.id, metadata);
        } catch (_) {
          // Non-blocking; show a gentle warning
        }
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Subscription Created'),
          content: Text('${widget.plan.name} for ${_periodMonths(widget.plan.billingPeriod)} months\n'
              'Phone: $phone\n'
              '${_requestSchedule && _date != null && _time != null ? 'Schedule requested: ${_date!.toString().split(' ').first} ${_time!.format(context)}' : ''}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int _periodMonths(String period) {
    switch (period.toLowerCase()) {
      case 'quarterly':
        return 3;
      case 'half_yearly':
        return 6;
      case 'yearly':
        return 12;
      default:
        return 1;
    }
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '4';
      default:
        return '';
    }
  }
}