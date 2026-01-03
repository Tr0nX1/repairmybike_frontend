import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/saved_services_api.dart';
import '../models/service.dart';
import 'service_detail_page.dart';

class SavedServicesPage extends StatefulWidget {
  const SavedServicesPage({super.key});

  @override
  State<SavedServicesPage> createState() => _SavedServicesPageState();
}

class _SavedServicesPageState extends State<SavedServicesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!AppState.isAuthenticated || AppState.sessionToken == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await SavedServicesApi().getSavedServices(AppState.sessionToken!);
      if (mounted) {
        setState(() {
          _services = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(int serviceId) async {
    // Optimistic update
    setState(() {
      _services.removeWhere((item) => item['service']['id'] == serviceId);
    });
    // Update global state
    await AppState.toggleLikeService(serviceId);
    // If global state update fails, we might want to revert, but toggleLikeService handles API call too.
    // If we want to be sure, we can re-fetch.
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F0F0F);
    
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Saved Services'),
        backgroundColor: bg,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                       Icon(Icons.favorite_border, size: 64, color: Colors.white24),
                       SizedBox(height: 16),
                       Text('No saved services yet', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final item = _services[index];
                    final serviceData = item['service'];
                    final sId = serviceData['id'];
                    final name = serviceData['name'] ?? 'Unknown Service';
                    final image = serviceData['images'] != null && serviceData['images'].isNotEmpty 
                        ? serviceData['images'][0] 
                        : null;
                    
                    return GestureDetector(
                      onTap: () {
                         try {
                           // Construct Service object from the data
                           final service = Service.fromJson(serviceData);
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceDetailPage(service: service),
                              ),
                           );
                         } catch (e) {
                           // If construction fails, show error
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Error loading service: $e')),
                           );
                         }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                          image: image != null
                              ? DecorationImage(
                                  image: NetworkImage(image),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.6),
                                    BlendMode.darken,
                                  ),
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                onPressed: () => _remove(sId),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
