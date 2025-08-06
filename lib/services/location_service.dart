import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:takasly/utils/logger.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Konum izinlerini kontrol eder
  Future<bool> checkLocationPermission() async {
    try {
      // Önce geolocator ile kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // İzin iste
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Kullanıcı kalıcı olarak reddetti
        Logger.warning('Konum izni kalıcı olarak reddedildi');
        return false;
      }
      
      // İzin verildi mi kontrol et
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        Logger.info('Konum izni verildi');
        return true;
      }
      
      Logger.warning('Konum izni verilmedi: $permission');
      return false;
    } catch (e) {
      Logger.error('Konum izni kontrol edilirken hata: $e');
      return false;
    }
  }

  /// GPS servislerinin açık olup olmadığını kontrol eder
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      Logger.error('Konum servisi kontrol edilirken hata: $e');
      return false;
    }
  }

  /// Mevcut konumu alır
  Future<Position?> getCurrentLocation() async {
    try {
      // İzin kontrolü
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        Logger.warning('Konum izni verilmedi');
        return null;
      }

      // GPS servisi kontrolü
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        Logger.warning('GPS servisi kapalı');
        return null;
      }

      // Konum alma
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      Logger.info('Konum alındı: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      Logger.error('Konum alınırken hata: $e');
      return null;
    }
  }

  /// Konum izinlerini açmaya yönlendirir
  Future<void> openLocationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      Logger.error('Ayarlar açılırken hata: $e');
    }
  }

  /// GPS ayarlarını açmaya yönlendirir
  Future<void> openGPSSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      Logger.error('GPS ayarları açılırken hata: $e');
    }
  }

  /// Mevcut konumu string formatında alır
  Future<Map<String, String>?> getCurrentLocationAsStrings() async {
    try {
      final position = await getCurrentLocation();
      if (position != null) {
        return {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        };
      }
      return null;
    } catch (e) {
      Logger.error('Konum string formatında alınırken hata: $e');
      return null;
    }
  }

  /// İki konum arasındaki mesafeyi hesaplar (km)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    try {
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
    } catch (e) {
      Logger.error('Mesafe hesaplanırken hata: $e');
      return 0.0;
    }
  }

  /// Konum kalitesini kontrol eder
  bool isLocationAccurate(Position position) {
    // Konum doğruluğu 100 metreden az ise kabul edilebilir
    return position.accuracy <= 100;
  }

  /// Şehir/İlçe adına göre koordinat alır
  Future<Position?> getLocationFromCityName(String locationName) async {
    try {
      Logger.info('Konum aranıyor: $locationName');
      
      List<Location> locations = [];
      
      // Farklı formatları dene
      List<String> searchFormats = [
        locationName, // Orijinal format
        '$locationName, Turkey', // Turkey eklenmişse
        locationName.replaceAll(', Turkey', ''), // Turkey'i kaldır
      ];
      
      for (String searchTerm in searchFormats) {
        try {
          locations = await locationFromAddress(searchTerm);
          if (locations.isNotEmpty) {
            Logger.info('Konum bulundu ($searchTerm): ${locations.first.latitude}, ${locations.first.longitude}');
            break;
          }
        } catch (e) {
          Logger.warning('Arama başarısız ($searchTerm): $e');
          continue;
        }
      }
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 1000, // Şehir/ilçe merkezi için yaklaşık doğruluk
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      
      Logger.warning('Konum bulunamadı: $locationName');
      return null;
    } catch (e) {
      Logger.error('Konum alınırken hata: $e');
      return null;
    }
  }
}
