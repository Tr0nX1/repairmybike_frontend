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
  
  // New props for saved address selection
  final List<Map<String, dynamic>>? savedAddresses;
  final int? selectedAddressId;
  final Function(int?)? onAddressSelected;
  
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
    this.savedAddresses,
    this.selectedAddressId,
    this.onAddressSelected,
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
    // If an address is selected, disable fields to show it's locked to the profile
    final bool isReadOnly = selectedAddressId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (savedAddresses != null && savedAddresses!.isNotEmpty) ...[
          const Text('Select saved address:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAddressChip(null, 'Manual'),
                ...savedAddresses!.map((addr) {
                  final id = addr['id'] as int;
                  final label = addr['label'] ?? addr['address_type'] ?? 'Address';
                  return _buildAddressChip(id, label);
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isReadOnly)
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                   Icon(Icons.lock, size: 14, color: Colors.green),
                   SizedBox(width: 6),
                   Text('Using saved address from profile.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
        ],

        _buildTextField(nameCtrl, 'Full Name', Icons.person_outline,
            readOnly: isReadOnly,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
        const SizedBox(height: 12),
        _buildTextField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
            readOnly: isReadOnly,
            keyboardType: TextInputType.phone,
            validator: (v) {
              final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (s.isEmpty) return 'Phone is required';
              return s.length < 10 ? 'Enter at least 10 digits' : null;
            }),
        const SizedBox(height: 12),
        _buildTextField(flatCtrl, 'Flat, House no., Building', Icons.home_outlined,
            readOnly: isReadOnly,
            validator: (v) => (v == null || v.trim().length < 2) ? 'Min 2 chars' : null),
        const SizedBox(height: 12),
        _buildTextField(areaCtrl, 'Area, Street, Sector', Icons.map_outlined,
            readOnly: isReadOnly,
            validator: (v) => (v == null || v.trim().length < 5) ? 'Min 5 chars' : null),
        const SizedBox(height: 12),
        _buildTextField(landmarkCtrl, 'Landmark (optional)', Icons.location_on_outlined, readOnly: isReadOnly),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(pincodeCtrl, 'Pincode', Icons.pin_drop_outlined,
                  readOnly: isReadOnly,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return s.length != 6 ? 'Exactly 6 digits' : null;
                  }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(cityCtrl, 'Town/City', Icons.location_city_outlined,
                  readOnly: isReadOnly,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStateDropdown(isReadOnly: isReadOnly),
      ],
    );
  }

  Widget _buildAddressChip(int? id, String label) {
    final isSelected = selectedAddressId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (onAddressSelected != null) onAddressSelected!(id);
        },
        selectedColor: const Color(0xFF01C9F5),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFF2A2A2A)),
        ),
      ),
    );
  }

  Widget _buildSavedAddressDropdown(BuildContext context) {
     return const SizedBox.shrink(); // Replaced by chips
  }

  Widget _buildTextField(
    TextEditingController ctrl, 
    String label, 
    IconData icon,
    {TextInputType? keyboardType, String? Function(String?)? validator, bool readOnly = false}
  ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.white54 : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: readOnly ? Colors.white54 : Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: readOnly ? Colors.white24 : Colors.grey),
        filled: true,
        fillColor: readOnly ? const Color(0xFF0A0A0A) : const Color(0xFF141414),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: readOnly ? Colors.transparent : const Color(0xFF2A2A2A))
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildStateDropdown({bool isReadOnly = false}) {
    // If read-only, we just display it as a text field so it can't be interacted with
    if (isReadOnly) {
       return _buildTextField(
         TextEditingController(text: selectedState ?? ''),
         'State',
         Icons.public_outlined,
         readOnly: true,
       );
    }
    return DropdownButtonFormField<String>(
      initialValue: selectedState,
      decoration: InputDecoration(
        labelText: 'State',
        prefixIcon: const Icon(Icons.public_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A))
        ),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: const Color(0xFF1C1C1C),
      items: states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
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
