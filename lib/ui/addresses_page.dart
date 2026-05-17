import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_api.dart';
import '../data/app_state.dart';
import '../utils/app_error.dart';
import 'widgets/address_form_fields.dart';

class AddressesPage extends ConsumerStatefulWidget {
  const AddressesPage({super.key});

  @override
  ConsumerState<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends ConsumerState<AddressesPage> {
  bool _loading = false;
  List<dynamic> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final authApi = AuthApi();
      final profile = await authApi.getProfile(sessionToken: AppState.sessionToken!);
      if (mounted) {
        setState(() {
          _addresses = profile['addresses'] ?? [];
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openAddAddressForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add New Address', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              AddressFormFields(
                nameCtrl: TextEditingController(),
                phoneCtrl: TextEditingController(),
                flatCtrl: TextEditingController(),
                areaCtrl: TextEditingController(),
                landmarkCtrl: TextEditingController(),
                pincodeCtrl: TextEditingController(),
                cityCtrl: TextEditingController(),
                selectedState: null,
                onStateChanged: (val) {},
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic to POST to /api/auth/addresses/ would go here
                    Navigator.pop(context);
                    _fetch();
                  },
                  child: const Text('Save Address'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: const Color(0xFF071A1D),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _addresses.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final addr = _addresses[index];
                  return _AddressCard(address: addr, onRefresh: _fetch);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAddressForm,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('No saved addresses', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final dynamic address;
  final VoidCallback onRefresh;
  const _AddressCard({required this.address, required this.onRefresh});

  Future<void> _deleteAddress(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text('Are you sure you want to remove this saved address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthApi().deleteAddress(id, sessionToken: AppState.sessionToken!);
        onRefresh();
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppError.sanitize(e))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = address['is_default'] == true;
    final label = address['label'] ?? 'Home';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDefault ? Colors.blue.withValues(alpha: 0.5) : Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            label.toString().toLowerCase() == 'work' ? Icons.work_outline : Icons.home_outlined,
            color: isDefault ? Colors.blue : Colors.white54,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text('DEFAULT', style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${address['flat_house_no']}, ${address['area_street']}, ${address['town_city']}, ${address['state']} - ${address['pincode']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteAddress(context, address['id']),
          ),
        ],
      ),
    );
  }
}
