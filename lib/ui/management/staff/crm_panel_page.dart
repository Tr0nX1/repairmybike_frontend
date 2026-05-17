import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/staff_provider.dart';

class CrmPanelPage extends ConsumerStatefulWidget {
  const CrmPanelPage({super.key});

  @override
  ConsumerState<CrmPanelPage> createState() => _CrmPanelPageState();
}

class _CrmPanelPageState extends ConsumerState<CrmPanelPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // We'll reuse the bookings provider for now, but in a real app
    // we'd have a dedicated Customer provider.
    final bookingsAsync = ref.watch(staffBookingsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Relations (CRM)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search customer name or phone...',
              onChanged: (val) => setState(() => _searchQuery = val),
              leading: const Icon(Icons.search),
            ),
          ),
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                // Extract unique customers from bookings
                final Map<String, dynamic> customers = {};
                for (var b in bookings) {
                  final c = b['customer'];
                  if (c != null && c['phone'] != null) {
                    if (!customers.containsKey(c['phone'])) {
                      customers[c['phone']] = {
                        'name': c['name'],
                        'phone': c['phone'],
                        'email': c['email'],
                        'total_bookings': 0,
                        'total_spent': 0.0,
                      };
                    }
                    customers[c['phone']]['total_bookings']++;
                    customers[c['phone']]['total_spent'] += double.parse(b['total_amount'].toString());
                  }
                }

                final customerList = customers.values.toList();
                final filtered = customerList.where((c) => 
                  c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  c['phone'].toString().contains(_searchQuery)
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(customer['name']),
                      subtitle: Text('${customer['phone']} • ${customer['total_bookings']} Bookings'),
                      trailing: Text(
                        '₹${customer['total_spent'].toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      onTap: () => _showCustomerDetails(context, customer),
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

  void _showCustomerDetails(BuildContext context, Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer['name'], style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(customer['phone'], style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              const Text('Life-time Value', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₹${customer['total_spent']}', style: const TextStyle(fontSize: 24, color: Colors.green)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = 'tel:${customer['phone']}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final phone = customer['phone'];
                        final url = 'https://wa.me/91$phone';
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
