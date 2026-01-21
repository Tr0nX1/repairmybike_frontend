import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../data/subscription_api.dart';
import '../data/app_state.dart';

const accent = Color(0xFF00E5FF);
const cardColor = Color(0xFF222222);
const borderColor = Color(0xFF3B3B3B);

class SubscriptionDetailPage extends StatefulWidget {
  final SubscriptionPlan plan;
  const SubscriptionDetailPage({super.key, required this.plan});

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;
  bool _loadingExisting = false;
  List<SubscriptionItem>? _existing;
  String? _errorText;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final phone = AppState.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      _phoneCtrl.text = phone;
    }
  }

  Color _getAccent() {
    if (widget.plan.tier?.toLowerCase() == 'premium' || widget.plan.name.toLowerCase().contains('premium')) {
      return const Color(0xFFFFD700);
    }
    return const Color(0xFF00E5FF);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final accentColor = _getAccent();
    final symbol = _currencySymbol(plan.currency);
    final period = _periodLabel(plan.billingPeriod);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0F0F0F),
            expandedHeight: 0,
            title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w900)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor.withOpacity(0.15), Colors.white.withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accentColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.stars_rounded, color: accentColor, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          plan.name,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(symbol, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w900)),
                            Text(
                              plan.price.toStringAsFixed(0),
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 4),
                            Text('/$period', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Plan Features'),
                  const SizedBox(height: 16),
                  _buildBenefitsList(plan, accentColor),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Subscribe Details'),
                  const SizedBox(height: 16),
                  _buildSubscriptionForm(accentColor),
                  const SizedBox(height: 32),
                  _buildExistingCheck(accentColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.2),
    );
  }

  Widget _buildBenefitsList(SubscriptionPlan plan, Color accentColor) {
    final benefits = plan.benefitsList;
    if (benefits.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white38, size: 18),
            const SizedBox(width: 10),
            Text('Includes ${plan.includedVisits} service visits', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Column(
      children: benefits.map((b) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: b.isActive ? accentColor : Colors.white24, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                b.text,
                style: TextStyle(
                  color: b.isActive ? Colors.white : Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: b.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSubscriptionForm(Color accentColor) {
    final phone = AppState.phoneNumber;
    final hasPhone = phone != null && phone.isNotEmpty;

    return Column(
      children: [
        if (!hasPhone)
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Contact Phone Number',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(Icons.phone_android, color: accentColor.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: accentColor, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subscribing as', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w700)),
                    Text(phone, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            onPressed: (AppState.isAuthenticated && !_submitting) ? () => _subscribe(widget.plan) : null,
            child: _submitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : const Text('CONFIRM SUBSCRIPTION', style: TextStyle(fontWeight: FontWeight.w950, fontSize: 15, letterSpacing: 0.5)),
          ),
        ),
        if (!AppState.isAuthenticated) ...[
          const SizedBox(height: 12),
          Center(child: Text('Login required to subscribe', style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontWeight: FontWeight.w700))),
        ],
      ],
    );
  }

  Widget _buildExistingCheck(Color accentColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text('Already have a subscription?', style: TextStyle(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600))),
            TextButton(
              onPressed: _loadingExisting ? null : _loadExistingByPhone,
              child: _loadingExisting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Check Status', style: TextStyle(color: accentColor, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        if (_existing != null) ...[
          const SizedBox(height: 12),
          ..._existing!.map((s) => _buildExistingItem(s, accentColor)).toList(),
        ],
      ],
    );
  }

  Widget _buildExistingItem(SubscriptionItem s, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white38, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(s.planName ?? 'Plan #${s.planId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s.isActive ? 'ACTIVE' : 'EXPIRED', style: TextStyle(color: s.isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Status', s.status, accentColor),
          _infoRow('Visits Remaining', '${s.remainingVisits}', accentColor),
          if (s.endDate != null) _infoRow('Expires', s.endDate!.split('T')[0], accentColor),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final phone = (AppState.phoneNumber ?? _phoneCtrl.text.trim());
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      final sub = await SubscriptionApi().createSubscription(planId: plan.id, contactPhone: phone);
      if (!mounted) return;
      _showSuccessSheet(sub);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString().contains('Exception: ') ? e.toString().split('Exception: ')[1] : e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _loadExistingByPhone() async {
    final phone = (AppState.phoneNumber ?? _phoneCtrl.text.trim());
    if (phone.isEmpty) {
      setState(() => _errorText = 'Enter a phone to check subscriptions');
      return;
    }
    setState(() {
      _loadingExisting = true;
      _errorText = null;
    });
    try {
      final items = await SubscriptionApi().getSubscriptionsByPhone(phone);
      if (!mounted) return;
      setState(() => _existing = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to fetch: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  void _showSuccessSheet(SubscriptionItem sub) {
    final accentColor = _getAccent();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Subscription Activated!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _infoRow('Status', sub.status, accentColor),
            _infoRow('Visits Remaining', '${sub.remainingVisits}', accentColor),
            if (sub.endDate != null) _infoRow('End Date', sub.endDate!.split('T')[0], accentColor),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w950)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currencySymbol(String? code) {
    switch (code?.toUpperCase()) {
      case 'INR': return '₹';
      case 'USD': return '$';
      default: return '$code';
    }
  }

  String _periodLabel(String? period) {
    switch (period?.toLowerCase()) {
      case 'monthly': return 'month';
      case 'half_yearly': return '6 mo';
      case 'yearly':
      case 'annual': return 'year';
      default: return 'period';
    }
  }
}

Widget _infoRow(String label, String value, Color accentColor) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

Widget _benefitsChips(List<Benefit> benefitsList, int includedVisits, Color accentColor) {
  if (benefitsList.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: accentColor.withOpacity(0.5), size: 18),
          const SizedBox(width: 10),
          Text('Includes $includedVisits visits per period', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
  return Column(
    children: benefitsList.map((b) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: b.isActive ? accentColor : Colors.white24, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(b.text, style: TextStyle(color: b.isActive ? Colors.white : Colors.white38, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    )).toList(),
  );
}

Widget _existingList(List<SubscriptionItem> items, Color accentColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items.map((s) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.history_edu_rounded, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.planName ?? 'Active Plan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(s.status.toUpperCase(), style: TextStyle(color: s.isActive ? Colors.greenAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.1))),
                child: Text('${s.remainingVisits} Visits Left', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          _infoRow('Started On', s.startDate.split('T')[0], accentColor),
          if (s.endDate != null) _infoRow('Expiry Date', s.endDate!.split('T')[0], accentColor),
          _infoRow('Auto-renew', s.autoRenew ? 'Enabled' : 'Disabled', accentColor),
        ],
      ),
    )).toList(),
  );
}

String _currencySymbol(String? code) {
  switch (code?.toUpperCase()) {
    case 'INR': return '₹';
    case 'USD': return '$';
    default: return '$code';
  }
}

String _periodLabel(String? period) {
  switch (period?.toLowerCase()) {
    case 'monthly': return 'month';
    case 'half_yearly': return '6 mo';
    case 'yearly':
    case 'annual': return 'year';
    default: return 'period';
  }
}
