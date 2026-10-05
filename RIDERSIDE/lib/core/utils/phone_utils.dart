class PhoneUtils {
  static String toInternational(String rawPhone) {
    var phone = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+63')) return phone;
    if (phone.startsWith('63') && phone.length >= 12) return '+$phone';
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '+63$phone';
  }
}
