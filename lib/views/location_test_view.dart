import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationTestView extends StatefulWidget {
  const LocationTestView({super.key});

  @override
  State<LocationTestView> createState() => _LocationTestViewState();
}

class _LocationTestViewState extends State<LocationTestView> {
  String _status = 'Test başlatılmadı';
  double? _latitude;
  double? _longitude;

  Future<void> _testLocation() async {
    setState(() {
      _status = 'Test başlatılıyor...';
    });

    try {
      final locationService = LocationService();
      
      // Konum servisi kontrolü
      final isEnabled = await locationService.isLocationServiceEnabled();
      setState(() {
        _status = 'Konum servisi: ${isEnabled ? "Açık" : "Kapalı"}';
      });

      if (!isEnabled) {
        setState(() {
          _status = 'Konum servisi kapalı! Emülatörde açın.';
        });
        return;
      }

      // İzin kontrolü
      final hasPermission = await locationService.requestLocationPermission();
      setState(() {
        _status = 'İzin durumu: ${hasPermission ? "Verildi" : "Reddedildi"}';
      });

      if (!hasPermission) {
        setState(() {
          _status = 'Konum izni reddedildi!';
        });
        return;
      }

      // Konum alma
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _status = 'Konum alındı!';
        });
      } else {
        setState(() {
          _status = 'Konum alınamadı!';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Hata: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testLocation,
              child: const Text('Konum Testini Başlat'),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Durum: $_status'),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 10),
                      Text('Enlem: $_latitude'),
                      Text('Boylam: $_longitude'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emülatör Ayarları:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('1. Settings > Location > Location services = ON'),
                    Text('2. Settings > Apps > Takasly > Permissions > Location = Allow'),
                    Text('3. Emülatör > ... > Location > Set location'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 