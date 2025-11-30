import 'package:flutter/material.dart';
import '../models/subscription.dart';
import 'subscription_checkout_page.dart';

const accent = Color(0xFF00E5FF);
const cardColor = Color(0xFF222222);
const borderColor = Color(0xFF3B3B3B);

class MembershipDetailPage extends StatefulWidget {
  final String tierName; // "Basic Plan" or "Premium Plan"
  final List<SubscriptionPlan> options; // quarterly / half_yearly / yearly
  const MembershipDetailPage({super.key, required this.tierName, required this.options});

  @override
  State<MembershipDetailPage> createState() => _MembershipDetailPageState();
}

class _MembershipDetailPageState extends State<MembershipDetailPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ordered = _orderOptions(widget.options);
    if (selectedIndex >= ordered.length) selectedIndex = 0;
    final selected = ordered.isNotEmpty ? ordered[selectedIndex] : null;
    final currency = selected != null ? selected.currency : (ordered.isNotEmpty ? ordered.first.currency : 'INR');
    final symbol = _currencySymbol(currency);

    final services = _collectServices(ordered);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: Text(widget.tierName), backgroundColor: const Color(0xFF071A1D)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.tierName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Membership Plans', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Icon(Icons.workspace_premium, color: accent, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _summaryCard(selected ?? (ordered.isNotEmpty ? ordered.first : null), symbol),
            ),
            const SizedBox(height: 16),
            const Text('Select Plan Duration', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < ordered.length; i++)
                  _durationChip(
                    ordered[i],
                    i == selectedIndex,
                    symbol,
                    onTap: () {
                      setState(() => selectedIndex = i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _maxServicesBanner(selected),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: selected == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SubscriptionCheckoutPage(plan: selected)),
                        );
                      },
                child: const Text('Book Subscription', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Services', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...services.map((s) => _serviceRow(s)).toList(),
          ],
        ),
      ),
    );
  }

  List<SubscriptionPlan> _orderOptions(List<SubscriptionPlan> list) {
    final order = {"quarterly": 1, "half_yearly": 2, "yearly": 3, "annual": 3};
    final l = [...list];
    l.sort((a, b) => (order[a.billingPeriod.toLowerCase()] ?? 99)
        .compareTo(order[b.billingPeriod.toLowerCase()] ?? 99));
    return l;
  }

  List<String> _collectServices(List<SubscriptionPlan> list) {
    final set = <String>{};
    for (final p in list) {
      for (final s in p.services) {
        if (s.trim().isNotEmpty) set.add(s.trim());
      }
    }
    return set.toList();
  }

  Widget _summaryCard(SubscriptionPlan? p, String symbol) {
    if (p == null) return const SizedBox.shrink();
    final months = _periodMonths(p.billingPeriod);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Starting from', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$symbol${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    Text('/$months months', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B2E32),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.calendar_month, color: accent, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _durationChip(SubscriptionPlan p, bool highlighted, String symbol, {VoidCallback? onTap}) {
    final months = _periodMonths(p.billingPeriod);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFF0B2E32) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: highlighted ? accent : borderColor, width: highlighted ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$months months',
                style: TextStyle(color: highlighted ? Colors.white : Colors.white70, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('$symbol${p.price.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _maxServicesBanner(SubscriptionPlan? p) {
    if (p == null) return const SizedBox.shrink();
    final months = _periodMonths(p.billingPeriod);
    final visits = p.includedVisits;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2E32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Text('Max $visits service${visits == 1 ? '' : 's'} in $months months',
            style: const TextStyle(color: accent, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _planLine(SubscriptionPlan p, String symbol) {
    final label = _periodLabel(p.billingPeriod);
    final months = _periodMonths(p.billingPeriod);
    final visits = p.includedVisits;
    final priceText = '$symbol${p.price.toStringAsFixed(2)}';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('$label ($months months plan) : @$priceText',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          if (visits > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF0B2E32), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
              child: Text('Max $visits services', style: const TextStyle(color: accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _serviceRow(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return ' 24';
      case 'EUR':
        return '€';
      default:
        return currency;
    }
  }

  String _periodLabel(String p) {
    switch (p) {
      case 'quarterly':
        return 'Quarterly';
      case 'half_yearly':
        return 'Half yearly';
      case 'yearly':
      case 'annual':
        return 'Yearly';
      default:
        return p;
    }
  }

  int _periodMonths(String p) {
    switch (p) {
      case 'quarterly':
        return 3;
      case 'half_yearly':
        return 6;
      case 'yearly':
      case 'annual':
        return 12;
      default:
        return 0;
    }
  }
}
