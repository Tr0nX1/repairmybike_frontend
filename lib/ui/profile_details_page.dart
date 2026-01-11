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
  static const Color bg = Color(0xFFFFFFFF); // White background as per image
  static const Color accent = Color(0xFFFFD814); // Amazon-like yellow
  static const Color fieldBg = Colors.white;
  static const Color border = Color(0xFFBBBBBB);
  static const Color textMain = Color(0xFF111111);

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
        // Update user profile name if changed
        final parts = name.split(' ');
        final first = parts.first;
        final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        await AuthApi().updateProfile(
          sessionToken: token,
          firstName: first,
          lastName: last,
        );

        // Add/Update address
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

      // Update local state
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

      if (widget.popOnSave) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      _show('Failed to save data: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF80D1D1).withOpacity(0.5), // Light teal header as per image
        elevation: 0,
        leading: const CloseButton(color: Colors.black54),
        title: const Text('Add a new address', style: TextStyle(color: textMain, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.black54)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Full name (First and Last name)'),
            _field(_nameCtrl),
            const SizedBox(height: 16),
            _label('Mobile number'),
            _field(_phoneCtrl, keyboardType: TextInputType.phone),
            const Text('May be used to assist delivery', style: TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.location_on, color: Colors.orange),
              label: const Text('Add location on map', style: TextStyle(color: Color(0xFF007185))),
            ),
            const SizedBox(height: 8),
            _label('Flat, House no., Building, Company, Apartment'),
            _field(_flatCtrl),
            const SizedBox(height: 16),
            _label('Area, Street, Sector, Village'),
            _field(_areaCtrl),
            const SizedBox(height: 16),
            _label('Landmark'),
            _field(_landmarkCtrl, hint: 'E.g. near apollo hospital'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Pincode'),
                      _field(_pincodeCtrl, hint: '6-digit Pincode', keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Town/City'),
                      _field(_cityCtrl),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('State'),
            _dropdown(),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isDefault, 
                  onChanged: (v) => setState(() => _isDefault = v ?? false),
                  activeColor: accent,
                  checkColor: Colors.black,
                ),
                const Text('Make this my default address'),
              ],
            ),
            const SizedBox(height: 16),
            _label('Delivery instructions (optional)'),
            _field(_instructionsCtrl, hint: 'Notes, preferences and more'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Add address', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: textMain)),
    );
  }

  Widget _field(TextEditingController ctrl, {String? hint, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE47911), width: 2)),
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState,
          isExpanded: true,
          hint: const Text('Select'),
          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selectedState = v),
        ),
      ),
    );
  }
}
