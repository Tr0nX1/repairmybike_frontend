import 'package:flutter/material.dart';

import 'package:signature/signature.dart';
import 'package:go_router/go_router.dart';

class HandoverFormPage extends StatefulWidget {
  final int bookingId;

  const HandoverFormPage({super.key, required this.bookingId});

  @override
  State<HandoverFormPage> createState() => _HandoverFormPageState();
}

class _HandoverFormPageState extends State<HandoverFormPage> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _fuelEmpty = false;
  bool _scratches = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Handover: #${widget.bookingId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle Condition Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Fuel Level Low?'),
              value: _fuelEmpty,
              onChanged: (val) => setState(() => _fuelEmpty = val),
            ),
            SwitchListTile(
              title: const Text('Existing Scratches?'),
              value: _scratches,
              onChanged: (val) => setState(() => _scratches = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Driver Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text('Customer Signature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Signature(
                controller: _signatureController,
                height: 200,
                backgroundColor: Colors.white,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _signatureController.clear(),
                  child: const Text('Clear Signature'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitHandover,
                child: const Text('Complete Handover'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitHandover() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer signature is required')),
      );
      return;
    }

    // In a real app, we'd upload the signature image and checklist data
    // final signatureImage = await _signatureController.toPngBytes();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Handover completed successfully')),
    );
    context.pop();
  }
}
