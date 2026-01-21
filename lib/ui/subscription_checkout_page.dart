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

  Color _getAccent() {
    if (widget.plan.tier?.toLowerCase() == 'premium' || widget.plan.name.toLowerCase().contains('premium')) {
      return const Color(0xFFFFD700);
    }
    return const Color(0xFF00E5FF);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final accentColor = _getAccent();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Confirm Membership', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildPlanSummary(p, accentColor),
          const SizedBox(height: 32),
          _buildSectionHeader('Contact Information'),
          const SizedBox(height: 16),
          _buildContactCard(accentColor),
          const SizedBox(height: 32),
          _buildSectionHeader('Preferences'),
          const SizedBox(height: 16),
          _buildPreferencesCard(accentColor),
          const SizedBox(height: 32),
          _buildSectionHeader('First Visit Scheduling'),
          const SizedBox(height: 16),
          _buildSchedulingCard(accentColor),
          const SizedBox(height: 32),
          _buildNotesSection(accentColor),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 40),
          _buildConfirmButton(accentColor),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2),
    );
  }

  Widget _buildPlanSummary(SubscriptionPlan p, Color accentColor) {
    final months = _periodMonths(p.billingPeriod);
    final symbol = _currencySymbol(p.currency);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: accentColor, size: 24),
              const SizedBox(width: 10),
              Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$symbol${p.price.toStringAsFixed(0)} / $months months', style: TextStyle(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${p.includedVisits} Visits', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Color accentColor) {
    final phone = AppState.phoneNumber;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          if (phone == null || phone.isEmpty)
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_android,
              accentColor: accentColor,
              type: TextInputType.phone,
            )
          else
            Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 12),
                Text(phone, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailCtrl,
            label: 'Email Address (Optional)',
            icon: Icons.email_outlined,
            accentColor: accentColor,
            type: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.autorenew_rounded, color: accentColor.withOpacity(0.6), size: 20),
              const SizedBox(width: 12),
              const Text('Auto-renew', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
          Switch(
            value: _autoRenew,
            activeColor: accentColor,
            onChanged: (v) => setState(() => _autoRenew = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Schedule first visit now?', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700))),
              Switch(value: _requestSchedule, activeColor: accentColor, onChanged: (v) => setState(() => _requestSchedule = v)),
            ],
          ),
          if (_requestSchedule) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildChoiceChip('At Shop', _location == 'shop', accentColor, () => setState(() => _location = 'shop')),
                const SizedBox(width: 12),
                _buildChoiceChip('At Home', _location == 'home', accentColor, () => setState(() => _location = 'home')),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPickerButton(
                    _date == null ? 'Select Date' : _date!.toString().split(' ').first,
                    Icons.calendar_today_rounded,
                    accentColor,
                    _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerButton(
                    _time == null ? 'Select Time' : _time!.format(context),
                    Icons.access_time_rounded,
                    accentColor,
                    _pickTime,
                  ),
                ),
              ],
            ),
            if (_location == 'home') ...[
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Service Address',
                icon: Icons.location_on_outlined,
                accentColor: accentColor,
                onChanged: (v) => _address = v,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(Color accentColor) {
    return _buildTextField(
      controller: _notesCtrl,
      label: 'Special Notes / Instructions',
      icon: Icons.note_alt_outlined,
      accentColor: accentColor,
      maxLines: 3,
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, Color accent, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.15) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? accent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? accent : Colors.white60, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildPickerButton(String label, IconData icon, Color accent, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent.withOpacity(0.7), size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
        prefixIcon: Icon(icon, color: accentColor.withOpacity(0.4), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentColor.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(Color accentColor) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        onPressed: _submitting ? null : _confirm,
        child: _submitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
            : const Text('ACTIVATE MEMBERSHIP', style: TextStyle(fontWeight: FontWeight.w950, fontSize: 16, letterSpacing: 1)),
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
    );
    if (res != null) setState(() => _date = res);
  }

  Future<void> _pickTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
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

      final sub = await SubscriptionApi().createSubscription(
        planId: widget.plan.id,
        contactPhone: phone,
        contactEmail: email.isNotEmpty ? email : null,
        autoRenew: _autoRenew,
      );

      await AppState.setLastCustomerPhone(phone);

      if (metadata.isNotEmpty) {
        try {
          await SubscriptionApi().updateSubscriptionMetadata(sub.id, metadata);
        } catch (_) {}
      }

      if (!mounted) return;
      _showSuccessDialog(phone);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog(String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Success!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(
          'Your ${widget.plan.name} has been activated for ${_periodMonths(widget.plan.billingPeriod)} months.\n\n'
          '${_requestSchedule && _date != null && _time != null ? 'Visit requested for: ${_date!.toString().split(' ').first} at ${_time!.format(context)}' : ''}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text('GREAT', style: TextStyle(color: _getAccent(), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  int _periodMonths(String period) {
    switch (period.toLowerCase()) {
      case 'quarterly': return 3;
      case 'half_yearly': return 6;
      case 'yearly':
      case 'annual': return 12;
      default: return 1;
    }
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR': return '₹';
      case 'USD': return '$';
      default: return '$currency';
    }
  }
}
