import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../data/vehicles_api.dart';
import '../models/postal_address.dart';
import 'widgets/address_form_fields.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/providers/checkout_manager.dart';

class BookingFormPage extends ConsumerStatefulWidget {
  final Service service;
  final String? initialLocation; // 'home' or 'shop'
  const BookingFormPage({super.key, required this.service, this.initialLocation});

  @override
  ConsumerState<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends ConsumerState<BookingFormPage> {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _flatCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _selectedState;
  final _notesCtrl = TextEditingController();

  final _vehiclesApi = VehiclesApi();

  List<VehicleTypeItem> _vehicleTypes = [];
  VehicleTypeItem? _selectedType;
  List<VehicleBrandItem> _vehicleBrands = [];
  VehicleBrandItem? _selectedBrand;
  List<VehicleModelItem> _vehicleModels = [];
  VehicleModelItem? _selectedModel;

  String _serviceLocation = 'home';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  bool _initializedProfile = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
    if (widget.initialLocation == 'home' || widget.initialLocation == 'shop') {
      _serviceLocation = widget.initialLocation!;
    }
    
    // Defer riverpod reads to post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _syncWithProfile();
    });
  }

  void _syncWithProfile() {
    if (_initializedProfile) return;
    
    final authData = ref.read(authProvider);
    final profileData = ref.read(profileProvider).value;

    if (authData.phoneNumber != null) {
      _phoneCtrl.text = authData.phoneNumber!;
    }
    if (profileData != null) {
      _nameCtrl.text = profileData.fullName;
      if (profileData.email != null) _emailCtrl.text = profileData.email!;
      
      final defaultAddr = profileData.defaultAddress;
      if (defaultAddr != null) {
         _onAddressPicked(defaultAddr['id'] as int);
      }
    }
    _initializedProfile = true;
  }

  void _onAddressPicked(int? addressId) {
     ref.read(checkoutManagerProvider.notifier).selectAddress(addressId);
     if (addressId != null) {
        final profile = ref.read(profileProvider).value;
        final addr = profile?.addresses.firstWhere((a) => a['id'] == addressId, orElse: () => {});
        if (addr != null && addr.isNotEmpty) {
           _nameCtrl.text = addr['full_name'] ?? profile?.fullName ?? '';
           _phoneCtrl.text = addr['phone_number'] ?? ref.read(authProvider).phoneNumber ?? '';
           _flatCtrl.text = addr['flat_house_no'] ?? '';
           _areaCtrl.text = addr['area_street'] ?? '';
           _landmarkCtrl.text = addr['landmark'] ?? '';
           _cityCtrl.text = addr['town_city'] ?? '';
           _pincodeCtrl.text = addr['pincode'] ?? '';
           setState(() {
              _selectedState = addr['state'];
           });
        }
     } else {
       // Clear form if choosing "Manual"
       _flatCtrl.clear();
       _areaCtrl.clear();
       _landmarkCtrl.clear();
       _cityCtrl.clear();
       _pincodeCtrl.clear();
       setState(() { _selectedState = null; });
     }
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final items = await _vehiclesApi.getVehicleTypes();
      if (mounted) setState(() => _vehicleTypes = items);
    } catch (e) {
      _showSnack('Failed to load vehicle types: $e');
    }
  }

  Future<void> _loadVehicleBrands(int typeId) async {
    try {
      final items = await _vehiclesApi.getVehicleBrands(typeId);
      if (mounted) setState(() => _vehicleBrands = items);
    } catch (e) {
      _showSnack('Failed to load vehicle brands: $e');
    }
  }

  Future<void> _loadVehicleModels(int brandId) async {
    try {
      final items = await _vehiclesApi.getVehicleModels(brandId);
      if (mounted) setState(() => _vehicleModels = items);
    } catch (e) {
      _showSnack('Failed to load vehicle models: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: _selectedDate ?? now,
    );
    if (res != null) setState(() => _selectedDate = res);
  }

  Future<void> _pickTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (res != null) setState(() => _selectedTime = res);
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return _showSnack('Please enter your name');
    final effectivePhone = _phoneCtrl.text.trim();
    if (effectivePhone.isEmpty) return _showSnack('Please enter your phone number');
    if (_selectedModel == null) return _showSnack('Please select your vehicle model');
    if (_selectedDate == null) return _showSnack('Please select appointment date');
    if (_selectedTime == null) return _showSnack('Please select appointment time');

    final address = PostalAddress(
      fullName: _nameCtrl.text.trim(),
      phoneNumber: effectivePhone,
      flatHouseNo: _flatCtrl.text.trim(),
      areaStreet: _areaCtrl.text.trim(),
      landmark: _landmarkCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
      townCity: _cityCtrl.text.trim(),
      state: _selectedState ?? '',
    );

    final payload = {
      'customer_name': _nameCtrl.text.trim(),
      'customer_phone': effectivePhone,
      'customer_email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'vehicle_model_id': _selectedModel!.id,
      'service_ids': [widget.service.id],
      'service_location': _serviceLocation,
      'address': _serviceLocation == 'home' ? address.toFullString() : null,
      'address_details': _serviceLocation == 'home' ? address.toJson() : null,
      'appointment_date': _formatDate(_selectedDate!),
      'appointment_time': _formatTime(_selectedTime!),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      final result = await ref.read(checkoutManagerProvider.notifier).submitServiceBooking(bookingData: payload);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Booking Confirmed'),
          content: Text('Your booking #${result['id']} is created.\n'
              'Total: ₹${result['total_amount']}\n'
              'Status: ${result['booking_status']}\n'
              'Payment: ${result['payment_status']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            )
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutManagerProvider);
    final profileData = ref.watch(profileProvider).value;
    final isAuth = ref.watch(authProvider).isAuthenticated;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        title: const Text('Book Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),
            const SizedBox(height: 16),
            _inputCard(
              title: 'Customer Info',
              child: Column(
                children: [
                  _textField(_nameCtrl, 'Full Name'),
                  const SizedBox(height: 12),
                  // Lock phone if authenticated
                  if (isAuth)
                     _lockedField(_phoneCtrl.text.isEmpty ? 'Logged In User' : _phoneCtrl.text, Icons.phone)
                  else
                     _textField(_phoneCtrl, 'Phone Number', keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _textField(_emailCtrl, 'Email (optional)', keyboardType: TextInputType.emailAddress),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _inputCard(
              title: 'Vehicle Configuration',
              child: Column(
                children: [
                  DropdownButtonFormField<VehicleTypeItem>(
                    dropdownColor: card,
                    initialValue: _selectedType,
                    items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name, style: const TextStyle(color: Colors.white)))).toList(),
                    decoration: _inputDecoration('Select vehicle type'),
                    onChanged: (val) async {
                      setState(() {
                        _selectedType = val;
                        _selectedBrand = null;
                        _selectedModel = null;
                        _vehicleBrands = [];
                        _vehicleModels = [];
                      });
                      if (val != null) await _loadVehicleBrands(val.id);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<VehicleBrandItem>(
                    dropdownColor: card,
                    initialValue: _selectedBrand,
                    items: _vehicleBrands.map((b) => DropdownMenuItem(value: b, child: Text(b.name, style: const TextStyle(color: Colors.white)))).toList(),
                    decoration: _inputDecoration(_selectedType == null ? 'Select type first' : 'Select vehicle brand'),
                    onChanged: (val) async {
                      setState(() {
                        _selectedBrand = val;
                        _selectedModel = null;
                        _vehicleModels = [];
                      });
                      if (val != null) await _loadVehicleModels(val.id);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<VehicleModelItem>(
                    dropdownColor: card,
                    initialValue: _selectedModel,
                    items: _vehicleModels.map((m) => DropdownMenuItem(value: m, child: Text(m.name, style: const TextStyle(color: Colors.white)))).toList(),
                    decoration: _inputDecoration(_selectedBrand == null ? 'Select brand first' : 'Select vehicle model'),
                    onChanged: (val) => setState(() => _selectedModel = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _inputCard(
              title: 'Service Location',
              child: Row(
                children: [
                  _locationChip('home', 'Home'),
                  const SizedBox(width: 12),
                  _locationChip('shop', 'Workshop'),
                ],
              ),
            ),
            if (_serviceLocation == 'home') ...[
              const SizedBox(height: 16),
              _inputCard(
                title: 'Service Address',
                child: AddressFormFields(
                  nameCtrl: _nameCtrl, // Links to master customer name
                  phoneCtrl: _phoneCtrl, 
                  flatCtrl: _flatCtrl,
                  areaCtrl: _areaCtrl,
                  landmarkCtrl: _landmarkCtrl,
                  pincodeCtrl: _pincodeCtrl,
                  cityCtrl: _cityCtrl,
                  selectedState: _selectedState,
                  onStateChanged: (v) => setState(() => _selectedState = v),
                  compact: true,
                  savedAddresses: profileData?.addresses,
                  selectedAddressId: checkoutState.selectedAddressId,
                  onAddressSelected: _onAddressPicked,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _inputCard(
              title: 'Schedule',
              child: Row(
                children: [
                  Expanded(
                    child: _pickerButton(
                      label: _selectedDate == null ? 'Select date' : _formatDate(_selectedDate!),
                      icon: Icons.calendar_today,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pickerButton(
                      label: _selectedTime == null
                          ? 'Select time'
                          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                      icon: Icons.access_time,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _inputCard(
              title: 'Notes (optional)',
              child: _textField(_notesCtrl, 'Anything we should know?'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: checkoutState.isSubmitting ? null : _submit,
              child: checkoutState.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.build_circle, color: accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.service.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Starting at ', style: TextStyle(color: Colors.white70)),
                    if (widget.service.originalPrice != null && widget.service.originalPrice! > widget.service.price)
                      Text(
                        '₹${widget.service.originalPrice}.00 ',
                        style: const TextStyle(
                          color: Colors.white54,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 13,
                        ),
                      ),
                    Text('₹${widget.service.price}.00', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _inputCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return const InputDecoration().copyWith(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF141414),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: accent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint),
    );
  }
  
  Widget _lockedField(String value, IconData icon) {
     return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
  }

  Widget _pickerButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _locationChip(String value, String label) {
    final selected = _serviceLocation == value;
    return GestureDetector(
      onTap: () => setState(() => _serviceLocation = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
