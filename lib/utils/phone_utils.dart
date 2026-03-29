
/// Standardizes phone numbers to E.164 format with +91 prefix for India.
String normalizePhoneNumber(String phone) {
  final clean = phone.trim().replaceAll(RegExp(r'\D'), '');
  if (clean.isEmpty) return phone;
  
  // Format based on length
  if (clean.length == 10) return '+91$clean';
  if (clean.length == 11 && clean.startsWith('0')) return '+91${clean.substring(1)}';
  if (clean.length == 12 && clean.startsWith('91')) return '+$clean';
  
  // Already has international prefix? (Starts with non-zero digit and long enough)
  if (phone.trim().startsWith('+')) {
    return phone.trim().replaceAll(RegExp(r'\s+'), '');
  }
  
  return '+$clean';
}
