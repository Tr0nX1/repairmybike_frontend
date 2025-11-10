import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/auth_api.dart';
import 'auth_page.dart';
import 'profile_details_page.dart';
import 'vehicle_type_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  bool _loggingOut = false;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _edit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileDetailsPage()),
    ).then((_) => setState(() {}));
  }

  void _signIn() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthPage(
          onFinished: () {
            Navigator.of(context).pop();
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = AppState.isAuthenticated;
    final name = AppState.fullName ?? 'Guest User';
    final email = (AppState.email?.isNotEmpty == true) ? AppState.email! : 'Add email';
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
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(email, style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                      ),
                      // Edit button
                      TextButton(
                        onPressed: _edit,
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick stats
                Row(
                  children: const [
                    _StatCard(title: 'Bookings', value: '0'),
                    SizedBox(width: 12),
                    _StatCard(title: 'Vehicles', value: '1'),
                    SizedBox(width: 12),
                    _StatCard(title: 'Saved', value: '0'),
                  ],
                ),

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
                      const Icon(Icons.directions_bike, color: Colors.white70, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Vehicle',
                                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              [
                                AppState.vehicleBrand ?? '—',
                                AppState.vehicleName ?? '—',
                              ]
                                  .where((e) => e != '—')
                                  .join(' • ')
                                  .isEmpty
                                  ? 'Choose your vehicle'
                                  : [
                                      AppState.vehicleBrand ?? '—',
                                      AppState.vehicleName ?? '—',
                                    ]
                                      .where((e) => e != '—')
                                      .join(' • '),
                              style:
                                  const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const VehicleTypePage()))
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Details list
                _Section(title: 'Vehicle'),
                _Tile(label: 'Type', value: AppState.vehicleType ?? '—', icon: Icons.motorcycle),
                _Tile(label: 'Brand', value: AppState.vehicleBrand ?? '—', icon: Icons.factory),
                _Tile(label: 'Model', value: AppState.vehicleName ?? '—', icon: Icons.directions_bike),

                const SizedBox(height: 12),
                _Section(title: 'Contact'),
                _Tile(label: 'Name', value: AppState.fullName ?? '—', icon: Icons.person_outline),
                _Tile(label: 'Address', value: AppState.address ?? '—', icon: Icons.location_on_outlined),
                _Tile(label: 'Email', value: AppState.email?.isEmpty == true ? '—' : (AppState.email ?? '—'), icon: Icons.email_outlined),
                _Tile(label: 'Phone (OTP)', value: AppState.phoneNumber ?? '—', icon: Icons.phone_outlined),

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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loggingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
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
  const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    const Color card = Color(0xFF1C1C1C);
    const Color border = Color(0xFF2A2A2A);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
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
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
          return const Icon(Icons.person, color: Colors.white70, size: 32);
        }),
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
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
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