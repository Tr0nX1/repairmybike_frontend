import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/staff_provider.dart';
import '../../../providers/vehicles_provider.dart';
import '../../../providers/services_provider.dart';
import '../../../data/app_state.dart';

class WalkInCreatorPage extends ConsumerStatefulWidget {
  const WalkInCreatorPage({super.key});

  @override
  ConsumerState<WalkInCreatorPage> createState() => _WalkInCreatorPageState();
}

class _WalkInCreatorPageState extends ConsumerState<WalkInCreatorPage> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Form Data
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  
  int? _selectedVehicleId;
  String? _selectedVehicleName;
  final List<int> _selectedServiceIds = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Walk-in Booking'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: _handleContinue,
            onStepCancel: _handleCancel,
            steps: [
              Step(
                title: const Text('Customer'),
                isActive: _currentStep >= 0,
                content: _buildCustomerStep(),
              ),
              Step(
                title: const Text('Vehicle'),
                isActive: _currentStep >= 1,
                content: _buildVehicleStep(),
              ),
              Step(
                title: const Text('Services'),
                isActive: _currentStep >= 2,
                content: _buildServicesStep(),
              ),
              Step(
                title: const Text('Schedule'),
                isActive: _currentStep >= 3,
                content: _buildScheduleStep(),
              ),
            ],
          ),
    );
  }

  Widget _buildCustomerStep() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
            hintText: 'e.g. 9876543210',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Customer Name',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email (Optional)',
            prefixIcon: Icon(Icons.email),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleStep() {
    // This is a simplified vehicle selector. In a real app, 
    // we'd fetch types/brands/models.
    final vehiclesAsync = ref.watch(vehicleTypesProvider); // Simplified for this demo
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Vehicle Model', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // Search/Dropdown for models would go here
        // For now, let's show a simple hint or mock selector
        InkWell(
          onTap: () => _pickVehicle(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.motorcycle),
                const SizedBox(width: 12),
                Text(_selectedVehicleName ?? 'Tap to select vehicle'),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesStep() {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    
    return categoriesAsync.when(
      data: (categories) => Column(
        children: categories.map((cat) => CheckboxListTile(
          title: Text(cat.name),
          value: _selectedServiceIds.contains(cat.id),
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _selectedServiceIds.add(cat.id);
              } else {
                _selectedServiceIds.remove(cat.id);
              }
            });
          },
        )).toList(),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildScheduleStep() {
    return Column(
      children: [
        ListTile(
          title: const Text('Appointment Date'),
          subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
        ListTile(
          title: const Text('Appointment Time'),
          subtitle: Text(_selectedTime.format(context)),
          trailing: const Icon(Icons.access_time),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            if (picked != null) setState(() => _selectedTime = picked);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Staff/Customer Notes',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  void _handleContinue() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitBooking();
    }
  }

  void _handleCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _pickVehicle() {
    // In a real app, this would push a selector screen
    // For now, let's mock a selection
    setState(() {
      _selectedVehicleId = 1; // Example ID
      _selectedVehicleName = 'Honda Activa 6G';
    });
  }

  Future<void> _submitBooking() async {
    if (_phoneController.text.isEmpty || _selectedVehicleId == null || _selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final api = ref.read(staffApiProvider);
      final bookingData = {
        'customer_name': _nameController.text,
        'customer_phone': _phoneController.text,
        'customer_email': _emailController.text,
        'vehicle_model_id': _selectedVehicleId,
        'service_ids': _selectedServiceIds,
        'service_location': 'shop',
        'appointment_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'appointment_time': '${_selectedTime.hour}:${_selectedTime.minute}',
        'payment_method': 'cash',
        'notes': _notesController.text,
      };

      final res = await api.createBooking(bookingData);
      
      if (res['error'] == false) {
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking created successfully')),
          );
          ref.invalidate(staffBookingsProvider('pending'));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create booking: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
