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

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final symbol = _currencySymbol(plan.currency);
    final period = _periodLabel(plan.billingPeriod);
    return Scaffold(
      appBar: AppBar(title: Text(plan.name), backgroundColor: Colors.black),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient, price and period
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF004E57), Color(0xFF0A1F22), Color(0xFF111111)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFF0B2E32), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                              child: Text('$symbol${plan.price.toStringAsFixed(2)}/$period', style: const TextStyle(color: accent, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 8),
                            if (plan.includedVisits > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                                child: Text('${plan.includedVisits} visits', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.subscriptions, color: accent, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Benefits', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _benefitsChips(plan.benefits, plan.includedVisits),
            const SizedBox(height: 24),
            const Text('Subscribe', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if ((AppState.phoneNumber ?? '').isEmpty)
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter contact phone',
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accent)),
                ),
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
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
                onPressed: _submitting ? null : () => _subscribe(plan),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Confirm Subscription', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Check existing subscriptions by phone', style: const TextStyle(color: Colors.white70)),
                ),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: accent, side: const BorderSide(color: accent)),
                    onPressed: _loadingExisting ? null : _loadExistingByPhone,
                    child: _loadingExisting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Check'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_existing != null) _existingList(_existing!),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final phone = (AppState.phoneNumber ?? _phoneCtrl.text.trim());
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
      return;
    }
    setState(() => _submitting = true);
    final api = SubscriptionApi();
    try {
      final sub = await api.createSubscription(planId: plan.id, contactPhone: phone);
      if (!mounted) return;
      _showResponseSheet(sub);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed: ${e.toString()}');
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
    final api = SubscriptionApi();
    try {
      final items = await api.getSubscriptionsByPhone(phone);
      if (!mounted) return;
      setState(() => _existing = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to fetch: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  void _showResponseSheet(SubscriptionItem sub) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle, color: accent),
                  SizedBox(width: 8),
                  Text('Subscription Created', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('Status', sub.status),
              _infoRow('Remaining visits', '${sub.remainingVisits}'),
              if (sub.nextBillingDate != null && sub.nextBillingDate!.isNotEmpty)
                _infoRow('Next billing', sub.nextBillingDate!),
              if (sub.autoRenew) _infoRow('Auto-renew', 'Enabled'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0B2E32),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(label, style: const TextStyle(color: accent, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
      ],
    ),
  );
}

Widget _benefitsChips(Map<String, dynamic> benefits, int includedVisits) {
  final entries = benefits.entries.toList();
  if (entries.isEmpty) {
    entries.add(MapEntry('Visits', includedVisits > 0 ? '$includedVisits included' : 'Unlimited'));
  }
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: entries
        .map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: accent, size: 16),
                  const SizedBox(width: 6),
                  Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ))
        .toList(),
  );
}

Widget _existingList(List<SubscriptionItem> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map((s) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.planName ?? 'Plan #${s.planId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.isActive ? const Color(0xFF103B2A) : const Color(0xFF3B1010),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(s.isActive ? 'Active' : 'Inactive', style: TextStyle(color: s.isActive ? Colors.greenAccent : Colors.redAccent)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF0B2E32), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                          child: Text(s.status, style: const TextStyle(color: accent)),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Remaining visits', '${s.remainingVisits}'),
                  if (s.nextBillingDate != null && s.nextBillingDate!.isNotEmpty)
                    _infoRow('Next billing', s.nextBillingDate!),
                  if (s.endDate != null && s.endDate!.isNotEmpty)
                    _infoRow('End date', s.endDate!),
                ],
              ),
            ))
        .toList(),
  );
}

String _currencySymbol(String? code) {
  switch (code?.toUpperCase()) {
    case 'INR':
      return '₹';
    case 'USD':
      return '\$';
    default:
      return '';
  }
}

String _periodLabel(String? period) {
  switch (period?.toLowerCase()) {
    case 'monthly':
      return 'month';
    case 'yearly':
      return 'year';
    default:
      return 'period';
  }
}
