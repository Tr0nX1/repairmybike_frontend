import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/staff_provider.dart';

class CashCollectionDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onSuccess;

  const CashCollectionDialog({
    super.key,
    required this.booking,
    required this.onSuccess,
  });

  @override
  ConsumerState<CashCollectionDialog> createState() => _CashCollectionDialogState();
}

class _CashCollectionDialogState extends ConsumerState<CashCollectionDialog> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.booking['total_amount'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Collect Cash Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Confirm the amount collected from the customer in physical cash.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount Collected (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Confirm Collection'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(staffApiProvider);
      final res = await api.collectCash(widget.booking['id'], amount);
      
      if (res['error'] == false) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cash collected successfully')),
          );
        }
      } else {
        throw Exception(res['message'] ?? 'Failed to collect cash');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
