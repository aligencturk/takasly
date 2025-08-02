import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneFormatter {
  // Türkiye telefon numarası formatı: 0(555) 555 55 55
  static final MaskTextInputFormatter phoneMask = MaskTextInputFormatter(
    mask: '0(###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Telefon numarasını temizle (sadece rakamları al)
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Telefon numarasını formatla
  static String formatPhoneNumber(String phone) {
    final clean = cleanPhoneNumber(phone);
    if (clean.length == 11 && clean.startsWith('0')) {
      // 0(555) 555 55 55 formatına çevir
      return '0(${clean.substring(1, 4)}) ${clean.substring(4, 7)} ${clean.substring(7, 9)} ${clean.substring(9, 11)}';
    }
    return phone;
  }

  // Telefon numarasının geçerli olup olmadığını kontrol et
  static bool isValidPhoneNumber(String phone) {
    final clean = cleanPhoneNumber(phone);
    // Türkiye telefon numarası: 05XXXXXXXXX (11 haneli)
    return clean.length == 11 && clean.startsWith('05');
  }

  // Telefon numarasını API için hazırla (sadece rakamlar)
  static String prepareForApi(String phone) {
    return cleanPhoneNumber(phone);
  }
} 