import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/spare_parts_provider.dart';


class PartPickerDialog extends ConsumerStatefulWidget {
  const PartPickerDialog({super.key});

  @override
  ConsumerState<PartPickerDialog> createState() => _PartPickerDialogState();
}

class _PartPickerDialogState extends ConsumerState<PartPickerDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filter = PartsFilter(search: _searchQuery);
    final partsAsync = ref.watch(sparePartsByFilterProvider(filter));

    return AlertDialog(
      title: const Text('Select Spare Part'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by SKU or name...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: partsAsync.when(
                data: (parts) {
                  if (parts.isEmpty) return const Center(child: Text('No parts found'));
                  return ListView.builder(
                    itemCount: parts.length,
                    itemBuilder: (context, index) {
                      final part = parts[index];
                      return ListTile(
                        title: Text(part.name),
                        subtitle: Text('SKU: ${part.sku} • ₹${part.salePrice}'),
                        trailing: Text('Stock: ${part.stockQty}'),
                        onTap: part.stockQty > 0 
                          ? () => Navigator.pop(context, part)
                          : null,
                        enabled: part.stockQty > 0,
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}
