# AdMob Production Reklam Yükleme Kontrol Listesi

## ✅ Tamamlanan Düzenlemeler

### 1. **Test Reklamları Tamamen Kaldırıldı**
- ✅ Test ad unit ID'leri kaldırıldı (`ca-app-pub-3940256099942544/*`)
- ✅ Test cihazı konfigürasyonları kaldırıldı
- ✅ Debug log mesajları temizlendi
- ✅ Sadece production ad unit ID'leri kullanılıyor

### 2. **Production Ad Unit ID'leri**
```dart
// Android Production IDs
static const String _androidNativeAdUnitIdProd = 'ca-app-pub-3600325889588673/5822213790';
static const String _androidBannerAdUnitIdProd = 'ca-app-pub-3600325889588673/7805712447';

// iOS Production IDs  
static const String _iosNativeAdUnitIdProd = 'ca-app-pub-3600325889588673/1202018911';
static const String _iosBannerAdUnitIdProd = 'ca-app-pub-3600325889588673/3365147820';
```

### 3. **Uygulama Yapılandırması**
- ✅ Android Package Name: `com.rivorya.takaslyapp`
- ✅ iOS Bundle ID: `com.rivorya.takaslyapp`
- ✅ AdMob App ID: `ca-app-pub-3600325889588673~2182319863` (Android)
- ✅ AdMob App ID: `ca-app-pub-3600325889588673~5340558560` (iOS)

### 4. **Güvenlik Yapılandırması**
- ✅ Network Security Config eklendi
- ✅ `usesCleartextTraffic="false"` ayarlandı
- ✅ HTTPS zorunlu hale getirildi

## 🔍 Kontrol Edilmesi Gerekenler

### 1. **AdMob Konsol Kontrolleri**
- [ ] AdMob hesabında reklam birimleri **AKTIF** mi?
- [ ] Ödeme bilgileri tamamlanmış mı?
- [ ] Ad serving **ENABLED** durumda mı?
- [ ] Uygulamalar AdMob konsolunda doğru package name/bundle ID ile kayıtlı mı?

### 2. **Reklam Birimi Durumu**
- [ ] Yeni oluşturulan ad unit'ler henüz aktif olmayabilir (24 saat bekleyin)
- [ ] Ad inventory (reklam envanteri) dolmuş mu?
- [ ] Targeting ayarları çok kısıtlayıcı değil mi?

### 3. **Uygulama Store Durumu**
- [ ] Uygulama Google Play Store'da yayınlandı mı?
- [ ] iOS App Store'da yayınlandı mı?
- [ ] Store'daki package name/bundle ID AdMob ile uyumlu mu?

### 4. **Coğrafi ve İçerik Kısıtlamaları**
- [ ] Test ettiğiniz ülkede AdMob reklamları var mı?
- [ ] Uygulama içeriği AdMob politikalarına uygun mu?
- [ ] Yaş kısıtlamaları doğru ayarlanmış mı?

## 🛠️ Sorun Giderme Adımları

### Adım 1: AdMob Konsol Kontrolü
1. [AdMob Console](https://apps.admob.com/) → Apps → Takasly
2. Ad units sekmesini kontrol edin
3. Her ad unit'in status'ünün "Serving" olduğunu doğrulayın

### Adım 2: Test Reklamlarını Geçici Olarak Etkinleştirin
Eğer production reklamlar yüklenmiyorsa, geçici olarak test reklamlarını aktif edin:

```dart
// GEÇİCİ TEST - PRODUCTION'A ÇIKARMADAN ÖNCE KALDIR!
String get nativeAdUnitId {
  // Geçici test için
  return 'ca-app-pub-3940256099942544/2247696110'; 
}

String get bannerAdUnitId {
  // Geçici test için  
  return 'ca-app-pub-3940256099942544/6300978111';
}
```

### Adım 3: Logları İzleyin
```bash
# Android logları
adb logcat | grep -i "ads\|admob"

# iOS Simulator logları  
xcrun simctl spawn booted log stream --predicate 'subsystem contains "ads"'
```

### Adım 4: Network Trafiğini Kontrol Edin
- Charles Proxy veya benzer araçlarla
- AdMob sunucularına yapılan istekleri izleyin
- HTTP status kodlarını kontrol edin

## 📱 Gerçek Cihaz Test Önerileri

### Android
```bash
# Release APK oluştur
flutter build apk --release

# Cihaza yükle ve test et
flutter install --use-application-binary=build/app/outputs/flutter-apk/app-release.apk
```

### iOS  
```bash
# Release IPA oluştur
flutter build ios --release

# Xcode ile gerçek cihaza deploy et
```

## ⚠️ Önemli Notlar

1. **24 Saat Kuralı**: Yeni ad unit'ler 24 saate kadar aktif olmayabilir
2. **Store Requirement**: Bazı ad network'ler uygulamanın store'da olmasını gerektirir
3. **Fill Rate**: %100 fill rate beklemeyin, özellikle bazı coğrafyalarda
4. **AdMob Policies**: İçerik politikalarına uygunluğu kontrol edin

## 🔧 Kod İyileştirmeleri

### Request Configuration Optimizasyonu
```dart
await MobileAds.instance.updateRequestConfiguration(
  RequestConfiguration(
    tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
    tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
    maxAdContentRating: MaxAdContentRating.pg,
    // Test device ID'leri production'da ASLA eklemeyin
  ),
);
```

### Error Handling İyileştirmesi
- Retry logic optimize edildi (3 deneme, 5 saniye aralık)
- Timeout süresi 10 saniye olarak ayarlandı
- Memory leak'leri önlemek için dispose logic güçlendirildi

## 📊 Başarı Metrikleri

Aşağıdaki logları görmeli ve reklamların başarıyla yüklendiğini doğrulamalısınız:

```
✅ AdMobService - AdMob başarıyla başlatıldı
📡 AdMobService - Android NativeAdUnitId: ca-app-pub-3600325889588673/5822213790
✅ AdMobService - Native reklam basariyla yuklendi
👁️ AdMobService - Native reklam gosterildi
```

Eğer bu logları göremiyorsanız, yukarıdaki kontrol listesini takip edin.
