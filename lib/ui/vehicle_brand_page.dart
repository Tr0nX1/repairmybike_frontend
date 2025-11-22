import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/vehicles_api.dart';
import '../utils/url_utils.dart';
import 'vehicle_name_page.dart';
import 'widgets/rm_app_bar.dart';

class VehicleBrandPage extends StatefulWidget {
  const VehicleBrandPage({super.key, this.phone, required this.vehicleTypeId, required this.vehicleTypeName});
  final String? phone;
  final int vehicleTypeId;
  final String vehicleTypeName;

  @override
  State<VehicleBrandPage> createState() => _VehicleBrandPageState();
}

class _VehicleBrandPageState extends State<VehicleBrandPage> {
  final _api = VehiclesApi();
  List<VehicleBrandItem> _brands = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getVehicleBrands(widget.vehicleTypeId);
      setState(() => _brands = items);
    } catch (e) {
      setState(() => _error = 'Failed to load brands');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _select(VehicleBrandItem item) {
    final phone = widget.phone ?? AppState.phoneNumber ?? AppState.lastCustomerPhone ?? '';
    if (phone.isNotEmpty) {
      AppState.setVehicleForPhone(phone: phone, brand: item.name);
    } else {
      AppState.setVehicleBrand(item.name);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleNamePage(
          phone: widget.phone,
          vehicleBrandId: item.id,
          vehicleBrandName: item.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: RMAppBar(title: 'Select ${widget.vehicleTypeName.toUpperCase()} Brand'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Choose your ${widget.vehicleTypeName} brand:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            OutlinedButton(onPressed: _loadBrands, child: const Text('Retry')),
                          ],
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
                            childAspectRatio: 0.95,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: _brands.length,
                          itemBuilder: (context, index) {
                            final item = _brands[index];
                            final img = buildImageUrl(item.image);
                            return InkWell(
                              onTap: () => _select(item),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[700]!, width: 1),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: img != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                img,
                                                fit: BoxFit.cover,
                                                alignment: Alignment.center,
                                                loadingBuilder: (context, child, progress) {
                                                  if (progress == null) return child;
                                                  return const Center(child: CircularProgressIndicator());
                                                },
                                                errorBuilder: (_, __, ___) => const Icon(Icons.factory, color: Colors.white54, size: 40),
                                              ),
                                            )
                                          : const Icon(Icons.factory, color: Colors.white54, size: 40),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
