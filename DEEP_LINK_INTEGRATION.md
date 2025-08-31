# Takasly Deep Link Entegrasyonu

Bu doküman, Takasly Flutter uygulamasında deep link entegrasyonunun nasıl yapıldığını ve nasıl kullanılacağını açıklar.

## 🎯 Genel Bakış

Deep link entegrasyonu sayesinde:
- Kullanıcılar `https://www.takasly.tr/ilan/1234` linkine tıkladığında uygulama açılır
- Doğru ürün detay sayfasına yönlendirilir
- Hem uygulama açıkken hem de kapalıyken çalışır
- Android ve iOS platformlarında desteklenir

## 📱 Desteklenen Link Formatları

### 1. HTTP/HTTPS Links
```
https://www.takasly.tr/ilan/1234
http://www.takasly.tr/ilan/1234
```

### 2. Custom Scheme Links
```
takasly://ilan/1234
```

## 🏗️ Mimari Yapı

### MVVM Mimarisi
- **Service Layer**: `DeepLinkService` - Deep link'leri yakalar ve işler
- **ViewModel Layer**: `DeepLinkViewModel` - State yönetimi ve UI iletişimi
- **View Layer**: `DeepLinkHandler` - Deep link işleme widget'ı

### Dosya Yapısı
```
lib/
├── services/
│   └── deep_link_service.dart
├── viewmodels/
│   └── deep_link_viewmodel.dart
└── widgets/
    └── deep_link_handler.dart
```

## ⚙️ Kurulum Adımları

### 1. Paket Ekleme
```yaml
dependencies:
  uni_links: ^0.5.1
```

### 2. Android Manifest Ayarları
`android/app/src/main/AndroidManifest.xml` dosyasına eklenen intent-filter'lar:

```xml
<!-- Deep Link Intent Filter - HTTP/HTTPS -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="www.takasly.tr" />
    <data android:scheme="http" android:host="www.takasly.tr" />
</intent-filter>

<!-- Deep Link Intent Filter - Custom Scheme -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="takasly" android:host="ilan" />
</intent-filter>
```

### 3. iOS Info.plist Ayarları
`ios/Runner/Info.plist` dosyasına eklenen ayarlar:

```xml
<!-- Custom URL Scheme -->
<dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>deeplink</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>takasly</string>
    </array>
</dict>

<!-- Associated Domains for Universal Links -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:www.takasly.tr</string>
</array>
```

### 4. Web Sunucu Ayarları

#### Apple App Site Association
`/.well-known/apple-app-site-association` dosyası:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.rivorya.takaslyapp",
        "paths": [
          "/ilan/*"
        ]
      }
    ]
  }
}
```

#### Android Asset Links
`/.well-known/assetlinks.json` dosyası:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.rivorya.takaslyapp",
      "sha256_cert_fingerprints": [
        "SHA256_FINGERPRINT_BURAYA_EKLENECEK"
      ]
    }
  }
]
```

## 🔧 Kullanım

### 1. Uygulama Başlatma
`main.dart` dosyasında `DeepLinkHandler` widget'ı otomatik olarak eklenir:

```dart
home: DeepLinkHandler(
  child: Builder(
    builder: (context) {
      // ... existing code
      return SplashVideoPage();
    },
  ),
),
```

### 2. Deep Link Dinleme
Deep link'ler otomatik olarak yakalanır ve işlenir. Kullanıcı:
- Uygulama açıkken link'e tıklarsa → Runtime link yakalanır
- Uygulama kapalıyken link'e tıklarsa → Initial link yakalanır

### 3. Yönlendirme
Deep link geldiğinde otomatik olarak ürün detay sayfasına yönlendirilir:

```dart
Navigator.of(context).pushNamed(
  '/product-detail',
  arguments: {'productId': productId},
);
```

## 🌐 Web Tarafı Entegrasyonu

