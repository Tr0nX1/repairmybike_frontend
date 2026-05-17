import 'package:flutter/material.dart';

class BookingTimeline extends StatelessWidget {
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingTimeline({
    super.key,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    final stages = [
      ('pending', 'Requested'),
      ('confirmed', 'Confirmed'),
      ('in_progress', 'In Progress'),
      ('completed', 'Ready'),
    ];

    int currentIdx = stages.indexWhere((s) => s.$1 == status.toLowerCase());
    if (status.toLowerCase() == 'cancelled') currentIdx = -1;

    return Column(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          _buildStep(
            context,
            label: stages[i].$2,
            isActive: i <= currentIdx,
            isLast: i == stages.length - 1,
            isCancelled: status.toLowerCase() == 'cancelled' && i == 0,
          ),
          if (i < stages.length - 1)
            _buildLine(context, isActive: i < currentIdx),
        ],
      ],
    );
  }

  Widget _buildStep(BuildContext context, {
    required String label,
    required bool isActive,
    required bool isLast,
    bool isCancelled = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCancelled 
                ? Colors.red 
                : (isActive ? cs.primary : cs.surfaceContainerHighest),
            border: Border.all(
              color: isActive ? Colors.transparent : cs.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            isCancelled ? Icons.close : (isActive ? Icons.check : null),
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          isCancelled ? 'Cancelled' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(BuildContext context, {required bool isActive}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 11),
      height: 20,
      width: 2,
      color: isActive ? cs.primary : cs.outline.withValues(alpha: 0.2),
    );
  }
}
