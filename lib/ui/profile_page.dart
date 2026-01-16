import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../data/app_state.dart';
import '../data/auth_api.dart';
import 'auth_page.dart';
import 'profile_details_page.dart';
import 'vehicle_type_page.dart';
import 'booking_list_page.dart';
import 'cart_page.dart';
import 'saved_services_page.dart';
import '../data/booking_api.dart'; // Added for fetching bookings
import '../data/order_api.dart'; // Added for fetching spare parts orders
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/saved_services_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  bool _loggingOut = false;
  int _bookingCount = 0;  // Service bookings count
  int _orderCount = 0;  // Spare parts orders count
  List<Map<String, dynamic>> _recentBookings = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!AppState.isAuthenticated || (AppState.phoneNumber?.isEmpty ?? true)) return;
    setState(() => _loading = true);
    try {
      final api = BookingApi();
      final bookings = await api.getBookingsByPhone(
        AppState.phoneNumber!,
        sessionToken: AppState.sessionToken,
      );
      
      // Also fetch spare parts orders
      try {
        final orderApi = OrderApi();
        final orders = await orderApi.listOrders(phone: AppState.phoneNumber);
        
        // Also refresh liked/saved services here
        if (mounted) {
           await ref.read(savedServicesProvider.notifier).sync();
        }

        setState(() => _orderCount = orders.length);
      } catch (_) {
        // Ignore
      }
      
      setState(() {
         _bookingCount = bookings.length;
         // Take top 3 for recent
         _recentBookings = bookings.take(3).toList();
      });
    } catch (_) {
      // ignore
    } finally {
        if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      final api = AuthApi();
      await api.logout(
        refreshToken: AppState.refreshToken,
        sessionToken: AppState.sessionToken,
      );
      await AppState.clearAuth();
      await AppState.setLastCustomerPhone(null);
      if (!mounted) return;
      
      // Close app after logout per requirement
      // Using exit(0) to ensure a full shutdown as requested
      // Note: On iOS this might look like a crash, but it fulfills the "shutdown and close" request.
      try {
        await SystemNavigator.pop();
      } catch (_) {}
      
      // Fallback to exit(0) to ensure it closes
      // ignore: avoid_print
      print('Shutting down app...');
      exit(0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _edit() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileDetailsPage(popOnSave: true)))
        .then((_) => setState(() {}));
  }

  void _signIn() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthPage(
          onFinished: () async {
            // Re-check state after login to handle onboarding
            await AppState.init(); // Refresh state
            if (!mounted) return;
            
            Navigator.of(context).pop(); // Close auth page
            
            final hasVehicle = AppState.hasVehicle;

            if (!hasVehicle) {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleTypePage()));
            } else {
               setState(() {}); // Just refresh if everything is good
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = AppState.isAuthenticated;
    final name = isAuth
        ? ((AppState.fullName?.isNotEmpty ?? false)
              ? AppState.fullName!
              : 'User')
        : 'Guest User';
    final email = (AppState.email?.isNotEmpty == true)
        ? AppState.email!
        : 'Add email';
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      _Avatar(size: 64),
                      const SizedBox(width: 12),
                      // Name & email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      // Edit button
                      TextButton(onPressed: _edit, child: const Text('Edit')),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick stats
                Row(
                  children: [
                    _StatCard(
                      title: 'Bookings', 
                      value: '${_bookingCount + _orderCount}',  // Combined count
                      isLoading: _loading,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingListPage())),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                        title: 'Vehicles', 
                        value: (AppState.vehicleName?.isNotEmpty ?? false) ? '1' : '0',
                        isLoading: _loading,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleTypePage())), 
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                        title: 'Saved', 
                        value: '${ref.watch(savedServicesProvider).length}',
                        // Synced with backend now
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedServicesPage())),
                    ),
                  ],
                ),
                
                if (_recentBookings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Section(title: 'Recent Bookings'),
                    ..._recentBookings.map((b) {
                        return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border),
                            ),
                            child: ListTile(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingListPage())),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text('Booking #${b['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text('${b['booking_status'] ?? 'Pending'} • ₹${b['total_amount']}', style: const TextStyle(color: Colors.white70)),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                            ),
                        );
                    }).toList(),
                ],

                const SizedBox(height: 16),

                // Your Vehicle card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_bike,
                        color: Colors.white70,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Vehicle',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                    AppState.vehicleBrand ?? '—',
                                    AppState.vehicleName ?? '—',
                                  ].where((e) => e != '—').join(' • ').isEmpty
                                  ? 'Choose your vehicle'
                                  : [
                                      AppState.vehicleBrand ?? '—',
                                      AppState.vehicleName ?? '—',
                                    ].where((e) => e != '—').join(' • '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const VehicleTypePage(),
                                ),
                              )
                              .then((_) => setState(() {}));
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Primary actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAuth ? _edit : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isAuth ? 'Update Details' : 'Sign In'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _edit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: const BorderSide(color: accent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Details list
                _Section(title: 'Vehicle'),
                _Tile(
                  label: 'Type',
                  value: AppState.vehicleType ?? '—',
                  icon: Icons.motorcycle,
                ),
                _Tile(
                  label: 'Brand',
                  value: AppState.vehicleBrand ?? '—',
                  icon: Icons.factory,
                ),
                _Tile(
                  label: 'Model',
                  value: AppState.vehicleName ?? '—',
                  icon: Icons.directions_bike,
                ),

                const SizedBox(height: 12),
                _Section(title: 'Contact'),
                _Tile(
                  label: 'Name',
                  value: AppState.fullName ?? '—',
                  icon: Icons.person_outline,
                ),
                _Tile(
                  label: 'Address',
                  value: AppState.hasAddress ? AppState.fullAddress : '—',
                  icon: Icons.location_on_outlined,
                ),
                _Tile(
                  label: 'Email',
                  value: AppState.email?.isEmpty == true
                      ? '—'
                      : (AppState.email ?? '—'),
                  icon: Icons.email_outlined,
                ),
                _Tile(
                  label: 'Phone (OTP)',
                  value: AppState.phoneNumber ?? '—',
                  icon: Icons.phone_outlined,
                ),

                const SizedBox(height: 24),
                if (AppState.isAuthenticated)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loggingOut ? null : _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loggingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Logout'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Legacy row helper removed; using structured tiles above.
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool isLoading;
  const _StatCard({required this.title, required this.value, this.onTap, this.isLoading = false});
  @override
  Widget build(BuildContext context) {
    const Color card = Color(0xFF1C1C1C);
    const Color border = Color(0xFF2A2A2A);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final double size;
  const _Avatar({required this.size});

  static const Color border = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    final url = AppState.avatarUrl;
    final radius = size / 2;
    if (url != null && url.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(Icons.person, color: Colors.white70, size: 32);
          },
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: const Icon(Icons.person, color: Colors.white70, size: 32),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Tile({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    const Color card = Color(0xFF1C1C1C);
    const Color border = Color(0xFF2A2A2A);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
