import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneFormatter {
  // Türkiye telefon numarası formatı: 0(555) 555 55 55
  // Her alan için yeni bir formatter örneği üretmek, paylaşılan state kaynaklı hataları önler
  static MaskTextInputFormatter buildPhoneMask() {
    return MaskTextInputFormatter(
      mask: '(###) ### ## ##',
      filter: {"#": RegExp(r'[0-9]')},
    );
  }

  // Telefon numarasını temizle (sadece rakamları al)
  static String cleanPhoneNumber(String phone) {
    if (phone.isEmpty) return phone;

    try {
      return phone.replaceAll(RegExp(r'[^\d]'), '');
    } catch (e) {
      return phone;
    }
  }

  // Telefon numarasını ekranda göstermek için formatla
  static String formatPhoneNumber(String phone) {
    if (phone.isEmpty) return phone;

    try {
      final clean = cleanPhoneNumber(phone);
      if (clean.length == 11 && clean.startsWith('0')) {
        return '0(${clean.substring(1, 4)}) ${clean.substring(4, 7)} ${clean.substring(7, 9)} ${clean.substring(9, 11)}';
      }
      return phone;
    } catch (e) {
      // Hata durumunda orijinal telefon numarasını döndür
      return phone;
    }
  }

  // API'nin beklediği formata dönüştür: 0(5XX) XXX XX XX
  static String formatToApiPattern(String phone) {
    if (phone.isEmpty) return phone;

    try {
      final clean = cleanPhoneNumber(phone);
      String withLeadingZero = clean;
      if (clean.length == 10 && clean.startsWith('5')) {
        withLeadingZero = '0$clean';
      }
      if (withLeadingZero.length == 11 && withLeadingZero.startsWith('05')) {
        return '0(${withLeadingZero.substring(1, 4)}) ${withLeadingZero.substring(4, 7)} ${withLeadingZero.substring(7, 9)} ${withLeadingZero.substring(9, 11)}';
      }
      return phone;
    } catch (e) {
      return phone;
    }
  }

  // Telefon numarasının geçerli olup olmadığını kontrol et
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;

    try {
      final clean = cleanPhoneNumber(phone);
      // Geçerli: 05XXXXXXXXX (11 hane) veya 5XXXXXXXXX (10 hane)
      return (clean.length == 11 && clean.startsWith('05')) ||
          (clean.length == 10 && clean.startsWith('5'));
    } catch (e) {
      return false;
    }
  }

  // Telefon numarasını API için hazırla (sadece rakamlar)
  static String prepareForApi(String phone) {
    if (phone.isEmpty) return phone;

    try {
      return formatToApiPattern(phone);
    } catch (e) {
      return phone;
    }
  }
}
