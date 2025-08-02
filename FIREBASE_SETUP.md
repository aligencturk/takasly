# Firebase Realtime Database Kurulum Rehberi

Bu rehber, Takasly uygulamasında Firebase Realtime Database ile mesajlaşma sistemini kurmak için gereken adımları açıklar.

## 1. Firebase Console'da Proje Oluşturma

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. "Proje Ekle" butonuna tıklayın
3. Proje adını "takasly" olarak belirleyin
4. Google Analytics'i etkinleştirin (isteğe bağlı)
5. "Proje Oluştur" butonuna tıklayın

## 2. Realtime Database Oluşturma

1. Sol menüden "Realtime Database"i seçin
2. "Veritabanı oluştur" butonuna tıklayın
3. Güvenlik kurallarını "Test modunda başlat" olarak seçin
4. Veritabanı konumunu seçin (örn: europe-west1)
5. "Tamam" butonuna tıklayın

## 3. Güvenlik Kurallarını Ayarlama

1. Realtime Database sayfasında "Kurallar" sekmesine tıklayın
2. `firebase_rules.json` dosyasındaki kuralları kopyalayın
3. Mevcut kuralları silin ve yeni kuralları yapıştırın
4. "Yayınla" butonuna tıklayın

## 4. Flutter Uygulamasını Firebase'e Bağlama

### Android için:
1. Sol menüden "Proje ayarları"nı seçin
2. "Genel" sekmesinde "Android uygulaması ekle" butonuna tıklayın
3. Android paket adını girin: `com.rivorya.takasly`
4. `google-services.json` dosyasını indirin
5. Bu dosyayı `android/app/` klasörüne yerleştirin

### iOS için:
1. "iOS uygulaması ekle" butonuna tıklayın
2. Bundle ID'yi girin: `com.rivorya.takasly`
3. `GoogleService-Info.plist` dosyasını indirin
4. Bu dosyayı iOS projesine ekleyin

## 5. Firebase Konfigürasyonu

1. `lib/firebase_options.dart` dosyasını açın
2. Firebase Console'dan aldığınız değerleri ilgili yerlere yerleştirin:
   - `apiKey`
   - `appId`
   - `messagingSenderId`
   - `projectId`
   - `databaseURL`
   - `storageBucket`

## 6. Veritabanı Yapısı

Firebase Realtime Database'de şu yapı kullanılır:

```
takasly-app/
├── chats/
│   └── {chatId}/
│       ├── id: "chat123"
│       ├── tradeId: "trade456"
│       ├── participantIds: ["user1", "user2"]
│       ├── createdAt: 1234567890
│       ├── updatedAt: 1234567890
│       └── isActive: true
├── messages/
│   └── {chatId}/
│       └── {messageId}/
│           ├── id: "msg789"
│           ├── chatId: "chat123"
│           ├── senderId: "user1"
│           ├── content: "Merhaba!"
│           ├── type: "text"
│           ├── timestamp: 1234567890
│           ├── isRead: false
│           └── isDeleted: false
└── users/
    └── {userId}/
        ├── id: "user1"
        ├── name: "Ahmet"
        ├── email: "ahmet@example.com"
        └── ...
```

## 7. Test Etme

1. Uygulamayı çalıştırın
2. Giriş yapın
3. Ana sayfada chat ikonuna tıklayın
4. Mesajlar sayfasının açıldığını kontrol edin

## 8. Önemli Notlar

- Firebase Realtime Database ücretsiz planında günlük 1GB veri transferi ve 100 eşzamanlı bağlantı sınırı vardır
- Güvenlik kuralları çok önemlidir, mutlaka test edin
- Offline desteği otomatik olarak çalışır
- Mesajlar gerçek zamanlı olarak güncellenir

## 9. Sorun Giderme

### Hata: "Firebase not initialized"
- `main.dart` dosyasında Firebase.initializeApp() çağrısını kontrol edin
- `firebase_options.dart` dosyasındaki konfigürasyonu kontrol edin

### Hata: "Permission denied"
- Firebase Console'da güvenlik kurallarını kontrol edin
- Kullanıcının chat'e katılımcı olup olmadığını kontrol edin

### Mesajlar görünmüyor
- Veritabanı bağlantısını kontrol edin
- Chat ID'nin doğru olduğunu kontrol edin
- Güvenlik kurallarını kontrol edin

## 10. Gelecek Geliştirmeler

- Push notifications ekleme
- Dosya yükleme desteği
- Mesaj arama özelliği
- Okundu durumu güncelleme
- Mesaj silme özelliği
- Emoji desteği 