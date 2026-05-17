import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/services_provider.dart';

class PricingEditorPage extends ConsumerStatefulWidget {
  const PricingEditorPage({super.key});

  @override
  ConsumerState<PricingEditorPage> createState() => _PricingEditorPageState();
}

class _PricingEditorPageState extends ConsumerState<PricingEditorPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Reusing existing service categories provider
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Pricing Editor'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: 'Search services...',
              onChanged: (val) => setState(() => _searchQuery = val),
              leading: const Icon(Icons.search),
            ),
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          // Flattening for demo search
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ExpansionTile(
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  // This should ideally fetch services for this category
                  ListTile(
                    title: const Text('General Service (Mock)'),
                    subtitle: const Text('Standard maintenance'),
                    trailing: const Text('₹999', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _editPrice(context, 'General Service (Mock)', 999),
                  ),
                  ListTile(
                    title: const Text('Oil Change (Mock)'),
                    subtitle: const Text('Synthetic oil replacement'),
                    trailing: const Text('₹599', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _editPrice(context, 'Oil Change (Mock)', 599),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _editPrice(BuildContext context, String name, double currentPrice) {
    final controller = TextEditingController(text: currentPrice.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Price: $name'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Price (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // API call to update price
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Price updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
