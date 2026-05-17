import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffDirectoryPage extends ConsumerStatefulWidget {
  const StaffDirectoryPage({super.key});

  @override
  ConsumerState<StaffDirectoryPage> createState() => _StaffDirectoryPageState();
}

class _StaffDirectoryPageState extends ConsumerState<StaffDirectoryPage> {

  bool _isLoading = true;
  List<dynamic> _staffList = [];

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      // Mock data for UI development since endpoint might be empty
      await Future.delayed(const Duration(milliseconds: 800));
      _staffList = [
        {'id': 1, 'name': 'John Mechanic', 'role': 'mechanic', 'identifier': '9876543210', 'is_active': true},
        {'id': 2, 'name': 'Sarah Admin', 'role': 'admin', 'identifier': 'admin@repairmybike.com', 'is_active': true},
        {'id': 3, 'name': 'Mike Staff', 'role': 'staff', 'identifier': '9988776655', 'is_active': true},
      ];
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchStaff),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staffList.isEmpty
              ? const Center(child: Text('No staff members found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staffList.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final staff = _staffList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(staff['role']),
                        child: Text(staff['role'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(staff['name'] ?? 'Unnamed'),
                      subtitle: Text('${staff['identifier']} • ${staff['role'].toString().toUpperCase()}'),
                      trailing: Switch(
                        value: staff['is_active'],
                        onChanged: (val) => _toggleStatus(staff['id'], val),
                      ),
                      onTap: () => _editStaff(staff),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewStaff,
        label: const Text('Add Staff'),
        icon: const Icon(Icons.person_add_alt_1),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red;
      case 'mechanic': return Colors.blue;
      case 'staff': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _toggleStatus(int id, bool val) {
    // API call would go here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Staff member ${val ? 'activated' : 'deactivated'}')),
    );
  }

  void _editStaff(Map<String, dynamic> staff) {
    // Show edit dialog/page
  }

  void _addNewStaff() {
    // Show add dialog/page
  }
}
