import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/staff_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/app_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';

class StaffDashboardPage extends ConsumerStatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  ConsumerState<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends ConsumerState<StaffDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(staffStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(staffStatsProvider);
              _refreshLists();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Center(
                child: Text(
                  'REPAIR MY BIKE\nOperations',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Logistics & Map'),
              onTap: () {
                Navigator.pop(context);
                context.push('/staff/logistics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Customer Directory (CRM)'),
              onTap: () {
                Navigator.pop(context);
                context.push('/staff/crm');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Cash Session (Daily)'),
              onTap: () {
                Navigator.pop(context);
                context.push('/staff/cash');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Cash Reconciliation'),
              onTap: () {
                Navigator.pop(context);
                context.push('/staff/reconciliation');
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                await AppState.clearAllData();
                if (!context.mounted) return;
                context.go('/');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Summary at Top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: statsAsync.when(
              data: (stats) {
                final bookingStats = stats['booking_status'] ?? {};
                return Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Today',
                        value: '${bookingStats['pending'] ?? 0}',
                        icon: Icons.new_releases_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Unpaid',
                        value: '${stats['payment_status']?['pending'] ?? 0}',
                        icon: Icons.payments_outlined,
                        color: Colors.red,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, stack) => Text('Error loading stats: $e'),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookingList(status: 'pending'),
                _BookingList(status: 'in_progress'),
                _BookingList(status: 'completed'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/staff/walk-in'),
        label: const Text('New Walk-in'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _refreshLists() {
    ref.invalidate(staffBookingsProvider('pending'));
    ref.invalidate(staffBookingsProvider('in_progress'));
    ref.invalidate(staffBookingsProvider('completed'));
  }
}

class _BookingList extends ConsumerWidget {
  final String status;

  const _BookingList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(staffBookingsProvider(status));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(staffBookingsProvider(status));
      },
      child: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return TaskCard(
                booking: booking,
                onTap: () {},
                onStatusUpdate: (newStatus) async {
                  await _updateStatus(context, ref, booking['id'], newStatus);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, int id, String status) async {
    try {
      final api = ref.read(staffApiProvider);
      final res = await api.updateBookingStatus(id, status);
      if (res['error'] == false) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking updated')),
        );
        // Refresh all lists and stats
        ref.invalidate(staffStatsProvider);
        ref.invalidate(staffBookingsProvider('pending'));
        ref.invalidate(staffBookingsProvider('confirmed'));
        ref.invalidate(staffBookingsProvider('in_progress'));
        ref.invalidate(staffBookingsProvider('completed'));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }
}
