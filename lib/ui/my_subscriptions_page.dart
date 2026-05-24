import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../utils/app_error.dart';

class MySubscriptionsPage extends ConsumerWidget {
  const MySubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubs = ref.watch(mySubscriptionsProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('My Membership'),
        backgroundColor: const Color(0xFF071A1D),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.refresh(mySubscriptionsProvider);
        },
        child: asyncSubs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            final msg = AppError.sanitize(err, fallback: 'Failed to load subscriptions');
            final isAuthError = err.toString().contains('403') || err.toString().contains('401') || err.toString().contains('Authentication credentials were not provided');
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      Icon(isAuthError ? Icons.lock_outline : Icons.error_outline, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        isAuthError ? 'Session Expired' : 'Failed to load membership',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAuthError ? 'Please sign in again to view your membership.' : msg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      if (isAuthError)
                        ElevatedButton(
                          onPressed: () {
                             // Navigate away or logout
                             Navigator.of(context).pop(); 
                          },
                          child: const Text('Go Back'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => ref.refresh(mySubscriptionsProvider),
                          child: const Text('Retry'),
                        ),
                   ],
                ),
              ),
            );
          },
          data: (subs) {
             if (subs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.card_membership, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'No membership plans found',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () {
                        // Ideally navigate to "Buy Subscription" flow
                        // For now just pop back or stay
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('View Plans'),
                    )
                  ],
                ),
              );
            }
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: subs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _MySubscriptionCard(item: subs[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _MySubscriptionCard extends StatelessWidget {
  final SubscriptionItem item;
  const _MySubscriptionCard({required this.item});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFF00FFCC);
      case 'expired': return const Color(0xFFFF4D4D);
      case 'canceled': return const Color(0xFFFF9900);
      case 'pending': return const Color(0xFFFFCC00);
      default: return Colors.grey;
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final planName = item.planName ?? 'Quartly';
    final subId = item.id;
    final message = "Hello RepairMyBike! I'd like to pay for my $planName membership (ID: #$subId). Please share the payment Paytm QR code.";
    final url = "https://wa.me/918168121711?text=${Uri.encodeComponent(message)}";
    
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please message support at +91 81681 21711.')),
        );
      }
    }
  }

  Future<void> _callSupport(BuildContext context) async {
    final url = "tel:+918168121711";
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);
    final planName = item.planName ?? 'Unknown Plan';
    final isPremium = planName.toLowerCase().contains('premium');
    final isPending = item.status.toLowerCase() == 'pending';
    
    // Formatting dates
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return 'N/A';
      try {
        final dt = DateTime.parse(dateStr);
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (e) {
        return dateStr;
      }
    }

    final price = item.planDetails?.price;
    final billing = item.planDetails?.billingPeriod ?? 'monthly';
    final benefits = item.planDetails?.benefitsList ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending 
              ? const Color(0x33FFCC00) 
              : item.status.toLowerCase() == 'active' 
                  ? const Color(0x3300FFCC) 
                  : const Color(0xFF2A2A2A),
          width: 1.5,
        ),
        boxShadow: [
           BoxShadow(
            color: isPending 
                ? const Color(0x0FFFCC00) 
                : item.status.toLowerCase() == 'active' 
                    ? const Color(0x0F00FFCC) 
                    : Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isPremium ? const Color(0xFF2C2C00) : const Color(0xFF002C33),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(
                  isPremium ? Icons.workspace_premium : Icons.stars_rounded,
                  color: isPremium ? Colors.amber : Colors.cyanAccent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price Info
                if (price != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Plan Pricing',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        '₹${price.toStringAsFixed(0)} / ${billing.toLowerCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2A2A2A), height: 20),
                ],

                _RowItem(label: 'Start Date', value: formatDate(item.startDate)),
                const SizedBox(height: 10),
                _RowItem(label: 'End Date', value: formatDate(item.endDate)),
                const SizedBox(height: 10),
                if (item.remainingVisits > 0) ...[
                  _RowItem(label: 'Visits Remaining', value: '${item.remainingVisits}', highlight: true),
                  const SizedBox(height: 10),
                ],
                _RowItem(label: 'Visits Used', value: '${item.visitsConsumed}'),
                
                // Show benefits list if present
                if (benefits.isNotEmpty) ...[
                  const Divider(color: Color(0xFF2A2A2A), height: 24),
                  const Text(
                    'Included Benefits:',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...benefits.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline, 
                          color: b.isActive ? const Color(0xFF00FFCC) : Colors.white24, 
                          size: 16
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.text,
                            style: TextStyle(
                              color: b.isActive ? Colors.white70 : Colors.white30,
                              fontSize: 13,
                              decoration: b.isActive ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],

                // Pending Payment Box
                if (isPending) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x13FFCC00),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x33FFCC00)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payment_rounded, color: Color(0xFFFFCC00), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Required',
                              style: TextStyle(
                                color: const Color(0xFFFFCC00).withValues(alpha: 0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your membership is pending activation. Please pay in cash at the shop or complete UPI transfer via Paytm QR.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                label: const Text(
                                  'Pay via WhatsApp',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _launchWhatsApp(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFCC00),
                                  side: const BorderSide(color: Color(0x77FFCC00)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.phone_enabled_rounded, size: 16),
                                label: const Text(
                                  'Call Support',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _callSupport(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Active instructions
                if (item.status.toLowerCase() == 'active') ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x1300FFCC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x3300FFCC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF00FFCC), size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Book any service and select this active membership to redeem your free visits.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Footer Actions
          if (item.isActive && item.status == 'active')
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Please contact support at +91 81681 21711 to cancel your membership.')),
                     );
                  },
                  child: const Text('Cancel Subscription'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _RowItem({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.cyanAccent : Colors.white,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
