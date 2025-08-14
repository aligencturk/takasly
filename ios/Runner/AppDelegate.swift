import Flutter
import UIKit
import GoogleSignIn
import AppTrackingTransparency
import AdSupport
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Firebase'i başlat
    FirebaseApp.configure()
    NSLog("🔥 Firebase yapılandırıldı")
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Push notifications için iOS setup
    setupPushNotifications(application)
    
    // Google Mobile Ads başlatma ve Native Ad Factory kaydı geçici olarak devre dışı.
    // Not: Reklamlar için gereklidir; doğru API ile yeniden eklenebilir.

    // iOS 14+ ATT izni iste (IDFA için)
    if #available(iOS 14, *) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        ATTrackingManager.requestTrackingAuthorization { _ in
          // No-op
        }
      }
    }
    
    // Google Sign-In konfigürasyonu
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let clientId = plist["CLIENT_ID"] as? String {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      NSLog("Google Sign-In konfigürasyonu başarılı: %@", clientId)
    } else {
      NSLog("⚠️ GoogleService-Info.plist dosyası bulunamadı veya CLIENT_ID eksik")
      // Fatal error yerine sadece log, uygulama çökmesin
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Push notifications setup
  private func setupPushNotifications(_ application: UIApplication) {
    NSLog("📱 iOS Push bildirim setup'ı başlıyor...")
    
    // UNUserNotificationCenter delegate set et
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          NSLog("📝 Push bildirim izni: \(granted ? "VERİLDİ ✅" : "REDDEDİLDİ ❌")")
          if let error = error {
            NSLog("⚠️ Push bildirim izin hatası: \(error.localizedDescription)")
          }
          // İzin akışı tamamlandıktan sonra APNs'e register ol
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    // Remote notifications için register (iOS < 10 fallback)
    // iOS 10+ tarafında izin akışı tamamlandığında register ediyoruz
    
    // Firebase Messaging delegate set et
    Messaging.messaging().delegate = self
    
    NSLog("✅ iOS Push bildirim setup'ı tamamlandı")
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    super.applicationWillTerminate(application)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Google Sign-In URL handling
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
  
  // MARK: - Remote Notifications
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    NSLog("🎯 APNs device token alındı")
    
    // Firebase Messaging'e device token'ı ver
    Messaging.messaging().apnsToken = deviceToken
    
    // Token'ı hex string olarak logla
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    NSLog("📱 APNs Token (hex): \(String(token.prefix(20)))...")
  }
  
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    NSLog("❌ APNs kayıt hatası: \(error.localizedDescription)")
  }
  
  // Background'da gelen notification'ları işle
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    NSLog("📨 Background remote notification alındı: \(userInfo)")
    
    // Firebase Analytics için
    if let messageID = userInfo["gcm.message_id"] {
      NSLog("📊 FCM Message ID: \(messageID)")
    }
    
    completionHandler(.newData)
  }
  
  // MARK: - UNUserNotificationCenter Delegate Methods (iOS 10+)
  // Foreground'da notification geldiğinde
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    
    NSLog("🔔 Foreground notification alındı: \(userInfo)")
    
    // Foreground'da da notification'ı göster
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // Notification'a tıklandığında
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    NSLog("👆 Notification tıklandı: \(userInfo)")
    
    // Firebase Analytics için
    if let messageID = userInfo["gcm.message_id"] {
      NSLog("📊 Tıklanan FCM Message ID: \(messageID)")
    }
    
    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  // FCM Token güncellendiğinde
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken = fcmToken else {
      NSLog("⚠️ FCM token nil geldi")
      return
    }
    
    NSLog("🔑 FCM Token güncellendi: \(String(fcmToken.prefix(20)))...")
    
    // Token'ı UserDefaults'a kaydet (isteğe bağlı)
    UserDefaults.standard.set(fcmToken, forKey: "fcm_token")
    
    // Flutter tarafına token'ı bildir (channel üzerinden gönderilebilin)
    // Bu kısmı ihtiyaç duyarsanız implement edebilirsiniz
  }
}
