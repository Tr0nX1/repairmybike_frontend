import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../data/app_state.dart';
import 'main_shell.dart';
import 'vehicle_type_page.dart';

class YourVehiclePage extends StatelessWidget {
  const YourVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vehicleName = AppState.vehicleName ?? 'Unknown Vehicle';
    final vehicleBrand = AppState.vehicleBrand ?? 'Unknown Brand';
    final vehicleType = AppState.vehicleType ?? 'Vehicle';
    
    // We try to use the specific model image first, fallback to brand, then type
    final heroImage = AppState.vehicleImageUrl ?? AppState.vehicleTypeImageUrl;
    final brandImage = AppState.vehicleBrandImageUrl;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent for hero effect
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: colorScheme.onSurface),
            onPressed: () {}, // Future feature
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // Allow image to go behind status bar
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                // Gradient background for a "premium" feel
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surfaceContainerHighest, // Light/Dark grey depending on mode
                    colorScheme.surface,
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Atmospheric glow
                  Positioned(
                    top: 50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.2),
                        boxShadow: [
                           BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 100, spreadRadius: 50),
                        ]
                      ),
                    ),
                  ),
                  
                  // The Hero Vehicle Image
                  if (heroImage != null)
                    Positioned.fill(
                      bottom: 50,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CachedNetworkImage(
                          imageUrl: heroImage,
                          fit: BoxFit.contain, // Maintain aspect ratio to show full bike
                          placeholder: (context, url) => Center(
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: const Icon(Icons.two_wheeler, size: 100),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(Icons.two_wheeler, size: 120, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                     Icon(Icons.two_wheeler, size: 120, color: colorScheme.onSurfaceVariant),

                  // Gradient Overlay at bottom to blend into body
                  Positioned(
                    bottom: 0,
                    left: 0, 
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, colorScheme.surface],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // DETAILS SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   // Brand & Model
                   if (brandImage != null)
                      Container(
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: CachedNetworkImage(imageUrl: brandImage, fit: BoxFit.contain),
                      ),
                   
                   Text(
                     vehicleName,
                     textAlign: TextAlign.center,
                     style: TextStyle(
                       fontSize: 28, 
                       fontWeight: FontWeight.w800, 
                       color: colorScheme.onSurface,
                       letterSpacing: -0.5, // Tight display font
                     )
                   ),
                   const SizedBox(height: 8),
                   Text(
                     '$vehicleBrand • $vehicleType',
                     style: TextStyle(
                       fontSize: 14, 
                       fontWeight: FontWeight.w500, 
                       color: colorScheme.onSurface.withOpacity(0.6),
                       letterSpacing: 1.0,
                     )
                   ),
                   
                   const SizedBox(height: 32),

                   // "Health" Status Card (Static for now, but looks cool)
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceAround,
                       children: [
                          _StatusItem(label: 'Status', value: 'Active', icon: Icons.check_circle, color: Colors.green),
                          Container(width: 1, height: 40, color: colorScheme.outline.withOpacity(0.2)),
                          _StatusItem(label: 'Service', value: 'Due Soon', icon: Icons.build_circle, color: Colors.orange),
                       ],
                     ),
                   ),

                   const SizedBox(height: 40),

                   // ACTION BUTTONS
                   SizedBox(
                     width: double.infinity,
                     height: 54,
                     child: ElevatedButton(
                       onPressed: () {
                         // Navigate to change vehicle flow
                         Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (_) => const VehicleTypePage())
                         );
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: colorScheme.primary,
                         foregroundColor: colorScheme.onPrimary,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         elevation: 0,
                       ),
                       child: const Text('Change Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     ),
                   ),
                   
                   const SizedBox(height: 16),
                   
                   // Secondary Action (Optional)
                   SizedBox(
                     width: double.infinity,
                     height: 54,
                     child: OutlinedButton(
                       onPressed: () {
                         // Just pop to home
                         Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainShell()),
                          (route) => false,
                        );
                       },
                       style: OutlinedButton.styleFrom(
                         side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                         foregroundColor: colorScheme.onSurface,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       ),
                       child: const Text('Go to Home', style: TextStyle(fontWeight: FontWeight.w600)),
                     ),
                   ),
                   
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 10)),
      ],
    );
  }
}
