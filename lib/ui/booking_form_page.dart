import 'package:flutter/material.dart';
import '../models/service.dart';
import '../data/vehicles_api.dart';
import '../data/booking_api.dart';
import '../data/app_state.dart';

class BookingFormPage extends StatefulWidget {
  final Service service;
  final String? initialLocation; // 'home' or 'shop'
  const BookingFormPage({super.key, required this.service, this.initialLocation});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _vehiclesApi = VehiclesApi();
  final _bookingApi = BookingApi();

  List<VehicleTypeItem> _vehicleTypes = [];
  VehicleTypeItem? _selectedType;
  List<VehicleBrandItem> _vehicleBrands = [];
  VehicleBrandItem? _selectedBrand;
  List<VehicleModelItem> _vehicleModels = [];
  VehicleModelItem? _selectedModel;

  String _serviceLocation = 'home';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _submitting = false;
  bool _autoName = false;
  bool _autoPhone = false;
  bool _autoEmail = false;
  bool _autoAddress = false;
  bool _autoType = false;
  bool _autoBrand = false;
  bool _autoModel = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
    // Initialize location from detail page if provided
    if (widget.initialLocation == 'home' || widget.initialLocation == 'shop') {
      _serviceLocation = widget.initialLocation!;
    }
    // Autofill from AppState
    final authPhone = AppState.phoneNumber;
    if (authPhone != null && authPhone.isNotEmpty) {
      _phoneCtrl.text = authPhone;
      _autoPhone = true;
    }
    if ((AppState.fullName ?? '').isNotEmpty) {
      _nameCtrl.text = AppState.fullName!;
      _autoName = true;
    }
    if ((AppState.email ?? '').isNotEmpty) {
      _emailCtrl.text = AppState.email!;
      _autoEmail = true;
    }
    if ((AppState.address ?? '').isNotEmpty) {
      _addressCtrl.text = AppState.address!;
      _autoAddress = true;
    }
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final items = await _vehiclesApi.getVehicleTypes();
      setState(() {
        _vehicleTypes = items;
      });
      // Try auto-select type
      final vt = AppState.vehicleType;
      if (vt != null && vt.isNotEmpty) {
        final match = _vehicleTypes.firstWhere(
          (t) => t.name.toLowerCase() == vt.toLowerCase(),
          orElse: () => _vehicleTypes.isNotEmpty ? _vehicleTypes.first : null as VehicleTypeItem,
        );
        if (match != null) {
          setState(() {
            _selectedType = match;
            _autoType = true;
          });
          await _loadVehicleBrands(match.id);
        }
      }
    } catch (e) {
      _showSnack('Failed to load vehicle types: $e');
    }
  }

  Future<void> _loadVehicleBrands(int typeId) async {
    try {
      final items = await _vehiclesApi.getVehicleBrands(typeId);
      setState(() {
        _vehicleBrands = items;
      });
      final vb = AppState.vehicleBrand;
      if (vb != null && vb.isNotEmpty) {
        final match = _vehicleBrands.firstWhere(
          (b) => b.name.toLowerCase() == vb.toLowerCase(),
          orElse: () => _vehicleBrands.isNotEmpty ? _vehicleBrands.first : null as VehicleBrandItem,
        );
        if (match != null) {
          setState(() {
            _selectedBrand = match;
            _autoBrand = true;
          });
          await _loadVehicleModels(match.id);
        }
      }
    } catch (e) {
      _showSnack('Failed to load vehicle brands: $e');
    }
  }

  Future<void> _loadVehicleModels(int brandId) async {
    try {
      final items = await _vehiclesApi.getVehicleModels(brandId);
      setState(() {
        _vehicleModels = items;
      });
      final vm = AppState.vehicleName;
      if (vm != null && vm.isNotEmpty) {
        final match = _vehicleModels.firstWhere(
          (m) => m.name.toLowerCase() == vm.toLowerCase(),
          orElse: () => _vehicleModels.isNotEmpty ? _vehicleModels.first : null as VehicleModelItem,
        );
        if (match != null) {
          setState(() {
            _selectedModel = match;
            _autoModel = true;
          });
        }
      }
    } catch (e) {
      _showSnack('Failed to load vehicle models: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: _selectedDate ?? now,
    );
    if (res != null) {
      setState(() => _selectedDate = res);
    }
  }

  Future<void> _pickTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (res != null) {
      setState(() => _selectedTime = res);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
      ;

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your name');
      return;
    }
    final effectivePhone = (AppState.phoneNumber ?? _phoneCtrl.text.trim());
    if (effectivePhone.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }
    if (_selectedModel == null) {
      _showSnack('Please select your vehicle model');
      return;
    }
    if (_selectedDate == null) {
      _showSnack('Please select appointment date');
      return;
    }
    if (_selectedTime == null) {
      _showSnack('Please select appointment time');
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = await _bookingApi.createBooking(
        customerName: _nameCtrl.text.trim(),
        customerPhone: effectivePhone,
        customerEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        vehicleModelId: _selectedModel!.id,
        serviceIds: [widget.service.id],
        serviceLocation: _serviceLocation,
        address: _serviceLocation == 'home' ? _addressCtrl.text.trim() : null,
        appointmentDate: _formatDate(_selectedDate!),
        appointmentTime: _formatTime(_selectedTime!),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      // NOTE: For payment gateway integration later, after creating booking
      // you can create a payment order then verify post transaction.
      // Currently cash-only; booking.payment_status will be pending.

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Booking Created'),
            content: Text('Your booking #${data['id']} is created.\n'
                'Total: ₹${data['total_amount']}\n'
                'Status: ${data['booking_status']}\n'
                'Payment: ${data['payment_status']}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              )
            ],
          );
        },
      );

      // Remember phone so Bookings tab can auto-fetch.
      await AppState.setLastCustomerPhone(effectivePhone);
      // Persist current vehicle/profile for consistency
      await AppState.setVehicleForPhone(
        phone: effectivePhone,
        type: _selectedType?.name,
        brand: _selectedBrand?.name,
        name: _selectedModel?.name,
      );
      await AppState.setProfile(
        name: _nameCtrl.text.trim(),
        addr: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        mail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );

      Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Failed to create booking: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Hide phone entry when authenticated; show read-only chip
                  if ((AppState.phoneNumber ?? '').isEmpty)
                    _textField(_phoneCtrl, 'Phone Number', keyboardType: TextInputType.phone)
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          border: Border.all(color: border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(AppState.phoneNumber ?? '', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _textField(_emailCtrl, 'Email (optional)', keyboardType: TextInputType.emailAddress),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _inputCard(
              title: 'Vehicle Type',
              child: DropdownButtonFormField<VehicleTypeItem>(
                dropdownColor: card,
                value: _selectedType,
                items: _vehicleTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name, style: const TextStyle(color: Colors.white))))
                    .toList(),
                decoration: _inputDecoration('Select vehicle type'),
                onChanged: (val) async {
                  setState(() {
                    _selectedType = val;
                    _selectedBrand = null;
                    _selectedModel = null;
                    _vehicleBrands = [];
                    _vehicleModels = [];
                  });
                  if (val != null) {
                    await _loadVehicleBrands(val.id);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            _inputCard(
              title: 'Vehicle Brand',
              child: DropdownButtonFormField<VehicleBrandItem>(
                dropdownColor: card,
                value: _selectedBrand,
                items: _vehicleBrands
                    .map((b) => DropdownMenuItem(value: b, child: Text(b.name, style: const TextStyle(color: Colors.white))))
                    .toList(),
                decoration: _inputDecoration(_selectedType == null ? 'Select type first' : 'Select vehicle brand'),
                onChanged: (val) async {
                  setState(() {
                    _selectedBrand = val;
                    _selectedModel = null;
                    _vehicleModels = [];
                  });
                  if (val != null) {
                    await _loadVehicleModels(val.id);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            _inputCard(
              title: 'Vehicle Model',
              child: DropdownButtonFormField<VehicleModelItem>(
                dropdownColor: card,
                value: _selectedModel,
                items: _vehicleModels
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name, style: const TextStyle(color: Colors.white))))
                    .toList(),
                decoration: _inputDecoration(_selectedBrand == null ? 'Select brand first' : 'Select vehicle model'),
                onChanged: (val) => setState(() => _selectedModel = val),
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
                title: 'Address',
                child: _textField(_addressCtrl, 'Your address'),
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
              onPressed: _submitting ? null : _submit,
              child: _submitting
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
                Text('Starting at ₹${widget.service.price}.00', style: const TextStyle(color: Colors.white70)),
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
          Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              if ((title == 'Vehicle Type' && _autoType) ||
                  (title == 'Vehicle Brand' && _autoBrand) ||
                  (title == 'Vehicle Model' && _autoModel))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x331EC8FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent),
                  ),
                  child: const Text('Auto-filled', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
            ],
          ),
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
    // Visual indicator for auto-populated fields
    final isAuto = (ctrl == _nameCtrl && _autoName) ||
        (ctrl == _phoneCtrl && _autoPhone) ||
        (ctrl == _emailCtrl && _autoEmail) ||
        (ctrl == _addressCtrl && _autoAddress);
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: isAuto ? const Icon(Icons.auto_awesome, color: Colors.cyan) : null,
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
