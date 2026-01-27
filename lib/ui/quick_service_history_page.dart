import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/quick_service_api.dart';
import '../models/quick_service.dart';

class QuickServiceHistoryPage extends StatefulWidget {
  const QuickServiceHistoryPage({super.key});

  @override
  State<QuickServiceHistoryPage> createState() => _QuickServiceHistoryPageState();
}

class _QuickServiceHistoryPageState extends State<QuickServiceHistoryPage> {
  List<QuickServiceRequest> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final list = await QuickServiceApi().getHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _loading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'initiated': return Colors.blue;
      case 'contacted': return Colors.amber;
      case 'mechanic_dispatched': return Colors.deepPurple;
      case 'in_progress': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.grey;
      default: return Colors.white;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Quick Service Requests'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: cs.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No requests found',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = _history[index];
                    final color = _getStatusColor(req.status);
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outline.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Request #${req.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _formatStatus(req.status),
                                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: cs.onSurface.withOpacity(0.5)),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(req.createdAt),
                                style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 13),
                              ),
                            ],
                          ),
                          if (req.servicesGrabbed != null && req.servicesGrabbed!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text('Services Rendered:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(req.servicesGrabbed!, style: TextStyle(color: cs.onSurface.withOpacity(0.8), fontSize: 13)),
                          ],
                          if (req.totalAmount > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Paid:', style: TextStyle(color: Colors.white70)),
                                Text(
                                  '₹${req.totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
