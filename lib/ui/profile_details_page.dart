import 'package:flutter/material.dart';
import '../data/app_state.dart';
import 'main_shell.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  final _nameCtrl = TextEditingController(text: AppState.fullName ?? '');
  final _addrCtrl = TextEditingController(text: AppState.address ?? '');
  final _emailCtrl = TextEditingController(text: AppState.email ?? '');
  final _avatarCtrl = TextEditingController(text: AppState.avatarUrl ?? '');
  final _vehicleCtrl = TextEditingController(text: AppState.vehicleName ?? '');
  final _phoneCtrl = TextEditingController(text: AppState.phoneNumber ?? '');

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _emailCtrl.dispose();
    _avatarCtrl.dispose();
    _vehicleCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final addr = _addrCtrl.text.trim();
    final mail = _emailCtrl.text.trim();
    final avatar = _avatarCtrl.text.trim();
    final vehicle = _vehicleCtrl.text.trim();
    if (name.isEmpty) {
      _show('Please enter your name');
      return;
    }
    if (addr.isEmpty) {
      _show('Please enter your address');
      return;
    }
    setState(() => _saving = true);
    AppState.setProfile(name: name, addr: addr, mail: mail.isEmpty ? null : mail);
    AppState.setAvatarUrl(avatar.isEmpty ? null : avatar);
    if (vehicle.isNotEmpty) AppState.setVehicleName(vehicle);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        title: const Text('Your Details'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field('Full name', _nameCtrl, Icons.person),
              const SizedBox(height: 12),
              _field('Phone (from login)', _phoneCtrl, Icons.phone, enabled: false),
              const SizedBox(height: 12),
              _field('Address', _addrCtrl, Icons.home, minLines: 2, maxLines: 4),
              const SizedBox(height: 12),
              _field('Email (optional)', _emailCtrl, Icons.email),
              const SizedBox(height: 12),
              _field('Avatar URL (optional)', _avatarCtrl, Icons.image),
              const SizedBox(height: 12),
              _field('Vehicle you have', _vehicleCtrl, Icons.directions_bike),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: accent,
                  elevation: 0,
                  side: const BorderSide(color: accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl, IconData icon,
      {int minLines = 1, int maxLines = 1, bool enabled = true}) {
    return TextField(
      controller: ctrl,
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF151515),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
      ),
    );
  }
}
