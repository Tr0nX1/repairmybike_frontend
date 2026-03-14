class PostalAddress {
  final String fullName;
  final String phoneNumber;
  final String flatHouseNo;
  final String areaStreet;
  final String landmark;
  final String pincode;
  final String townCity;
  final String state;

  PostalAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.flatHouseNo,
    required this.areaStreet,
    this.landmark = '',
    required this.pincode,
    required this.townCity,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'flat_house_no': flatHouseNo,
        'area_street': areaStreet,
        'landmark': landmark,
        'pincode': pincode,
        'town_city': townCity,
        'state': state,
      };

  factory PostalAddress.fromJson(Map<String, dynamic> json) => PostalAddress(
        fullName: json['full_name'] ?? '',
        phoneNumber: json['phone_number'] ?? '',
        flatHouseNo: json['flat_house_no'] ?? '',
        areaStreet: json['area_street'] ?? '',
        landmark: json['landmark'] ?? '',
        pincode: json['pincode'] ?? '',
        townCity: json['town_city'] ?? '',
        state: json['state'] ?? '',
      );

  String toFullString() {
    return [flatHouseNo, areaStreet, landmark, townCity, state, pincode]
        .where((e) => e.isNotEmpty)
        .join(', ');
  }

  bool get isEmpty =>
      fullName.isEmpty &&
      phoneNumber.isEmpty &&
      flatHouseNo.isEmpty &&
      areaStreet.isEmpty &&
      pincode.isEmpty;
}
