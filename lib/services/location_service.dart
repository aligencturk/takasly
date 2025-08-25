import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:takasly/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
            Logger.info(
              'Konum bulundu ($searchTerm): ${locations.first.latitude}, ${locations.first.longitude}',
            );
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

  /// Koordinatlardan il ve ilçe bilgilerini alır (reverse geocoding)
  Future<Map<String, String>?> getCityDistrictFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      Logger.info('Koordinatlardan il/ilçe aranıyor: $latitude, $longitude');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        Logger.info('Placemark detayları:');
        Logger.info('  administrativeArea: ${placemark.administrativeArea}');
        Logger.info(
          '  subAdministrativeArea: ${placemark.subAdministrativeArea}',
        );
        Logger.info('  locality: ${placemark.locality}');
        Logger.info('  subLocality: ${placemark.subLocality}');
        Logger.info('  thoroughfare: ${placemark.thoroughfare}');
        Logger.info('  name: ${placemark.name}');

        // İl bilgisi için administrativeArea kullan
        String? city = placemark.administrativeArea;

        // İlçe bilgisi için daha gelişmiş mantık:
        String? district;

        // 1. Öncelik: subAdministrativeArea (genellikle ilçe)
        if (placemark.subAdministrativeArea != null &&
            placemark.subAdministrativeArea!.isNotEmpty &&
            placemark.subAdministrativeArea != city) {
          district = placemark.subAdministrativeArea;
          Logger.info('İlçe subAdministrativeArea\'dan alındı: $district');
        }
        // 2. Öncelik: subLocality (mahalle/ilçe)
        else if (placemark.subLocality != null &&
            placemark.subLocality!.isNotEmpty &&
            placemark.subLocality != city) {
          district = placemark.subLocality;
          Logger.info('İlçe subLocality\'den alındı: $district');
        }
        // 3. Öncelik: locality (mahalle/kasaba - ilçe olabilir)
        else if (placemark.locality != null &&
            placemark.locality!.isNotEmpty &&
            placemark.locality != city) {
          // locality genellikle mahalle ama bazen ilçe olabilir
          // Eğer çok uzunsa muhtemelen ilçe
          if (placemark.locality!.length > 3) {
            district = placemark.locality;
            Logger.info('İlçe locality\'den alındı: $district');
          }
        }

        // Eğer ilçe bilgisi il ile aynıysa (genellikle il merkezi), null yap
        if (district != null && district.isNotEmpty && district == city) {
          Logger.info('İlçe bilgisi il ile aynı, null yapılıyor');
          district = null;
        }

        // Eğer ilçe bilgisi çok kısa ise (2 karakterden az), muhtemelen kısaltma, null yap
        if (district != null && district.length < 2) {
          Logger.info('İlçe bilgisi çok kısa, null yapılıyor: $district');
          district = null;
        }

        // Eğer ilçe bilgisi çok uzunsa (20 karakterden fazla), muhtemelen adres, null yap
        if (district != null && district.length > 20) {
          Logger.info('İlçe bilgisi çok uzun, null yapılıyor: $district');
          district = null;
        }

        // Eğer ilçe bilgisi sayı içeriyorsa, muhtemelen sokak numarası, null yap
        if (district != null && RegExp(r'\d').hasMatch(district)) {
          Logger.info('İlçe bilgisi sayı içeriyor, null yapılıyor: $district');
          district = null;
        }

        // Eğer Google API'den ilçe bilgisi alınamadıysa, OpenStreetMap'i dene
        if (district == null || district.isEmpty) {
          Logger.info(
            'Google API\'den ilçe bilgisi alınamadı, OpenStreetMap deneniyor...',
          );
          final osmDistrict = await _getDistrictFromOpenStreetMap(
            latitude,
            longitude,
            city,
          );
          if (osmDistrict != null && osmDistrict.isNotEmpty) {
            district = osmDistrict;
            Logger.info('İlçe OpenStreetMap\'den alındı: $district');
          }
        }

        Logger.info('Final il/ilçe: $city / $district');

        return {
          'city': city ?? '',
          'district': district ?? '',
          'country': placemark.country ?? '',
          'fullAddress': placemark.toString(),
        };
      }

      Logger.warning('Koordinatlardan il/ilçe bulunamadı');
      return null;
    } catch (e) {
      Logger.error('Koordinatlardan il/ilçe alınırken hata: $e');
      return null;
    }
  }

  /// OpenStreetMap Nominatim API'den ilçe bilgisini almaya çalışır
  Future<String?> _getDistrictFromOpenStreetMap(
    double latitude,
    double longitude,
    String? city,
  ) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'format=json&'
        'lat=$latitude&'
        'lon=$longitude&'
        'zoom=10&'
        'accept-language=tr',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'TakaslyApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        if (address != null) {
          // OpenStreetMap'de ilçe bilgisi farklı alanlarda olabilir
          String? district =
              address['county'] ?? // İlçe
              address['district'] ?? // İlçe (alternatif)
              address['suburb'] ?? // Mahalle (bazen ilçe)
              address['city_district']; // Şehir ilçesi

          Logger.info('OpenStreetMap address detayları: $address');
          Logger.info('OpenStreetMap\'den bulunan ilçe: $district');

          // Eğer ilçe bilgisi il ile aynıysa null yap
          if (district != null && district.isNotEmpty && district == city) {
            Logger.info(
              'OpenStreetMap ilçe bilgisi il ile aynı, null yapılıyor',
            );
            return null;
          }

          // Eğer ilçe bilgisi çok kısa veya uzunsa null yap
          if (district != null &&
              (district.length < 2 || district.length > 20)) {
            Logger.info(
              'OpenStreetMap ilçe bilgisi uygun değil, null yapılıyor: $district',
            );
            return null;
          }

          return district;
        }
      }

      Logger.warning('OpenStreetMap\'den ilçe bilgisi alınamadı');
      return null;
    } catch (e) {
      Logger.error('OpenStreetMap\'den ilçe alınırken hata: $e');
      return null;
    }
  }

  /// Koordinatlardan sadece il bilgisini alır
  Future<String?> getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final locationInfo = await getCityDistrictFromCoordinates(
        latitude,
        longitude,
      );
      return locationInfo?['city'];
    } catch (e) {
      Logger.error('Koordinatlardan il alınırken hata: $e');
      return null;
    }
  }

  /// Koordinatlardan sadece ilçe bilgisini alır
  Future<String?> getDistrictFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final locationInfo = await getCityDistrictFromCoordinates(
        latitude,
        longitude,
      );
      return locationInfo?['district'];
    } catch (e) {
      Logger.error('Koordinatlardan ilçe alınırken hata: $e');
      return null;
    }
  }
}
