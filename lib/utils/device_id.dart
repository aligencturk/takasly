import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import 'logger.dart';

class DeviceIdHelper {
  DeviceIdHelper._();

  static Future<String> getOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(AppConstants.deviceIdKey);
      if (existing != null && existing.isNotEmpty) {
        Logger.debug('DeviceID mevcut: $existing');
        return existing;
      }
      final String newId = const Uuid().v4();
      await prefs.setString(AppConstants.deviceIdKey, newId);
      Logger.info('Yeni DeviceID oluşturuldu: $newId');
      return newId;
    } catch (e) {
      Logger.error('DeviceID oluşturma hatası: $e');
      // Hata durumunda rastgele id üret
      return const Uuid().v4();
    }
  }
}
