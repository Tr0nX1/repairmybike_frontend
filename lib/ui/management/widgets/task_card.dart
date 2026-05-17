import 'package:flutter/material.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  final Function(String)? onStatusUpdate;

  const TaskCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = booking['customer'] ?? {};
    final vehicle = booking['vehicle_model'] ?? {};
    final brand = vehicle['vehicle_brand'] ?? {};
    final status = booking['booking_status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${booking['id']}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${brand['name'] ?? ''} ${vehicle['name'] ?? ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    customer['name'] ?? 'Unknown Customer',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${booking['appointment_date']} • ${booking['appointment_time']}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (status == 'confirmed' || status == 'in_progress') ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'confirmed')
                      ElevatedButton.icon(
                        onPressed: () => onStatusUpdate?.call('in_progress'),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Start Work'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (status == 'in_progress')
                      ElevatedButton.icon(
                        onPressed: () => onStatusUpdate?.call('completed'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Mark Fixed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
