import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_error.dart';
import '../models/service.dart';
import '../data/app_state.dart';
import '../data/vehicles_api.dart';
import '../models/postal_address.dart';
import 'widgets/address_form_fields.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/providers/checkout_manager.dart';

class BookingFormPage extends ConsumerStatefulWidget {
  final Service service;
  final String? initialLocation;
  const BookingFormPage({super.key, required this.service, this.initialLocation});

  @override
  ConsumerState<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends ConsumerState<BookingFormPage> {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  final _formKey = GlobalKey<FormState>();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentProfile = ref.read(profileProvider).value;
      if (currentProfile == null) {
        ref.read(profileProvider.notifier).fetchProfile();
      } else {
        _fillFormFromProfile(currentProfile);
      }
    });
  }

  void _fillFormFromProfile(UserProfile profile) {
    if (_nameCtrl.text.isEmpty) _nameCtrl.text = profile.fullName;
    final authPhone = ref.read(authProvider).phoneNumber;
    if (_phoneCtrl.text.isEmpty && authPhone != null) _phoneCtrl.text = authPhone;
    if (_emailCtrl.text.isEmpty && profile.email != null) _emailCtrl.text = profile.email!;
    if (_flatCtrl.text.isEmpty && profile.defaultAddress != null) {
      _onAddressPicked(profile.defaultAddress!['id'] as int?);
    }
    if (_selectedModel == null &&
        AppState.vehicleModelId != null &&
        _vehicleTypes.isNotEmpty) {
      _preselectVehicleFromAppState();
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
           setState(() => _selectedState = addr['state']);
        }
     } else {
       _flatCtrl.clear(); _areaCtrl.clear(); _landmarkCtrl.clear(); _cityCtrl.clear(); _pincodeCtrl.clear();
       setState(() => _selectedState = null);
     }
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final items = await _vehiclesApi.getVehicleTypes();
      if (!mounted) return;
      setState(() => _vehicleTypes = items);
      if (_selectedModel == null && AppState.vehicleModelId != null) {
        await _preselectVehicleFromAppState();
      }
    } catch (e) { _showSnack('Error loading vehicle types'); }
  }

  Future<void> _loadVehicleBrands(int id) async {
    try {
      final items = await _vehiclesApi.getVehicleBrands(id);
      if (mounted) setState(() => _vehicleBrands = items);
    } catch (e) { _showSnack('Error loading brands'); }
  }

  Future<void> _loadVehicleModels(int id) async {
    try {
      final items = await _vehiclesApi.getVehicleModels(id);
      if (mounted) setState(() => _vehicleModels = items);
    } catch (e) { _showSnack('Error loading models'); }
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  String _normalizeVehicleLabel(String? value) =>
      (value ?? '').trim().toLowerCase();

  void _seedSelectedVehicleFromAppState({
    VehicleModelItem? model,
    int? brandId,
  }) {
    final modelId = model?.id ?? AppState.vehicleModelId;
    if (modelId == null) return;

    final typeName = model?.vehicleTypeName.isNotEmpty == true
        ? model!.vehicleTypeName
        : AppState.vehicleType ?? '';
    final brandName = model?.brandName.isNotEmpty == true
        ? model!.brandName
        : AppState.vehicleBrand ?? '';
    final vehicleName = model?.name.isNotEmpty == true
        ? model!.name
        : AppState.vehicleName ?? 'Selected vehicle';

    final fallbackType = VehicleTypeItem(
      id: -1,
      name: typeName.isNotEmpty ? typeName : 'Selected type',
    );
    final fallbackBrand = VehicleBrandItem(
      id: brandId ?? model?.vehicleBrandId ?? -1,
      vehicleTypeId: fallbackType.id,
      vehicleTypeName: fallbackType.name,
      name: brandName.isNotEmpty ? brandName : 'Selected brand',
    );
    final fallbackModel = model ??
        VehicleModelItem(
          id: modelId,
          vehicleBrandId: fallbackBrand.id,
          brandName: fallbackBrand.name,
          vehicleTypeName: fallbackType.name,
          name: vehicleName,
          image: AppState.vehicleImageUrl,
        );

    setState(() {
      if (!_vehicleTypes.any((t) => t.id == fallbackType.id)) {
        _vehicleTypes = [..._vehicleTypes, fallbackType];
      }
      _selectedType = fallbackType;
      _vehicleBrands = [fallbackBrand];
      _selectedBrand = fallbackBrand;
      _vehicleModels = [fallbackModel];
      _selectedModel = fallbackModel;
    });
  }

  Future<void> _preselectVehicleFromAppState() async {
    final modelId = AppState.vehicleModelId;
    if (modelId == null || !mounted) return;

    try {
      final model = await _vehiclesApi.getVehicleModelById(modelId);
      if (!mounted) return;

      final matchingType = _firstWhereOrNull(
        _vehicleTypes,
        (t) =>
            _normalizeVehicleLabel(t.name) ==
                _normalizeVehicleLabel(model.vehicleTypeName) ||
            _normalizeVehicleLabel(t.name) ==
                _normalizeVehicleLabel(AppState.vehicleType),
      );
      if (matchingType == null) {
        _seedSelectedVehicleFromAppState(model: model);
        return;
      }

      final brands = await _vehiclesApi.getVehicleBrands(matchingType.id);
      if (!mounted) return;

      final matchingBrand = _firstWhereOrNull(
        brands,
        (b) =>
            b.id == model.vehicleBrandId ||
            _normalizeVehicleLabel(b.name) ==
                _normalizeVehicleLabel(model.brandName) ||
            _normalizeVehicleLabel(b.name) ==
                _normalizeVehicleLabel(AppState.vehicleBrand),
      );
      if (matchingBrand == null) {
        _seedSelectedVehicleFromAppState(
          model: model,
          brandId: model.vehicleBrandId,
        );
        return;
      }

      final models = await _vehiclesApi.getVehicleModels(model.vehicleBrandId);
      if (!mounted) return;

      final matched = _firstWhereOrNull(models, (m) => m.id == modelId);
      if (matched == null) return;

      setState(() {
        _selectedType = matchingType;
        _vehicleBrands = brands;
        _selectedBrand = matchingBrand;
        _vehicleModels = models;
        _selectedModel = matched;
      });
    } catch (_) {
      if (mounted) _seedSelectedVehicleFromAppState();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.white54),
      filled: true, fillColor: const Color(0xFF141414),
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: border), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: accent), borderRadius: BorderRadius.circular(12)),
      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(12)),
      focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent, width: 2), borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _textFormField(TextEditingController ctrl, String hint, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(controller: ctrl, keyboardType: keyboardType, validator: validator, style: const TextStyle(color: Colors.white), decoration: _inputDecoration(hint));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vehicleId = _selectedModel?.id ?? AppState.vehicleModelId;
    if (vehicleId == null) return _showSnack('Select vehicle model');
    if (_selectedDate == null || _selectedTime == null) return _showSnack('Select schedule');

    final address = PostalAddress(
      fullName: _nameCtrl.text.trim(), phoneNumber: _phoneCtrl.text.trim(),
      flatHouseNo: _flatCtrl.text.trim(), areaStreet: _areaCtrl.text.trim(),
      landmark: _landmarkCtrl.text.trim(), pincode: _pincodeCtrl.text.trim(),
      townCity: _cityCtrl.text.trim(), state: _selectedState ?? '',
    );

    final payload = {
      'customer_name': _nameCtrl.text.trim(), 'customer_phone': _phoneCtrl.text.trim(),
      'customer_email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'vehicle_model_id': vehicleId, 'service_ids': [widget.service.id],
      'service_location': _serviceLocation,
      'address': _serviceLocation == 'home' ? address.toFullString() : null,
      'address_details': _serviceLocation == 'home' ? address.toJson() : null,
      'appointment_date': '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      'appointment_time': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      final res = await ref.read(checkoutManagerProvider.notifier).submitServiceBooking(bookingData: payload);
      if (mounted) context.go('/booking-confirmation', extra: res);
    } catch (e) { if (mounted) _showSnack(AppError.sanitize(e)); }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserProfile?>>(profileProvider, (prev, next) {
      if (!_initializedProfile && next.value != null) _fillFormFromProfile(next.value!);
    });

    final checkoutState = ref.watch(checkoutManagerProvider);
    final profileData = ref.watch(profileProvider).value;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: const Color(0xFF071A1D), title: const Text('Book Service')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _inputCard(title: 'Customer Info', child: Column(children: [
                _textFormField(_nameCtrl, 'Full Name', validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                const SizedBox(height: 12),
                _textFormField(_phoneCtrl, 'Phone', keyboardType: TextInputType.phone, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
              ])),
              const SizedBox(height: 16),
              _inputCard(title: 'Vehicle', child: Column(children: [
                DropdownButtonFormField<VehicleTypeItem>(
                  dropdownColor: card,
                  decoration: _inputDecoration('Type'),
                  value: _selectedType,
                  items: _vehicleTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedType = v;
                      _selectedBrand = null;
                      _selectedModel = null;
                      _vehicleBrands = [];
                      _vehicleModels = [];
                    });
                    if (v != null) _loadVehicleBrands(v.id);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VehicleBrandItem>(
                  dropdownColor: card,
                  decoration: _inputDecoration('Brand'),
                  value: _selectedBrand,
                  items: _vehicleBrands
                      .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedBrand = v;
                      _selectedModel = null;
                      _vehicleModels = [];
                    });
                    if (v != null) _loadVehicleModels(v.id);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VehicleModelItem>(
                  dropdownColor: card,
                  decoration: _inputDecoration('Model'),
                  value: _selectedModel,
                  items: _vehicleModels
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedModel = v),
                ),
              ])),
              const SizedBox(height: 16),
              _inputCard(title: 'Location', child: Row(children: [
                _chip('home', 'Home'), const SizedBox(width: 12), _chip('shop', 'Workshop'),
              ])),
              if (_serviceLocation == 'home') ...[
                const SizedBox(height: 16),
                _inputCard(title: 'Address', child: AddressFormFields(
                  nameCtrl: _nameCtrl, phoneCtrl: _phoneCtrl, flatCtrl: _flatCtrl, areaCtrl: _areaCtrl,
                  landmarkCtrl: _landmarkCtrl, pincodeCtrl: _pincodeCtrl, cityCtrl: _cityCtrl,
                  selectedState: _selectedState, onStateChanged: (v) => setState(() => _selectedState = v),
                  savedAddresses: profileData?.addresses, selectedAddressId: checkoutState.selectedAddressId,
                  onAddressSelected: _onAddressPicked, compact: true,
                )),
              ],
              const SizedBox(height: 16),
              _inputCard(title: 'Schedule', child: Row(children: [
                Expanded(child: _pickBtn(_selectedDate == null ? 'Date' : 'Date selected', Icons.calendar_today, () async {
                   final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)), initialDate: DateTime.now());
                   if (d != null) setState(() => _selectedDate = d);
                })),
                const SizedBox(width: 12),
                Expanded(child: _pickBtn(_selectedTime == null ? 'Time' : 'Time selected', Icons.access_time, () async {
                   final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                   if (t != null) setState(() => _selectedTime = t);
                })),
              ])),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
        onPressed: checkoutState.isSubmitting ? null : _submit,
        child: checkoutState.isSubmitting ? const CircularProgressIndicator() : const Text('Confirm Booking'),
      ))),
    );
  }

  Widget _inputCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), child,
      ]),
    );
  }

  Widget _chip(String val, String label) {
    final sel = _serviceLocation == val;
    return GestureDetector(
      onTap: () => setState(() => _serviceLocation = val),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: sel ? accent : card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)), child: Text(label, style: TextStyle(color: sel ? Colors.black : Colors.white))),
    );
  }

  Widget _pickBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(12), border: Border.all(color: border)), child: Row(children: [Icon(icon, size: 16, color: Colors.white54), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white70))])));
  }
}
