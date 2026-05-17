import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/admin_provider.dart';

class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  String? _selectedAction;
  final List<String> _actions = [
    'status_change', 'stock_update', 'price_change', 
    'part_added', 'part_removed', 'payment_verified', 'cash_collected'
  ];

  @override
  Widget build(BuildContext context) {
    final params = (actionType: _selectedAction, userId: null);
    final logsAsync = ref.watch(activityLogsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activityLogsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Actions'),
                  selected: _selectedAction == null,
                  onSelected: (val) => setState(() => _selectedAction = null),
                ),
                const SizedBox(width: 8),
                ..._actions.map((action) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(action.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10)),
                    selected: _selectedAction == action,
                    onSelected: (val) => setState(() => _selectedAction = val ? action : null),
                  ),
                )),
              ],
            ),
          ),
          
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) return const Center(child: Text('No logs found'));
                
                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final date = DateTime.parse(log['timestamp']);
                    
                    return ListTile(
                      isThreeLine: true,
                      leading: CircleAvatar(
                        backgroundColor: _getActionColor(log['action_type']).withValues(alpha: 0.1),
                        child: Icon(_getActionIcon(log['action_type']), color: _getActionColor(log['action_type']), size: 20),
                      ),
                      title: Text(log['description'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('By: ${log['full_name']} (@${log['username']})', style: const TextStyle(fontSize: 12)),
                          Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      onTap: () => _showMetadata(context, log),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'status_change': return Colors.blue;
      case 'stock_update': return Colors.orange;
      case 'price_change': return Colors.green;
      case 'part_added': return Colors.purple;
      case 'part_removed': return Colors.red;
      case 'payment_verified': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'status_change': return Icons.sync_alt;
      case 'stock_update': return Icons.inventory_2_outlined;
      case 'price_change': return Icons.sell_outlined;
      case 'part_added': return Icons.add_circle_outline;
      case 'part_removed': return Icons.remove_circle_outline;
      case 'payment_verified': return Icons.verified_user_outlined;
      default: return Icons.history;
    }
  }

  void _showMetadata(BuildContext context, Map<String, dynamic> log) {
    final metadata = log['metadata'] as Map<String, dynamic>? ?? {};
    if (metadata.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: metadata.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Text('${e.key.replaceAll('_', ' ').toUpperCase()}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('${e.value}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
