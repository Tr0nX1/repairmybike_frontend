import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import '../data/subscription_api.dart';
import 'subscription_detail_page.dart';
import 'membership_detail_page.dart';

// Helper available to both home section and full page
bool isPopularPlan(SubscriptionPlan plan, List<SubscriptionPlan> all) {
  final maxPrice = all.map((p) => p.price).fold<num>(0, (a, b) => a > b ? a : b);
  return plan.price == maxPrice;
}

class SubscriptionSection extends ConsumerWidget {
  const SubscriptionSection({super.key});

  static const Color cardColor = Color(0xFF1C1C1C);
  static const Color borderColor = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(subscriptionPlansProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Memberships',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        asyncPlans.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _errorBox('Failed to load subscriptions: ${err.toString()}'),
          data: (plans) {
            final filtered = plans.where((p) => _isMembershipPlan(p)).toList();
            if (filtered.isEmpty) {
              return const Text('No plans', style: TextStyle(color: Colors.white70));
            }
            final grouped = _groupMemberships(filtered);
            final entries = grouped.entries.toList();
            final width = MediaQuery.of(context).size.width;
            final crossAxisCount = width < 900 ? 2 : 2; // always two cards
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, i) {
                final e = entries[i];
                return _MembershipCard(
                  tierName: e.key,
                  options: e.value,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => MembershipDetailPage(tierName: e.key, options: e.value)),
                    );
                  },
                );
              },
            );
          },
        ),
        // Removed "View Plans" button to keep focus on two memberships
      ],
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(message, style: const TextStyle(color: Colors.redAccent)),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isPopular;
  const _SubscriptionCard({required this.plan, required this.isPopular});

  static const Color cardColor = Color(0xFF1C1C1C);
  static const Color borderColor = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  String _currencySymbol(String c) {
    switch (c.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return ''; // fallback, not expected
      default:
        return c;
    }
  }

  String _periodLabel(String p) {
    switch (p) {
      case 'monthly':
        return 'mo';
      case 'quarterly':
        return 'quarter';
      case 'half_yearly':
        return '6 mo';
      case 'yearly':
      case 'annual':
        return 'yr';
      default:
        return p;
    }
  }

  Color _accentForPlan() {
    final palette = <Color>[
      const Color(0xFF00E5FF), // cyan
      const Color(0xFF8A2BE2), // blue violet
      const Color(0xFFFFA726), // orange
      const Color(0xFF66BB6A), // green
      const Color(0xFFEF5350), // red
      const Color(0xFF42A5F5), // blue
    ];
    final idx = (plan.id % palette.length).abs();
    return palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _currencySymbol(plan.currency);
    final accentColor = _accentForPlan();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SubscriptionDetailPage(plan: plan)),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPopular ? accentColor : borderColor, width: isPopular ? 2 : 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C1C1C),
              accentColor.withOpacity(0.25),
            ],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor),
                    ),
                    child: Text('Popular', style: TextStyle(color: accentColor, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$symbol${plan.price.toStringAsFixed(2)}',
              style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            // Intentionally removed extra details to keep only name and price
          ],
        ),
      ),
    );
  }

  String _firstBenefit(Map<String, dynamic> benefits) {
    if (benefits.isEmpty) return 'Includes ${plan.includedVisits} visits';
    final entries = benefits.entries.toList();
    if (entries.isEmpty) return 'Includes ${plan.includedVisits} visits';
    final k = entries.first.key;
    final v = entries.first.value;
    return '$k: $v';
  }
}

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  static const Color bg = Color(0xFF0F0F0F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(subscriptionPlansProvider);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Subscriptions'), backgroundColor: const Color(0xFF071A1D)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncPlans.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load: ${e.toString()}', style: const TextStyle(color: Colors.redAccent))),
          data: (plans) {
            final titles = plans.map((p) => _shortTitle(p)).toList();
            return _TwoColumnTitles(titles: titles);
          },
        ),
      ),
    );
  }
}

