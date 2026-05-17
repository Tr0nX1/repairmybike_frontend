import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/staff_provider.dart';
import '../widgets/stat_card.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(staffStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(staffStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final bookingStats = stats['booking_status'] ?? {};
          final paymentStats = stats['payment_status'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Health',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      title: 'Total Bookings',
                      value: '${stats['total_bookings'] ?? 0}',
                      icon: Icons.analytics_outlined,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Completed',
                      value: '${bookingStats['completed'] ?? 0}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    StatCard(
                      title: 'Revenue (Approx)',
                      value: '₹${(bookingStats['completed'] ?? 0) * 1200}', // Mock calculation
                      icon: Icons.currency_rupee,
                      color: Colors.green,
                    ),
                    StatCard(
                      title: 'Pending Payout',
                      value: '${paymentStats['pending'] ?? 0}',
                      icon: Icons.history_outlined,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 32),
                const Text(
                  'Booking Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 20,
                      barGroups: [
                        _makeGroupData(0, (bookingStats['pending'] ?? 0).toDouble(), Colors.orange),
                        _makeGroupData(1, (bookingStats['confirmed'] ?? 0).toDouble(), Colors.blue),
                        _makeGroupData(2, (bookingStats['in_progress'] ?? 0).toDouble(), Colors.purple),
                        _makeGroupData(3, (bookingStats['completed'] ?? 0).toDouble(), Colors.green),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const labels = ['Pnd', 'Cnf', 'Prog', 'Done'];
                              if (value.toInt() < labels.length) {
                                return Text(labels[value.toInt()], style: const TextStyle(fontSize: 10));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _ActionTile(
          icon: Icons.people_alt_outlined,
          label: 'Staff Directory',
          onTap: () => context.push('/admin/staff'),
        ),
        _ActionTile(
          icon: Icons.settings_applications_outlined,
          label: 'App CMS',
          onTap: () => context.push('/admin/cms'),
        ),
        _ActionTile(
          icon: Icons.payments_outlined,
          label: 'Service Pricing',
          onTap: () => context.push('/admin/pricing'),
        ),
        _ActionTile(
          icon: Icons.inventory_2_outlined,
          label: 'Full Inventory',
          onTap: () => context.push('/admin/inventory'),
        ),
        _ActionTile(
          icon: Icons.history_edu_outlined,
          label: 'System Audit Logs',
          onTap: () => context.push('/admin/audit-logs'),
        ),
      ],
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
