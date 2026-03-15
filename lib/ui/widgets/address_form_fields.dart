import 'package:flutter/material.dart';
import '../../models/postal_address.dart';

class AddressFormFields extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController flatCtrl;
  final TextEditingController areaCtrl;
  final TextEditingController landmarkCtrl;
  final TextEditingController pincodeCtrl;
  final TextEditingController cityCtrl;
  final String? selectedState;
  final Function(String?) onStateChanged;
  final bool compact;

  const AddressFormFields({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.flatCtrl,
    required this.areaCtrl,
    required this.landmarkCtrl,
    required this.pincodeCtrl,
    required this.cityCtrl,
    required this.selectedState,
    required this.onStateChanged,
    this.compact = false,
  });

  static final List<String> states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Chandigarh', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(nameCtrl, 'Full Name', Icons.person_outline,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
        const SizedBox(height: 12),
        _buildTextField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return s.length < 10 ? 'Enter a valid phone' : null;
            }),
        const SizedBox(height: 12),
        _buildTextField(flatCtrl, 'Flat, House no., Building', Icons.home_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        const SizedBox(height: 12),
        _buildTextField(areaCtrl, 'Area, Street, Sector', Icons.map_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        const SizedBox(height: 12),
        _buildTextField(landmarkCtrl, 'Landmark (optional)', Icons.location_on_outlined),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(pincodeCtrl, 'Pincode', Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return s.length < 6 ? 'Enter valid pincode' : null;
                  }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(cityCtrl, 'Town/City', Icons.location_city_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStateDropdown(),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedState,
      decoration: InputDecoration(
        labelText: 'State',
        prefixIcon: const Icon(Icons.public_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onStateChanged,
      validator: (v) => v == null ? 'Select state' : null,
    );
  }

  PostalAddress toAddress() {
    return PostalAddress(
      fullName: nameCtrl.text.trim(),
      phoneNumber: phoneCtrl.text.trim(),
      flatHouseNo: flatCtrl.text.trim(),
      areaStreet: areaCtrl.text.trim(),
      landmark: landmarkCtrl.text.trim(),
      pincode: pincodeCtrl.text.trim(),
      townCity: cityCtrl.text.trim(),
      state: selectedState ?? '',
    );
  }
}
