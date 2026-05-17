import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/staff_provider.dart';
import '../widgets/stat_card.dart';

class FinancialDashboardPage extends ConsumerWidget {
  const FinancialDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(staffStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue & Payments'),
      ),
      body: statsAsync.when(
        data: (stats) {
          final paymentStats = stats['payment_status'] ?? {};
          final bookingStats = stats['booking_status'] ?? {};
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Revenue',
                        value: '₹1.85L',
                        icon: Icons.account_balance,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Cash in Hand',
                        value: '₹42,300',
                        icon: Icons.payments,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Weekly Revenue Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildRevenueChart(context),
                const SizedBox(height: 32),
                const Text(
                  'Payment Status Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPaymentTable(context, paymentStats, bookingStats),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() < days.length) {
                    return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 4),
                FlSpot(2, 3.5),
                FlSpot(3, 5),
                FlSpot(4, 4),
                FlSpot(5, 6),
                FlSpot(6, 5.5),
              ],
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTable(BuildContext context, Map paymentStats, Map bookingStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _RowItem(label: 'Pending Payments', value: '${paymentStats['pending'] ?? 0}', color: Colors.red),
            const Divider(),
            _RowItem(label: 'Completed Payments', value: '${paymentStats['completed'] ?? 0}', color: Colors.green),
            const Divider(),
            _RowItem(label: 'Razorpay (Digital)', value: '₹1,42,700', color: Colors.blue),
            const Divider(),
            _RowItem(label: 'Cash (Physical)', value: '₹42,300', color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RowItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
