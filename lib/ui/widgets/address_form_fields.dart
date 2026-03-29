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
          _buildSavedAddressDropdown(context),
          const SizedBox(height: 16),
          if (isReadOnly)
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                   Icon(Icons.lock, size: 14, color: Colors.green),
                   SizedBox(width: 6),
                   Text('Using saved address from your profile.', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
              return s.length < 10 ? 'Enter a valid phone' : null;
            }),
        const SizedBox(height: 12),
        _buildTextField(flatCtrl, 'Flat, House no., Building', Icons.home_outlined,
            readOnly: isReadOnly,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        const SizedBox(height: 12),
        _buildTextField(areaCtrl, 'Area, Street, Sector', Icons.map_outlined,
            readOnly: isReadOnly,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
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
                    return s.length < 6 ? 'Enter valid pincode' : null;
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

  Widget _buildSavedAddressDropdown(BuildContext context) {
    return DropdownButtonFormField<int?>(
      key: ValueKey(selectedAddressId),
      initialValue: selectedAddressId,
      decoration: InputDecoration(
        labelText: 'Saved Addresses',
        prefixIcon: const Icon(Icons.bookmarks_outlined, size: 20, color: Color(0xFF01C9F5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: const Color(0xFF141414),
      ),
      dropdownColor: const Color(0xFF1C1C1C),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Enter a new address manually'),
        ),
        ...savedAddresses!.map((addr) {
          final addrIdInfo = addr['id'];
          int? id;
          if (addrIdInfo is int) {
            id = addrIdInfo;
          } else if (addrIdInfo != null) {
            id = int.tryParse(addrIdInfo.toString());
          }
          final type = addr['address_type'] ?? 'Address';
          final flat = addr['flat_house_no'] ?? '';
          final text = '$type: $flat, ${addr['town_city']}';
          return DropdownMenuItem<int?>(
            value: id,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }),
      ],
      onChanged: onAddressSelected,
    );
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
