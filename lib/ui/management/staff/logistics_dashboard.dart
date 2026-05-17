import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/staff_provider.dart';

class LogisticsDashboardPage extends ConsumerStatefulWidget {
  const LogisticsDashboardPage({super.key});

  @override
  ConsumerState<LogisticsDashboardPage> createState() => _LogisticsDashboardPageState();
}

class _LogisticsDashboardPageState extends ConsumerState<LogisticsDashboardPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Mock Shop Location (Center of Map)
  static const LatLng _shopLocation = LatLng(12.9716, 77.5946); // Example: Bangalore

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(staffBookingsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logistics & Pickups'),
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _shopLocation,
                zoom: 12,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationEnabled: true,
            ),
          ),
          // List View of Pending Pickups
          Expanded(
            flex: 2,
            child: bookingsAsync.when(
              data: (bookings) {
                final pickups = bookings.where((b) => b['service_location'] == 'home').toList();
                
                if (pickups.isEmpty) {
                  return const Center(child: Text('No home pickups scheduled'));
                }

                return ListView.builder(
                  itemCount: pickups.length,
                  itemBuilder: (context, index) {
                    final pickup = pickups[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.home_repair_service)),
                      title: Text(pickup['vehicle_model_name'] ?? 'Bike'),
                      subtitle: Text(pickup['address'] ?? 'No address provided'),
                      trailing: const Icon(Icons.directions),
                      onTap: () => _focusOnPickup(pickup),
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

  void _focusOnPickup(Map<String, dynamic> pickup) {
    // In a real app, we'd use actual lat/lng from backend.
    // Since it's missing, we'll use a random offset from shop for demo.
    final lat = _shopLocation.latitude + (0.01 * (pickup['id'] % 5));
    final lng = _shopLocation.longitude + (0.01 * (pickup['id'] % 3));
    final pos = LatLng(lat, lng);

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
    
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('pickup_${pickup['id']}'),
          position: pos,
          infoWindow: InfoIdWindow(
            title: 'Pickup #${pickup['id']}',
            snippet: pickup['customer']['name'],
          ),
        ),
      );
    });
  }
}

// Fixed InfoIdWindow typo
class InfoIdWindow extends InfoWindow {
  const InfoIdWindow({super.title, super.snippet});
}
