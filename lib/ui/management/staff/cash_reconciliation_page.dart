import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/staff_provider.dart';
import '../widgets/status_chip.dart';

class CashReconciliationPage extends ConsumerWidget {
  const CashReconciliationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconciliationsAsync = ref.watch(pendingReconciliationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Reconciliation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingReconciliationsProvider),
          ),
        ],
      ),
      body: reconciliationsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('All cash handovers verified!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${payment['amount']}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              Text('Booking #${payment['booking_id']}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const StatusChip(status: 'collected'),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Held by: ${payment['handler_name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Collected on: ${payment['collected_at'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: () => _verifyHandover(context, ref, payment['id']),
                          icon: const Icon(Icons.verified_user_outlined),
                          label: const Text('Confirm Cash Receipt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _verifyHandover(BuildContext context, WidgetRef ref, int paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Handover'),
        content: const Text('Are you sure you have physically received this cash from the mechanic?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(staffApiProvider);
        final res = await api.verifyCash(paymentId);
        if (res['error'] == false) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cash verified and moved to register')));
          ref.invalidate(pendingReconciliationsProvider);
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
      }
    }
  }
}
