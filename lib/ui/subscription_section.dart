import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';


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
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.9,
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
  final allowedPeriods = ['monthly', 'quarterly', 'half_yearly', 'yearly'];
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

  Color _getAccent(String name) {
    if (name.toLowerCase().contains('premium')) {
      return const Color(0xFFFFD700); // Gold for premium
    }
    return const Color(0xFF00E5FF); // Cyan for basic
  }

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

  @override
  Widget build(BuildContext context) {
    final prices = options.map((o) => o.price).toList();
    final minPrice = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b);
    final currency = options.isNotEmpty ? options.first.currency : 'INR';
    final planSymbol = _currencySymbol(currency);
    final accentColor = _getAccent(tierName);
    
    // Header shape concept:
    // A ticket shape with inward arcs at the top corners or sides.
    // User requested "rectangular with half circle corner kind of UI (_____)"
    // Typically this means an inverted rounded corner at the top.

    return InkWell(
      onTap: onTap,
      child: ClipPath(
        clipper: _TicketHeaderClipper(radius: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _getGradient(tierName),
            border: Border(
               // Simulated border via container nesting or CustomPainter is complex. 
               // For now, simple border on the unclipped sides via container decoration won't work perfectly with ClipPath.
               // We will rely on the gradient and inner content for style.
            ),
          ),
          child: Stack(
            children: [
               // Border Painter to draw the outline on the clipped path
               Positioned.fill(
                 child: CustomPaint(
                    painter: _TicketBorderPainter(radius: 20, color: accentColor.withValues(alpha: 0.3), width: 1.5),
                 ),
               ),
              
              // Decorative Icon Pattern
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  Icons.workspace_premium,
                  size: 70,
                  color: accentColor.withValues(alpha: 0.08),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Header
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: accentColor.withValues(alpha: 0.1), blurRadius: 8),
                        ],
                      ),
                      child: Icon(
                        tierName.toLowerCase().contains('premium') ? Icons.auto_awesome : Icons.stars_rounded, 
                        color: accentColor, 
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      tierName.toUpperCase(),
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Dashed Line Divider
                    Row(
                      children: List.generate(
                        10, 
                        (index) => Expanded(
                          child: Container(
                            height: 1, 
                            color: Colors.white10, 
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Price Footer
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STARTS AT',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                             Text(
                              planSymbol,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              minPrice.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
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
      ),
    );
  }
}

class _TicketHeaderClipper extends CustomClipper<Path> {
  final double radius;
  _TicketHeaderClipper({this.radius = 20});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, radius);
    
    // Top Left Corner (Inverted arc? Or standard rounded?)
    // User asked for "half circle corner kind of UI (_____)". 
    // This usually means Top Left and Top Right have concave cutouts OR overly rounded convential corners.
    // Let's implement Top Left/Right as large rounded corners (Standard) and Bottoms as standard, 
    // BUT usually "ticket" implies a cutout. 
    // Reviewing user request: "rectangular with half circle corner kind of UI (____________) (_________)"
    // This likely refers to the "Tab" shape or "Inverted Rounded" where the top edge dips or the corners are concave.
    // Let's go with Concave Cutout at Top Left and Top Right.
    
    // Start Top Left
    path.lineTo(0, size.height - radius);
    path.quadraticBezierTo(0, size.height, radius, size.height); // Bottom Left Rounded
    path.lineTo(size.width - radius, size.height); 
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - radius); // Bottom Right Rounded
    path.lineTo(size.width, radius);
    
    // Top Right Cutout (Concave)
    path.arcToPoint(
      Offset(size.width - radius, 0),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    
    path.lineTo(radius, 0);
    
    // Top Left Cutout (Concave)
    path.arcToPoint(
      Offset(0, radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class _TicketBorderPainter extends CustomPainter {
  final double radius;
  final Color color;
  final double width;
  
  _TicketBorderPainter({required this.radius, required this.color, this.width = 1.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
      
    final path = Path();
    path.moveTo(0, radius);
    
    path.lineTo(0, size.height - radius);
    path.quadraticBezierTo(0, size.height, radius, size.height);
    path.lineTo(size.width - radius, size.height);
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - radius);
    path.lineTo(size.width, radius);
    
    path.arcToPoint(Offset(size.width - radius, 0), radius: Radius.circular(radius), clockwise: false);
    path.lineTo(radius, 0);
    path.arcToPoint(Offset(0, radius), radius: Radius.circular(radius), clockwise: false);
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
