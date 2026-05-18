import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:image_picker/image_picker.dart';
import '../data/app_state.dart';
import '../data/auth_api.dart';
import '../data/booking_api.dart';
import '../data/order_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/saved_services_provider.dart';
import '../utils/app_error.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _loggingOut = false;
  int _bookingCount = 0;
  int _orderCount = 0;

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
      final bookings = await api.getBookings();
      
      try {
        final orderApi = OrderApi();
        final orders = await orderApi.listOrders();
        setState(() => _orderCount = orders.length);
      } catch (_) {}

      if (mounted) {
        try {
          final authApi = AuthApi();
          final profileData = await authApi.getProfile(sessionToken: AppState.sessionToken!);
          await AppState.updateFromProfileMap(profileData);
          await ref.read(savedServicesProvider.notifier).sync();
          setState(() {});
        } catch (_) {}
      }
      
      setState(() {
         _bookingCount = bookings.length;

      });
    } catch (_) {} finally {
        if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      final api = AuthApi();
      await api.logout(refreshToken: AppState.refreshToken, sessionToken: AppState.sessionToken);
      await AppState.clearAuth();
      await AppState.setLastCustomerPhone(null);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppError.sanitize(e, fallback: 'Logout failed'))));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _edit() {
    context.push('/profile-details').then((_) {
      if (mounted) setState(() {});
    });
  }



  @override
  Widget build(BuildContext context) {
    final isAuth = AppState.isAuthenticated;
    final rawName = AppState.fullName ?? '';
    final isGenericName = rawName.isEmpty || rawName.startsWith('user_') || rawName.toLowerCase() == 'user';
    final name = isAuth ? (isGenericName ? 'Set your name' : rawName) : 'Guest User';
    final email = (AppState.email?.isNotEmpty == true) ? AppState.email! : (isAuth ? 'Complete profile to add email' : 'Add email');
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    final card = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final border = colorScheme.outline.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const _Avatar(size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(color: isGenericName && isAuth ? accent : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email, style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _edit, child: const Text('Edit')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (AppState.loyaltyPoints != null && AppState.loyaltyPoints! > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: Color(0xFFFACC15), size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Loyalty Points', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('${AppState.loyaltyPoints} PTS', style: const TextStyle(color: Color(0xFFFACC15), fontSize: 20, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isAuth && (isGenericName || !AppState.hasAddress))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: _edit,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.assignment_ind, color: accent),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Complete your profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text('Add your name and address to get started', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    _StatCard(title: 'Bookings', value: '${_bookingCount + _orderCount}', isLoading: _loading, onTap: () => context.push('/bookings')),
                    const SizedBox(width: 12),
                    _StatCard(title: 'Vehicles', value: (AppState.vehicleName?.isNotEmpty ?? false) ? '1' : '0', isLoading: _loading, onTap: () => context.push(AppState.hasVehicle ? '/your-vehicle' : '/vehicle-type')),
                    const SizedBox(width: 12),
                    _StatCard(title: 'Saved', value: '${ref.watch(savedServicesProvider).length}', onTap: () => context.push('/saved-services')),
                  ],
                ),
                const SizedBox(height: 16),
                _ActionTile(label: 'My Subscriptions', icon: Icons.card_membership, onTap: () => context.push('/my-subscriptions')),
                _ActionTile(label: 'Quick Service History', icon: Icons.flash_on, onTap: () => context.push('/quick-service-history')),
                const SizedBox(height: 16),
                _Section(title: 'Account Settings'),
                _ActionTile(label: 'Manage Addresses', icon: Icons.location_on_outlined, onTap: () => context.push('/addresses')),
                _ActionTile(label: 'Edit Profile', icon: Icons.person_outline, onTap: _edit),
                _ActionTile(label: 'Customer Care', icon: Icons.support_agent, onTap: () => context.push('/customer-care')),
                const SizedBox(height: 16),
                _Section(title: 'Legal'),
                _ActionTile(label: 'Terms & Conditions', icon: Icons.description_outlined, onTap: () => context.push('/terms-and-conditions')),
                _ActionTile(label: 'Privacy Policy', icon: Icons.privacy_tip_outlined, onTap: () => context.push('/privacy-policy')),
                _ActionTile(
                  label: 'Refund & Cancellation Policy',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.push('/refund-and-cancellation-policy'),
                ),
                _ActionTile(
                  label: 'Shipping & Delivery Policy',
                  icon: Icons.local_shipping_outlined,
                  onTap: () => context.push('/shipping-and-delivery-policy'),
                ),
                _ActionTile(
                  label: 'Payment Policy',
                  icon: Icons.payments_outlined,
                  onTap: () => context.push('/payment-policy'),
                ),
                _ActionTile(
                  label: 'Service Policy',
                  icon: Icons.build_circle_outlined,
                  onTap: () => context.push('/service-policy'),
                ),
                const SizedBox(height: 24),
                if (AppState.isAuthenticated)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loggingOut ? null : _logout,
                      style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _loggingOut ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Logout'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool isLoading;
  const _StatCard({required this.title, required this.value, this.onTap, this.isLoading = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2A2A))),
          child: Column(
            children: [
              isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatefulWidget {
  final double size;
  const _Avatar({required this.size});
  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  bool _uploading = false;
  Future<void> _pick(ImageSource src) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: src, maxWidth: 512, maxHeight: 512, imageQuality: 75);
      if (photo == null || !mounted) return;
      setState(() => _uploading = true);
      final result = await AuthApi().uploadProfilePhoto(filePath: photo.path);
      if (result['data'] != null && result['data']['profile_picture_url'] != null) {
        await AppState.setAvatarUrl(result['data']['profile_picture_url']);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppError.sanitize(e))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = AppState.avatarUrl;
    return GestureDetector(
      onTap: () => showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(ctx); _pick(ImageSource.camera); }),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(ctx); _pick(ImageSource.gallery); }),
      ]))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size, height: widget.size,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2A2A2A), width: 2), color: const Color(0xFF151515)),
            clipBehavior: Clip.antiAlias,
            child: (url != null && url.isNotEmpty) ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover) : const Icon(Icons.person, color: Colors.white70, size: 32),
          ),
          if (_uploading) const CircularProgressIndicator(strokeWidth: 2),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)));
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionTile({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outline.withValues(alpha: 0.2))),
      child: ListTile(onTap: onTap, leading: Icon(icon, color: cs.primary), title: Text(label, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500)), trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant)),
    );
  }
}