String _shortTitle(SubscriptionPlan p) {
  String period;
  switch (p.billingPeriod) {
    case 'monthly':
      period = 'Monthly';
      break;
    case 'quarterly':
      period = 'Quarterly';
      break;
    case 'half_yearly':
      period = 'Half Yearly';
      break;
    case 'yearly':
    case 'annual':
      period = 'Yearly';
      break;
    default:
      period = p.billingPeriod;
  }
  return '${p.name} $period';
}

bool _isMembershipPlan(SubscriptionPlan p) {
  final slug = (p.slug).toLowerCase();
  final name = p.name.toLowerCase();
  final allowedPeriods = ['quarterly', 'half_yearly', 'yearly'];
  final isAllowedPeriod = allowedPeriods.contains(p.billingPeriod.toLowerCase());
  final tier = (p.tier ?? '').toLowerCase();
  final isBasicTier = tier == 'basic';
  final isPremiumTier = tier == 'premium';
  final isBasicText = slug.contains('basic') || name.contains('basic');
  final isPremiumText = slug.contains('premium') || name.contains('premium');
  return isAllowedPeriod && (isBasicTier || isPremiumTier || isBasicText || isPremiumText);
}

Map<String, List<SubscriptionPlan>> _groupMemberships(List<SubscriptionPlan> filtered) {
  final Map<String, List<SubscriptionPlan>> grouped = {};
  for (final p in filtered) {
    final t = (p.tier ?? '').toLowerCase();
    String key;
    if (t == 'basic') {
      key = 'Basic Membership';
    } else if (t == 'premium') {
      key = 'Premium Membership';
    } else if (p.name.toLowerCase().contains('basic')) {
      key = 'Basic Membership';
    } else if (p.name.toLowerCase().contains('premium')) {
      key = 'Premium Membership';
    } else {
      key = p.name.trim();
    }
    grouped.putIfAbsent(key, () => []);
    grouped[key]!.add(p);
  }
  // Ensure ordering: Basic then Premium if present
  final keys = grouped.keys.toList();
  keys.sort((a, b) => a.toLowerCase().contains('basic') ? -1 : a.toLowerCase().contains('premium') ? 1 : 0);
  final ordered = <String, List<SubscriptionPlan>>{};
  for (final k in keys) {
    ordered[k] = grouped[k]!..sort((a, b) => a.billingPeriod.compareTo(b.billingPeriod));
  }
  return ordered;
}

String _currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'INR':
      return '₹';
    case 'USD':
      return '\u000024';
    case 'EUR':
      return '€';
    default:
      return currency;
  }
}

class _MembershipCard extends StatelessWidget {
  final String tierName;
  final List<SubscriptionPlan> options;
  final VoidCallback onTap;
  const _MembershipCard({required this.tierName, required this.options, required this.onTap});

  static const Color accent = Color(0xFF01C9F5);

  LinearGradient _getGradient(String name) {
    if (name.toLowerCase().contains('premium')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF071A1D), Color(0xFF0D3D44)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
    );
  }

  Color _getAccent(String name) {
    if (name.toLowerCase().contains('premium')) {
      return const Color(0xFFFFD700); // Gold for premium
    }
    return const Color(0xFF00E5FF); // Cyan for basic
  }

  @override
  Widget build(BuildContext context) {
    final prices = options.map((o) => o.price).toList();
    final minPrice = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b);
    final currency = options.isNotEmpty ? options.first.currency : 'INR';
    final planSymbol = _currencySymbol(currency);
    final plan = options.first;
    final accentColor = _getAccent(tierName);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
          gradient: _getGradient(tierName),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.workspace_premium,
                size: 100,
                color: accentColor.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.stars_rounded, color: accentColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tierName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STARTS AT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            planSymbol,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            minPrice.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ONLY',
                            style: TextStyle(
                              color: accentColor.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoColumnTitles extends StatelessWidget {
  final List<String> titles;
  const _TwoColumnTitles({required this.titles});

  @override
  Widget build(BuildContext context) {
    final left = <String>[];
    final right = <String>[];
    for (var i = 0; i < titles.length; i++) {
      (i % 2 == 0 ? left : right).add(titles[i]);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _titleColumn(left)),
          const SizedBox(width: 12),
          Expanded(child: _titleColumn(right)),
        ],
      ),
    );
  }

  Widget _titleColumn(List<String> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in list)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              t,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
