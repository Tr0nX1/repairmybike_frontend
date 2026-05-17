import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/staff_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';

class MechanicDashboardPage extends ConsumerWidget {
  const MechanicDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(staffStatsProvider);
    final bookingsAsync = ref.watch(staffBookingsProvider('in_progress')); // Show ongoing first
    final pendingAsync = ref.watch(staffBookingsProvider('confirmed'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanic Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(staffStatsProvider);
              ref.invalidate(staffBookingsProvider('in_progress'));
              ref.invalidate(staffBookingsProvider('confirmed'));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(staffStatsProvider);
          ref.invalidate(staffBookingsProvider('in_progress'));
          ref.invalidate(staffBookingsProvider('confirmed'));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Section
              statsAsync.when(
                data: (stats) {
                  final bookingStats = stats['booking_status'] ?? {};
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'In Progress',
                          value: '${bookingStats['in_progress'] ?? 0}',
                          icon: Icons.handyman_outlined,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Assigned Today',
                          value: '${bookingStats['confirmed'] ?? 0}',
                          icon: Icons.assignment_outlined,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => Text('Error: $e'),
              ),

              const SizedBox(height: 24),
              const Text(
                'My Current Jobs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Ongoing Tasks
              bookingsAsync.when(
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No jobs in progress'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return TaskCard(
                        booking: booking,
                        onTap: () => context.push('/mechanic/job/${booking['id']}'),
                        onStatusUpdate: (newStatus) async {
                          await _updateStatus(context, ref, booking['id'], newStatus);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => Text('Error: $e'),
              ),

              const SizedBox(height: 24),
              const Text(
                'New Assignments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Pending Tasks
              pendingAsync.when(
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No new assignments'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return TaskCard(
                        booking: booking,
                        onTap: () => context.push('/mechanic/job/${booking['id']}'),
                        onStatusUpdate: (newStatus) async {
                          await _updateStatus(context, ref, booking['id'], newStatus);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, int id, String status) async {
    try {
      final api = ref.read(staffApiProvider);
      final res = await api.updateBookingStatus(id, status);
      if (res['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
        // Refresh data
        ref.invalidate(staffStatsProvider);
        ref.invalidate(staffBookingsProvider('in_progress'));
        ref.invalidate(staffBookingsProvider('confirmed'));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }
}
