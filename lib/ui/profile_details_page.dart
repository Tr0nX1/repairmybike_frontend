import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/auth_api.dart';
import 'main_shell.dart';

class ProfileDetailsPage extends StatefulWidget {
  final bool popOnSave;
  final String? phoneHint;
  const ProfileDetailsPage({super.key, this.popOnSave = false, this.phoneHint});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  late final _nameCtrl = TextEditingController(text: AppState.fullName ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.phoneHint ?? AppState.phoneNumber ?? '');
  late final _flatCtrl = TextEditingController(text: AppState.addrFlat ?? '');
  late final _areaCtrl = TextEditingController(text: AppState.addrArea ?? '');
  late final _landmarkCtrl = TextEditingController(text: AppState.addrLandmark ?? '');
  late final _pincodeCtrl = TextEditingController(text: AppState.addrPincode ?? '');
  late final _cityCtrl = TextEditingController(text: AppState.addrCity ?? '');
  late final _instructionsCtrl = TextEditingController(text: AppState.addrInstructions ?? '');
  
  String? _selectedState = AppState.addrState;
  bool _isDefault = true;
  bool _saving = false;

  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Chandigarh', 'Other'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _flatCtrl.dispose();
    _areaCtrl.dispose();
    _landmarkCtrl.dispose();
    _pincodeCtrl.dispose();
    _cityCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final flat = _flatCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    final landmark = _landmarkCtrl.text.trim();
    final pin = _pincodeCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = _selectedState;
    final instr = _instructionsCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || flat.isEmpty || area.isEmpty || pin.isEmpty || city.isEmpty || state == null) {
      _show('Please fill all required fields');
      return;
    }

    setState(() => _saving = true);

    try {
      final token = AppState.sessionToken ?? '';
      if (token.isNotEmpty) {
        final parts = name.split(' ');
        final first = parts.first;
        final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        await AuthApi().updateProfile(
          sessionToken: token,
          firstName: first,
          lastName: last,
        );

        await AuthApi().addAddress(
          sessionToken: token,
          fullName: name,
          phone: phone,
          flat: flat,
          area: area,
          landmark: landmark,
          pincode: pin,
          city: city,
          state: state,
          isDefault: _isDefault,
          instructions: instr,
        );
      }

      await AppState.setProfile(
        name: name,
        f: flat,
        a: area,
        l: landmark,
        p: pin,
        c: city,
        s: state,
        i: instr,
        ph: phone,
      );

      if (mounted) {
        if (widget.popOnSave) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        }
      }
    } catch (e) {
      _show('Failed to save data: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: colorScheme.onSurface,
        ),
        title: Text(
          'Edit Profile', 
          style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Personal Info'),
            _label('Full Name'),
            _field(_nameCtrl, prefixIcon: Icons.person_outline),
            const SizedBox(height: 16),
            _label('Mobile Number'),
            _field(_phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined),
            
            const SizedBox(height: 32),
            _sectionHeader('Address Details'),
            _label('Flat, House no., Building'),
            _field(_flatCtrl, prefixIcon: Icons.home_outlined),
            const SizedBox(height: 16),
            _label('Area, Street, Sector'),
            _field(_areaCtrl, prefixIcon: Icons.map_outlined),
            const SizedBox(height: 16),
            _label('Landmark (Optional)'),
            _field(_landmarkCtrl, hint: 'E.g. near hospital', prefixIcon: Icons.store_outlined),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Pincode'),
                      _field(_pincodeCtrl, hint: '6-digit', keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('City'),
                      _field(_cityCtrl),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('State'),
            _dropdown(),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                    value: _isDefault, 
                    onChanged: (v) => setState(() => _isDefault = v ?? false),
                    activeColor: colorScheme.primary,
                    checkColor: colorScheme.onPrimary,
                    side: BorderSide(color: colorScheme.outline),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Default address', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8))),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _saving 
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
                  : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(
          color: colorScheme.primary, 
          fontSize: 12, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.2
        )
      ),
    );
  }

  Widget _label(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
    );
  }

  Widget _field(TextEditingController ctrl, {String? hint, TextInputType keyboardType = TextInputType.text, IconData? prefixIcon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: colorScheme.onSurface.withOpacity(0.5)) : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
      ),
    );
  }

  Widget _dropdown() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          hint: Text('Select State', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3))),
          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: colorScheme.onSurface)))).toList(),
          onChanged: (v) => setState(() => _selectedState = v),
        ),
      ),
    );
  }
}
