# 🔔 Firebase Cloud Messaging (FCM) Kurulum ve Test Rehberi

## 📋 Gereksinimler

- Firebase Console erişimi
- Flutter projesi
- Android/iOS cihaz veya emülatör

## 🚀 Kurulum Adımları

### 1. Firebase Console Ayarları

1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. `takasla-b2aa5` projesini seçin
3. **Project Settings** > **Cloud Messaging** sekmesine gidin
4. **Server key**'i kopyalayın (test için gerekli)

### 2. Android Manifest Ayarları

`android/app/src/main/AndroidManifest.xml` dosyasında:

```xml
<!-- FCM için gerekli izinler -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />

<!-- FCM Service -->
<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- FCM Meta Data -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
    
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />
    
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/colorAccent" />
```

### 3. iOS Info.plist Ayarları

`ios/Runner/Info.plist` dosyasında:

```xml
<!-- FCM Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>background-fetch</string>
    <string>background-processing</string>
</array>

<!-- FCM için FirebaseAppDelegateProxyEnabled -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>

<!-- FCM için Notification Service Extension -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 4. Flutter Kod Ayarları

#### main.dart
```dart
// FCM Background Message Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Logger.debug('FCM Background Message: ${message.notification?.title}', tag: 'FCM_BG');
}

void main() async {
  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // FCM Background Handler'ı ayarla
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // FCM'i başlat
  final messaging = FirebaseMessaging.instance;
  
  // Notification permissions'ları iste
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // FCM token'ı al
    String? token = await messaging.getToken();
    if (token != null) {
      Logger.info('FCM Token: ${token.substring(0, 20)}...');
    }
  }
}
```

#### NotificationViewModel
```dart
class NotificationViewModel extends ChangeNotifier {
  Future<void> initializeFCM() async {
    try {
      // İzin iste
      final permissionGranted = await _notificationService.requestNotificationPermissions();
      
      if (permissionGranted) {
        // FCM Token'ını al
        await _refreshFCMToken();
        
        // Message listener'ları başlat
        _setupMessageListeners();
        
        // Kullanıcı ID'sine abone ol
        await _subscribeToUserTopic();
      }
    } catch (e) {
      Logger.error('FCM başlatma hatası: $e');
    }
  }
}
```

## 🧪 Test Etme

### 1. Uygulama İçi Test

1. Uygulamayı çalıştırın
2. **Bildirimler** sayfasına gidin
3. Sağ üstteki **🔔** (notifications_active) butonuna tıklayın
4. Console'da FCM token'ı kontrol edin

### 2. Firebase Console Test

1. Firebase Console > **Cloud Messaging** > **Send your first message**
2. **Notification** sekmesinde:
   - Title: "Test Bildirimi"
   - Body: "Bu bir test bildirimidir"
3. **Target** sekmesinde:
   - **Single device** seçin
   - FCM token'ı girin
4. **Send** butonuna tıklayın

### 3. Script ile Test

`test_fcm.dart` dosyasını kullanarak:

```bash
# FCM token ve server key'i güncelleyin
dart test_fcm.dart
```

## 🔍 Debug ve Sorun Giderme

### 1. FCM Token Kontrolü

```dart
// Console'da FCM token'ı kontrol edin
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

### 2. İzin Durumu Kontrolü

```dart
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Authorization Status: ${settings.authorizationStatus}');
```

### 3. Yaygın Sorunlar

#### Android
- **Bildirim gelmiyor**: Notification channel oluşturulmamış
- **Ses gelmiyor**: `default_sound: true` ayarı eksik
- **Titreşim gelmiyor**: `VIBRATE` izni eksik

#### iOS
- **Bildirim gelmiyor**: `UIBackgroundModes` eksik
- **Ses gelmiyor**: `sound: "default"` ayarı eksik
- **Badge gelmiyor**: `badge: 1` ayarı eksik

### 4. Log Kontrolü

```dart
// FCM mesajlarını dinle
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Foreground Message: ${message.notification?.title}');
});

FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('Background Message: ${message.notification?.title}');
});
```

## 📱 Test Senaryoları

### 1. Foreground Test
- Uygulama açıkken bildirim gönder
- `onMessage` listener'ı çalışmalı

### 2. Background Test
- Uygulama arka plandayken bildirim gönder
- `onMessageOpenedApp` listener'ı çalışmalı

### 3. Terminated Test
- Uygulama kapalıyken bildirim gönder
- Bildirime tıklayınca uygulama açılmalı

### 4. Topic Test
- Belirli bir topic'e abone ol
- Topic'e mesaj gönder
- Abone olan tüm cihazlara gelmeli

## 🚨 Güvenlik Notları

- Server key'i güvenli tutun
- Production'da test script'ini kullanmayın
- FCM token'ları güvenli şekilde saklayın
- Rate limiting uygulayın

## 📞 Destek

Sorun yaşarsanız:
1. Console log'larını kontrol edin
2. Firebase Console'da hata mesajlarını kontrol edin
3. FCM token'ın geçerli olduğundan emin olun
4. İzinlerin verildiğinden emin olun

---

**Not**: Bu rehber test amaçlıdır. Production ortamında ek güvenlik önlemleri alınmalıdır.
