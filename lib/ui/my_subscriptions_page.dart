import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../utils/api_config.dart';

class MySubscriptionsPage extends ConsumerWidget {
  const MySubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubs = ref.watch(mySubscriptionsProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: const Color(0xFF071A1D),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.refresh(mySubscriptionsProvider);
        },
        child: asyncSubs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Failed to load subscriptions\n$err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
          data: (subs) {
             if (subs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.card_membership, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'No subscriptions found',
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
      case 'active': return Colors.greenAccent;
      case 'expired': return Colors.redAccent;
      case 'canceled': return Colors.orangeAccent;
      case 'pending': return Colors.amberAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);
    final planName = item.planName ?? 'Unknown Plan';
    final isPremium = planName.toLowerCase().contains('premium');
    
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPremium ? const Color(0xFF2C2C00) : const Color(0xFF002C33),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  isPremium ? Icons.workspace_premium : Icons.stars_rounded,
                  color: isPremium ? Colors.amber : Colors.cyanAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _RowItem(label: 'Start Date', value: formatDate(item.startDate)),
                const SizedBox(height: 8),
                _RowItem(label: 'End Date', value: formatDate(item.endDate)),
                const SizedBox(height: 8),
                if (item.remainingVisits > 0) ...[
                 _RowItem(label: 'Visits Remaining', value: '${item.remainingVisits}', highlight: true),
                 const SizedBox(height: 8),
                ],
                _RowItem(label: 'Visits Used', value: '${item.visitsConsumed}'),
              ],
            ),
          ),
          
          // Footer Actions (e.g. Cancel)
          if (item.isActive && item.status == 'active')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () {
                     // TODO: Implement cancel logic
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Cancel feature coming soon')),
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
