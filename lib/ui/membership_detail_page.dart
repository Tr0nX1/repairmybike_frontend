import 'package:flutter/material.dart';
import '../models/subscription.dart';
import 'subscription_checkout_page.dart';
import '../data/app_state.dart';
import 'widgets/login_required_dialog.dart';

const accent = Color(0xFF00E5FF);
const cardColor = Color(0xFF222222);
const borderColor = Color(0xFF3B3B3B);

class MembershipDetailPage extends StatefulWidget {
  final String tierName; // "Basic Membership" or "Premium Membership"
  final List<SubscriptionPlan> options; // quarterly / half_yearly / yearly
  const MembershipDetailPage({super.key, required this.tierName, required this.options});

  @override
  State<MembershipDetailPage> createState() => _MembershipDetailPageState();
}

class _MembershipDetailPageState extends State<MembershipDetailPage> {
  int selectedIndex = 0;

  Color _getAccent() {
    if (widget.tierName.toLowerCase().contains('premium')) {
      return const Color(0xFFFFD700);
    }
    return const Color(0xFF00E5FF);
  }

  LinearGradient _getBgGradient() {
    if (widget.tierName.toLowerCase().contains('premium')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF071A1D), Color(0xFF0F0F0F)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0A0A0A), Color(0xFF0F0F0F)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _orderOptions(widget.options);
    if (selectedIndex >= ordered.length) selectedIndex = 0;
    final selected = ordered.isNotEmpty ? ordered[selectedIndex] : null;
    final accentColor = _getAccent();

    Future.microtask(() async {
      if (AppState.isAuthenticated) {
        final action = await AppState.takePendingAction();
        if (action != null && action['type'] == 'subscribe' && selected != null) {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SubscriptionCheckoutPage(plan: selected),
            ),
          );
        }
      }
    });

    final currency = selected?.currency ?? 'INR';
    final symbol = _currencySymbol(currency);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Container(
        decoration: BoxDecoration(gradient: _getBgGradient()),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(accentColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(selected, accentColor),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Choose Duration'),
                    const SizedBox(height: 16),
                    _buildDurationGrid(ordered, symbol, accentColor),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Plan Benefits'),
                    const SizedBox(height: 16),
                    _buildBenefitsList(selected, accentColor),
                    const SizedBox(height: 32),
                    if (selected?.includedServicesDetails.isNotEmpty ?? false) ...[
                      _buildSectionHeader('Included Services'),
                      const SizedBox(height: 16),
                      _buildServicesGrid(selected!, accentColor),
                      const SizedBox(height: 32),
                    ],
                    _buildCTAButton(selected, accentColor),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(Color accentColor) {
    return SliverAppBar(
      expandedHeight: 0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      title: Text(
        widget.tierName,
        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeroSection(SubscriptionPlan? selected, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium, color: accentColor, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            selected?.name ?? widget.tierName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selected?.description ?? 'Premium maintenance for your bike',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildDurationGrid(List<SubscriptionPlan> ordered, String symbol, Color accentColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: ordered.length,
      itemBuilder: (context, i) {
        final p = ordered[i];
        final isSelected = i == selectedIndex;
        final months = _periodMonths(p.billingPeriod);

        return InkWell(
          onTap: () => setState(() => selectedIndex = i),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.15) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? accentColor : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$months Months',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  child: Text(
                    '$symbol${p.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isSelected ? accentColor : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitsList(SubscriptionPlan? selected, Color accentColor) {
    if (selected == null || selected.benefitsList.isEmpty) {
      return const Text('No benefits listed', style: TextStyle(color: Colors.white38));
    }

    return Column(
      children: selected.benefitsList.map((benefit) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(
                benefit.isActive ? Icons.check_circle : Icons.remove_circle_outline,
                color: benefit.isActive ? accentColor : Colors.white24,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  benefit.text,
                  style: TextStyle(
                    color: benefit.isActive ? Colors.white : Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: benefit.isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServicesGrid(SubscriptionPlan selected, Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: selected.includedServicesDetails.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.build_circle_outlined, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Text(
                s.name,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCTAButton(SubscriptionPlan? selected, Color accentColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: selected == null
            ? null
            : () async {
                if (!AppState.isAuthenticated) {
                  await AppState.setPendingAction({'type': 'subscribe'});
                  if (context.mounted) {
                    await showLoginRequiredDialog(context);
                  }
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SubscriptionCheckoutPage(plan: selected)),
                );
              },
        child: const Text(
          'ACTIVATE MEMBERSHIP',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
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

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      default: return currency;
    }
  }

  int _periodMonths(String p) {
    switch (p.toLowerCase()) {
      case 'quarterly': return 3;
      case 'half_yearly': return 6;
      case 'yearly':
      case 'annual': return 12;
      default: return 0;
    }
  }
}
