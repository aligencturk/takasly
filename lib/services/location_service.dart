import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Konum izni kontrolü ve alma
  Future<bool> requestLocationPermission() async {
    print('📍 LocationService: Checking location permission...');

    // Önce permission_handler ile kontrol et
    PermissionStatus permission = await Permission.location.status;
    print('📍 Current permission status: $permission');

    if (permission.isDenied) {
      print('📍 Permission denied, requesting...');
      permission = await Permission.location.request();
      print('📍 Permission request result: $permission');
    }

    if (permission.isPermanentlyDenied) {
      print('❌ Permission permanently denied, opening settings...');
      await openAppSettings();
      return false;
    }

    if (permission.isGranted) {
      print('✅ Location permission granted');
      return true;
    }

    print('❌ Location permission not granted');
    return false;
  }

  /// Konum servisinin aktif olup olmadığını kontrol et
  Future<bool> isLocationServiceEnabled() async {
    print('📍 LocationService: Checking if location service is enabled...');
    final bool isEnabled = await Geolocator.isLocationServiceEnabled();
    print('📍 Location service enabled: $isEnabled');

    if (!isEnabled) {
      print('❌ Location service is disabled');
      return false;
    }

    return true;
  }

  /// Mevcut konumu al
  Future<Position?> getCurrentLocation() async {
    try {
      print('📍 LocationService: Getting current location...');

      // Konum servisi aktif mi kontrol et
      if (!await isLocationServiceEnabled()) {
        print('❌ Location service is not enabled');
        return null;
      }

      // İzin var mı kontrol et
      if (!await requestLocationPermission()) {
        print('❌ Location permission not granted');
        return null;
      }

      // Geolocator ile konum izni tekrar kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Geolocator permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('📍 Geolocator permission request result: $permission');

        if (permission == LocationPermission.denied) {
          print('❌ Geolocator permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Geolocator permission denied forever');
        return null;
      }

      // Konum al
      print('📍 Getting position...');
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy}m');
      print('📍 Timestamp: ${position.timestamp}');

      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Konum bilgilerini string olarak al
  Future<Map<String, String>?> getCurrentLocationAsStrings() async {
    final Position? position = await getCurrentLocation();

    if (position == null) {
      return null;
    }

    return {
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
    };
  }

  /// İki konum arasındaki mesafeyi hesapla (metre cinsinden)
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Mesafeyi kullanıcı dostu formatta göster
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }
}
