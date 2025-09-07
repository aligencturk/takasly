# Uygulama Versiyon Yönetimi

Bu dokümantasyon, Takasly uygulamasında dinamik versiyon yönetiminin nasıl çalıştığını açıklar.

## Genel Bakış

Artık `constants.dart` dosyasında sabit bir `appVersion` değeri tutulmamaktadır. Bunun yerine, uygulama versiyonu dinamik olarak alınmaktadır:

- **iOS**: `Info.plist` dosyasındaki `CFBundleShortVersionString` değerinden
- **Android**: `build.gradle.kts` dosyasındaki `versionName` değerinden

## Kullanım

### 1. Temel Kullanım

```dart
import '../utils/app_version_utils.dart';

// Versiyon bilgisini al
final version = await AppVersionUtils.getAppVersion();
print('App version: $version'); // Örnek: "1.0.5"

// Build number'ı al
final buildNumber = await AppVersionUtils.getBuildNumber();
print('Build number: $buildNumber'); // Örnek: "36"

// Formatlanmış versiyon
final formattedVersion = await AppVersionUtils.getFormattedVersion();
print('Formatted: $formattedVersion'); // Örnek: "1.0.5 (36)"
```

### 2. Widget İçinde Kullanım

```dart
FutureBuilder<String>(
  future: AppVersionUtils.getFormattedVersion(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('Version: ${snapshot.data}');
    }
    return const Text('Loading...');
  },
)
```

### 3. Versiyon Karşılaştırması

```dart
final comparison = await AppVersionUtils.compareVersion('1.0.4');
if (comparison > 0) {
  print('Current version is newer');
} else if (comparison < 0) {
  print('Current version is older');
} else {
  print('Versions are equal');
}
```

## Dosya Yapısı

```
lib/
├── core/
│   └── constants.dart          # AppConstants.appVersion kaldırıldı
├── utils/
│   ├── app_version_utils.dart  # Dinamik versiyon yönetimi
│   └── app_version_example.dart # Kullanım örnekleri
└── services/
    └── user_service.dart       # AppVersionUtils kullanıyor
```

## Platform Spesifik Ayarlar

### iOS (Info.plist)
```xml
<key>CFBundleShortVersionString</key>
<string>$(MARKETING_VERSION)</string>
```
- Xcode'da `MARKETING_VERSION` değeri güncellenmelidir
- Bu değer otomatik olarak `AppVersionUtils.getAppVersion()` tarafından alınır

### Android (build.gradle.kts)
```kotlin
defaultConfig {
    versionName = "1.0.5"  // Bu değer güncellenmelidir
    versionCode = 36       // Build number
}
```
- `versionName` değeri `AppVersionUtils.getAppVersion()` tarafından alınır
- `versionCode` değeri `AppVersionUtils.getBuildNumber()` tarafından alınır

## Avantajlar

1. **Tek Kaynak**: Versiyon bilgisi sadece platform dosyalarında tutulur
2. **Otomatik Senkronizasyon**: Kod değişikliği gerektirmez
3. **Hata Toleransı**: Hata durumunda fallback değer döndürür
4. **Cache Desteği**: Performans için cache mekanizması
5. **Versiyon Karşılaştırması**: Built-in versiyon karşılaştırma fonksiyonları

## Migration Notları

- `AppConstants.appVersion` kullanımları `AppVersionUtils.getAppVersion()` ile değiştirildi
- Tüm versiyon kullanımları artık `async` fonksiyonlardır
- Cache mekanizması sayesinde performans etkilenmez

## Örnek Kullanım Senaryoları

1. **Settings Sayfası**: Kullanıcıya versiyon bilgisi gösterme
2. **API İstekleri**: User-Agent veya header'larda versiyon gönderme
3. **Hata Raporlama**: Crash raporlarında versiyon bilgisi
4. **Update Kontrolü**: Yeni versiyon kontrolü
5. **Analytics**: Versiyon bazlı analitik veriler

## Test

```dart
// Cache'i temizle (test amaçlı)
AppVersionUtils.clearCache();

// Versiyon bilgisini tekrar al
final version = await AppVersionUtils.getAppVersion();
```

## Notlar

- İlk çağrıda `package_info_plus` paketi kullanılır
- Sonraki çağrılarda cache'den döndürülür
- Hata durumunda "1.0.0" fallback değeri döndürülür
- Logger ile tüm işlemler loglanır