### Meta Tag'ler
`web/index.html` dosyasına eklenen meta tag'ler:

```html
<!-- iOS Universal Links -->
<meta name="apple-itunes-app" content="app-id=6749484217, app-argument=takasly://ilan">

<!-- Android App Links -->
<meta name="google-play-app" content="app-id=com.rivorya.takaslyapp">

<!-- Open Graph Meta Tags -->
<meta property="og:title" content="Takasly - Ürün Takası Platformu">
<meta property="og:description" content="E-ticaret mantığında ürün takası yapın">
<meta property="og:type" content="website">
<meta property="og:url" content="https://www.takasly.tr">
<meta property="og:image" content="https://www.takasly.tr/logo/takasly-image.png">
```

### Firebase Dynamic Links
`web/firebase_dynamic_links.html` dosyası ile fallback yapısı sağlanır.

## 📋 Test Etme

### 1. Android Test
```bash
# ADB ile test
adb shell am start -W -a android.intent.action.VIEW -d "https://www.takasly.tr/ilan/1234" com.rivorya.takaslyapp

# Custom scheme test
adb shell am start -W -a android.intent.action.VIEW -d "takasly://ilan/1234" com.rivorya.takaslyapp
```

### 2. iOS Test
```bash
# Simulator'da test
xcrun simctl openurl booted "https://www.takasly.tr/ilan/1234"
xcrun simctl openurl booted "takasly://ilan/1234"
```

### 3. Web Test
Tarayıcıda `https://www.takasly.tr/ilan/1234` adresini açın.

## 🚀 Firebase Dynamic Links (Opsiyonel)

### 1. Firebase Console'da Kurulum
- Firebase projesi oluştur
- Dynamic Links'i etkinleştir
- Domain'i yapılandır

### 2. Konfigürasyon
`web/firebase_dynamic_links.html` dosyasında Firebase config'i güncelleyin:

```javascript
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
};
```

## 🔍 Debug ve Logging

Tüm deep link işlemleri `Logger` ile loglanır:

```dart
Logger.info('Deep link yakalandı: $link');
Logger.info('Ürün detay sayfasına yönlendirildi. Product ID: $productId');
```

## ⚠️ Önemli Notlar

### 1. Android App Links
- `android:autoVerify="true"` ile otomatik doğrulama
- SHA256 fingerprint'in doğru olması gerekir
- Web sunucuda `/.well-known/assetlinks.json` erişilebilir olmalı

### 2. iOS Universal Links
- Associated Domains capability gerekli
- Web sunucuda `/.well-known/apple-app-site-association` erişilebilir olmalı
- Team ID doğru olmalı

### 3. Web Sunucu Gereksinimleri
- HTTPS zorunlu
- `.well-known` klasörü erişilebilir olmalı
- CORS ayarları doğru yapılandırılmalı

## 🐛 Sorun Giderme

### 1. Deep Link Çalışmıyor
- Manifest/Info.plist ayarlarını kontrol edin
- Web sunucu dosyalarının erişilebilir olduğundan emin olun
- Logları kontrol edin

### 2. iOS'ta Çalışmıyor
- Associated Domains capability eklenmiş mi?
- Team ID doğru mu?
- Web sunucu dosyası erişilebilir mi?

### 3. Android'de Çalışmıyor
- SHA256 fingerprint doğru mu?
- `android:autoVerify="true"` eklenmiş mi?
- Web sunucu dosyası erişilebilir mi?

## 📚 Ek Kaynaklar

- [Flutter Deep Links](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
- [Firebase Dynamic Links](https://firebase.google.com/docs/dynamic-links)

## 🤝 Destek

Herhangi bir sorun yaşarsanız:
1. Logları kontrol edin
2. Manifest/Info.plist ayarlarını doğrulayın
3. Web sunucu dosyalarının erişilebilir olduğundan emin olun
4. Test cihazında uygulamanın yüklü olduğundan emin olun
