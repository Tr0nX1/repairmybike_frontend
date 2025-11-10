import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/vehicles_api.dart';
import '../utils/url_utils.dart';
import 'main_shell.dart';
import 'profile_details_page.dart';

class VehicleNamePage extends StatefulWidget {
  const VehicleNamePage({super.key, this.phone, required this.vehicleBrandId, required this.vehicleBrandName});
  final String? phone;
  final int vehicleBrandId;
  final String vehicleBrandName;

  @override
  State<VehicleNamePage> createState() => _VehicleNamePageState();
}

class _VehicleNamePageState extends State<VehicleNamePage> {
  final _api = VehiclesApi();
  List<VehicleModelItem> _models = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getVehicleModels(widget.vehicleBrandId);
      setState(() => _models = items);
    } catch (e) {
      setState(() => _error = 'Failed to load models');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select ${widget.vehicleBrandName} Model',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Choose your ${widget.vehicleBrandName} model:',
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
                            OutlinedButton(onPressed: _loadModels, child: const Text('Retry')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _models.length,
                          itemBuilder: (context, index) {
                            final item = _models[index];
                            return _buildModelCard(context, item);
                          },
                        ),
            ),
            const SizedBox(height: 20),
            // Custom model input option
            _buildCustomModelInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, VehicleModelItem item) {
    final model = item.name;
    final img = buildImageUrl(item.image);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () async {
          await AppState.setVehicleName(model);
          if (widget.phone != null && widget.phone!.isNotEmpty) {
            await AppState.setVehicleForPhone(
              phone: widget.phone!,
              type: AppState.vehicleType,
              brand: AppState.vehicleBrand,
              name: model,
            );
          }
          final needsDetails = AppState.isCustomerAuthenticated &&
              ((AppState.fullName?.isEmpty ?? true) || (AppState.address?.isEmpty ?? true));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => needsDetails ? const ProfileDetailsPage() : const MainShell()),
            (route) => false,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (img != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      img,
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => const Icon(Icons.directions_bike, color: Colors.white54),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  model,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomModelInput(BuildContext context) {
    final TextEditingController customController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Don\'t see your model?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: customController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your vehicle model',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.cyan),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.cyan),
                onPressed: () async {
                  if (customController.text.trim().isNotEmpty) {
                    final name = customController.text.trim();
                    await AppState.setVehicleName(name);
                    if (widget.phone != null && widget.phone!.isNotEmpty) {
                      await AppState.setVehicleForPhone(
                        phone: widget.phone!,
                        type: AppState.vehicleType,
                        brand: AppState.vehicleBrand,
                        name: name,
                      );
                    }
                    final needsDetails = AppState.isCustomerAuthenticated &&
                        ((AppState.fullName?.isEmpty ?? true) || (AppState.address?.isEmpty ?? true));
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => needsDetails ? const ProfileDetailsPage() : const MainShell()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}