import 'package:flutter/material.dart';
import '../../data/app_state.dart';

class CustomerDetailsResult {
  final String name;
  final String phone;
  final String address;
  CustomerDetailsResult({required this.name, required this.phone, required this.address});
}

Future<CustomerDetailsResult?> showCustomerDetailsSheet(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;
  final nameCtrl = TextEditingController(text: AppState.fullName ?? '');
  final phoneCtrl = TextEditingController(text: AppState.phoneNumber ?? '');
  final addressCtrl = TextEditingController(text: AppState.fullAddress);
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet<CustomerDetailsResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer Details', style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  validator: (v) {
                    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return s.length < 10 ? 'Enter a valid phone' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Address'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your address' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final address = addressCtrl.text.trim();
                      AppState.setLastCustomerPhone(phone);
                      AppState.setProfile(name: name, mail: AppState.email);
                      Navigator.of(ctx).pop(CustomerDetailsResult(name: name, phone: phone, address: address));
                    },
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
