import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/spare_parts_provider.dart';
import '../../../models/spare_part.dart';
import '../widgets/barcode_scanner_view.dart';

class InventoryPanel extends ConsumerStatefulWidget {
  const InventoryPanel({super.key});

  @override
  ConsumerState<InventoryPanel> createState() => _InventoryPanelState();
}

class _InventoryPanelState extends ConsumerState<InventoryPanel> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filter = PartsFilter(search: _searchQuery);
    final partsAsync = ref.watch(sparePartsByFilterProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: 'Search parts by SKU or name...',
              onChanged: (value) => setState(() => _searchQuery = value),
              leading: const Icon(Icons.search),
            ),
          ),
        ),
      ),
      body: partsAsync.when(
        data: (parts) {
          if (parts.isEmpty) {
            return const Center(child: Text('No parts found'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: parts.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final part = parts[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: part.thumbnail != null 
                      ? Image.network(part.thumbnail!, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                ),
                title: Text(part.name),
                subtitle: Text('SKU: ${part.sku} • ₹${part.salePrice}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock: ${part.stockQty}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: part.stockQty <= 5 ? Colors.red : Colors.green,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
                onTap: () => _showStockUpdateDialog(context, part),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarcodeScannerView(
                onScan: (sku) {
                  setState(() => _searchQuery = sku);
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  void _showStockUpdateDialog(BuildContext context, SparePartListItem part) {
    final controller = TextEditingController(text: part.stockQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${part.sku}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Stock Quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newQty = int.tryParse(controller.text);
              if (newQty != null) {
                await _updateStock(part.id, newQty);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStock(int id, int qty) async {
    try {
      final api = ref.read(sparePartsApiProvider);
      await api.updatePart(id, {'stock_qty': qty});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock updated successfully')),
      );
      ref.invalidate(sparePartsByFilterProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }
}
