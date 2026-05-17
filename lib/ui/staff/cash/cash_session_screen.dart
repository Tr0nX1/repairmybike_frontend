import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/staff_api.dart';
import '../../../utils/app_error.dart';

class CashSessionScreen extends ConsumerStatefulWidget {
  const CashSessionScreen({super.key});

  @override
  ConsumerState<CashSessionScreen> createState() => _CashSessionScreenState();
}

class _CashSessionScreenState extends ConsumerState<CashSessionScreen> {
  bool _loading = true;
  Map<String, dynamic>? _session;
  List<dynamic> _movements = [];
  final _balanceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final api = StaffApi();
      final res = await api.getCurrentCashSession();
      if (res['error'] == false && res['data'] != null) {
        _session = res['data'];
        final movesRes = await api.getCashMovements(_session!['id']);
        _movements = movesRes['data'] ?? [];
      } else {
        _session = null;
        _movements = [];
      }
    } catch (e) {
       _session = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startSession() async {
    final val = double.tryParse(_balanceCtrl.text);
    if (val == null) return;

    setState(() => _loading = true);
    try {
      await StaffApi().startCashSession(val);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppError.sanitize(e))));
      setState(() => _loading = false);
    }
  }

  Future<void> _closeSession() async {
    final val = await _showCloseDialog();
    if (val == null) return;

    setState(() => _loading = true);
    try {
      await StaffApi().closeCashSession(_session!['id'], val);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppError.sanitize(e))));
      setState(() => _loading = false);
    }
  }

  Future<double?> _showCloseDialog() async {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter actual cash in hand:'),
            TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)), child: const Text('Close Session')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_session == null) {
      return _buildEmptyState();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Active Cash Session')),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMovementsList()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _closeSession,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('End Day & Close Session'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Session')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text('Start Your Day', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Open a cash session to record collections.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            TextField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Opening Balance',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startSession,
                child: const Text('Open Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Row(
        children: [
          _stat('Opening', '₹${_session!['opening_balance']}'),
          const VerticalDivider(),
          _stat('Collected', '₹${_session!['collected_amount']}'),
          const VerticalDivider(),
          _stat('Expected', '₹${_session!['expected_balance']}'),
        ],
      ),
    );
  }

  Widget _stat(String label, String val) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildMovementsList() {
    if (_movements.isEmpty) return const Center(child: Text('No collections recorded yet.'));

    return ListView.builder(
      itemCount: _movements.length,
      itemBuilder: (context, index) {
        final m = _movements[index];
        final time = DateFormat('hh:mm a').format(DateTime.parse(m['created_at']).toLocal());
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.add, size: 16)),
          title: Text('Booking #${m['booking_id']}'),
          subtitle: Text(time, style: const TextStyle(fontSize: 12)),
          trailing: Text('₹${m['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        );
      },
    );
  }
}
