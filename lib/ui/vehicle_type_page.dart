import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../data/app_state.dart';
import '../data/vehicles_api.dart';
import '../utils/url_utils.dart';
import 'vehicle_brand_page.dart';

class VehicleTypePage extends StatefulWidget {
  const VehicleTypePage({super.key, this.phone});
  final String? phone;

  @override
  State<VehicleTypePage> createState() => _VehicleTypePageState();
}

class _VehicleTypePageState extends State<VehicleTypePage> {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  final _api = VehiclesApi();
  List<VehicleTypeItem> _types = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getVehicleTypes();
      setState(() => _types = items);
    } catch (e) {
      setState(() => _error = 'Failed to load vehicle types');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _select(VehicleTypeItem item) {
    final typeName = item.name.trim().isEmpty ? 'vehicle' : item.name.trim();
    AppState.setVehicleType(typeName);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleBrandPage(
          phone: widget.phone,
          vehicleTypeId: item.id,
          vehicleTypeName: typeName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        title: const Text('Select Vehicle Type'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadTypes,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: accent),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width < 600
                        ? 2
                        : (MediaQuery.of(context).size.width < 900 ? 3 : 4),
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _types.length,
                  itemBuilder: (context, index) {
                    final item = _types[index];
                    final imgUrl = buildImageUrl(item.image);
                    return InkWell(
                      onTap: () => _select(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: imgUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: imgUrl,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                        placeholder: (context, url) => Shimmer.fromColors(
                                          baseColor: Colors.grey[800]!,
                                          highlightColor: Colors.grey[700]!,
                                          child: Container(color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.two_wheeler,
                                              color: Colors.white54,
                                              size: 48,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.two_wheeler,
                                      color: Colors.white54,
                                      size: 48,
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
