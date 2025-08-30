# 📱 Takasly App Sürüm Yönetimi

Bu dokümanda Takasly uygulamasının sürüm yönetimi hakkında bilgi bulabilirsiniz.

## 🎯 Sürüm Yapısı

### Semantic Versioning (SemVer)
- **Major**: Büyük değişiklikler, uyumsuz API değişiklikleri
- **Minor**: Yeni özellikler, geriye uyumlu
- **Patch**: Hata düzeltmeleri, geriye uyumlu

### Build Number
- Her yeni build'de artırılır
- Store'lara yüklerken önceki versiyondan büyük olmalı

## 🚀 Sürüm Güncelleme

### Otomatik Güncelleme (Önerilen)

```bash
# Script'i çalıştırılabilir yap
chmod +x scripts/version_bump.sh

# Sürüm güncelleme
./scripts/version_bump.sh major      # 1.0.0 -> 2.0.0
./scripts/version_bump.sh minor      # 1.0.0 -> 1.1.0
./scripts/version_bump.sh patch      # 1.0.0 -> 1.0.1
./scripts/version_bump.sh build      # Build numarasını artır
```

### Manuel Güncelleme

#### Android
```kotlin
// android/app/build.gradle.kts
defaultConfig {
    versionCode = 32        // Build number
    versionName = "1.0.1"  // Semantic version
}
```

#### iOS
```objc
// ios/Runner.xcodeproj/project.pbxproj
CURRENT_PROJECT_VERSION = 32;        // Build number
MARKETING_VERSION = 1.0.1;          // Semantic version
```

#### macOS
```objc
// macos/Runner.xcodeproj/project.pbxproj
CURRENT_PROJECT_VERSION = 32;        // Build number
MARKETING_VERSION = 1.0.1;          // Semantic version
```

## 📋 Güncelleme Adımları

1. **Sürüm güncelle**
   ```bash
   ./scripts/version_bump.sh patch
   ```

2. **Değişiklikleri commit et**
   ```bash
   git add .
   git commit -m "Bump version to 1.0.1+32"
   ```

3. **Tag oluştur**
   ```bash
   git tag v1.0.1+32
   git push origin v1.0.1+32
   ```

4. **Build al**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

5. **iOS Archive (Xcode)**
   - Xcode'da Runner projesini aç
   - Product > Archive
   - Organizer'dan App Store'a yükle

## 🔧 Script Özellikleri

- **Otomatik sürüm artırma**
- **Tüm platformlarda senkronizasyon**
- **VERSION_INFO.md güncelleme**
- **Renkli terminal çıktısı**
- **Hata kontrolü**

## ⚠️ Önemli Notlar

- **Build number** her yeni build'de artırılmalı
- **Semantic version** sadece önemli değişikliklerde artırılır
- **Flutter version** artık kullanılmıyor
- **Platform bazlı** sürüm yönetimi
- **Git tag** her sürüm için zorunlu

## 📱 Mevcut Sürüm

- **Version**: 1.0.0
- **Build**: 31
- **Platforms**: Android, iOS, macOS
- **Son Güncelleme**: $(date)

## 🆘 Sorun Giderme

### Script çalışmıyor
```bash
# Script'i çalıştırılabilir yap
chmod +x scripts/version_bump.sh

# Dosya izinlerini kontrol et
ls -la scripts/version_bump.sh
```

### Sürüm uyumsuzluğu
```bash
# Tüm platformlarda sürüm kontrolü
grep -r "versionCode\|CURRENT_PROJECT_VERSION\|MARKETING_VERSION" android/ ios/ macos/
```

### Git tag hatası
```bash
# Mevcut tag'leri listele
git tag -l

# Tag'i sil ve yeniden oluştur
git tag -d v1.0.1+32
git tag v1.0.1+32
```

## 📞 Destek

Sürüm yönetimi ile ilgili sorunlar için:
- **Git Issues**: Proje repository'sinde issue açın
- **Team Chat**: Slack/Discord kanalında sorun
- **Documentation**: Bu dosyayı güncelleyin
