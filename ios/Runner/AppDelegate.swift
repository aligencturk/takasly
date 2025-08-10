import Flutter
import UIKit
import google_mobile_ads
import Firebase
import FirebaseMessaging
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase konfigürasyonu
    FirebaseApp.configure()

    // Google Mobile Ads SDK başlatma (iOS) - güvenli başlatma
    MobileAds.shared.start { status in
      print("✅ AdMob iOS başlatıldı: \(status.adapterStatusesByClassName)")
    }
    
    // FCM için notification ayarları
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("🔔 iOS Notification permission granted: \(granted), error: \(String(describing: error))")
          UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔧 iOS Notification settings: authorizationStatus=\(settings.authorizationStatus.rawValue)")
            print("🔧 iOS Notification settings: alertSetting=\(settings.alertSetting.rawValue)")
            print("🔧 iOS Notification settings: soundSetting=\(settings.soundSetting.rawValue)")
            print("🔧 iOS Notification settings: badgeSetting=\(settings.badgeSetting.rawValue)")
          }
        })
    } else {
      let settings: UIUserNotificationSettings =
      UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self
    
    // FCM için özel ayarlar
    Messaging.messaging().isAutoInitEnabled = true
    
    // APNS token'ı erken ayarlamaya çalış (iOS simülatör için)
    if let apnsToken = Messaging.messaging().apnsToken {
        print("✅ APNS Token zaten mevcut: \(apnsToken)")
    } else {
        print("⚠️ APNS Token henüz ayarlanmamış, remote notification kaydı bekleniyor...")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Native ad factory'yi güvenli şekilde kaydet
    do {
      FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
          self,
          factoryId: "listTile",
          nativeAdFactory: NativeAdFactory()
      )
      print("✅ Native Ad Factory başarıyla kaydedildi")
    } catch {
      print("❌ Native Ad Factory kaydetme hatası: \(error)")
    }

    // iOS 14+ için App Tracking Transparency izni (reklam doldurma oranını iyileştirir)
    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { status in
        // İzin sonucu burada döner; gerektiğinde ek konfigürasyon yapılabilir
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Native ad factory'yi güvenli şekilde temizle
    do {
      FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "listTile")
      print("✅ Native Ad Factory başarıyla temizlendi")
    } catch {
      print("❌ Native Ad Factory temizleme hatası: \(error)")
    }
  }
  
  // MARK: - FCM Delegate Methods
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    let dataDict:[String: String] = ["token": fcmToken ?? ""]
    print("🎯 FCM Registration Token (delegate): \(fcmToken ?? "<nil>")")
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
  }
  
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let tokenHex = tokenParts.joined()
    print("📱 iOS APNS Device Token (hex): \(tokenHex)")
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNS Token Firebase Messaging'e ayarlandı")

    // APNS set edildikten sonra FCM token'ı tekrar almaya çalış
    Messaging.messaging().token { token, error in
      if let error = error {
        print("⚠️ FCM token alma hatası (native): \(error)")
      } else if let token = token {
        print("🎯 FCM Token (native fetch): \(token)")
      } else {
        print("⚠️ FCM Token (native fetch) null döndü")
      }
    }
  }
  
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ iOS APNS kayıt hatası: \(error)")
  }
  
  // MARK: - UNUserNotificationCenterDelegate
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      willPresent notification: UNNotification,
                                      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("🔔 willPresent notification: \(notification.request.content.title)")
    print("🔔 Notification content: \(notification.request.content.body)")
    print("🔔 Notification userInfo: \(notification.request.content.userInfo)")
    
    // iOS 14+ için tüm presentation options'ları aç
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound, .list])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // iOS background/silent notification handling (when proxy disabled)
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📩 didReceiveRemoteNotification: \(userInfo)")
    
    // Firebase Messaging'e ilet
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // Notification content'ini kontrol et
    if let aps = userInfo["aps"] as? [String: Any] {
      print("📱 APS content: \(aps)")
      
      if let alert = aps["alert"] as? [String: Any] {
        print("🔔 Alert: \(alert)")
      }
      
      // Local notification oluştur (test için)
      if let alert = aps["alert"] as? [String: Any],
         let title = alert["title"] as? String,
         let body = alert["body"] as? String {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
          if let error = error {
            print("❌ Local notification hatası: \(error)")
          } else {
            print("✅ Local notification eklendi")
          }
        }
      }
    }
    
    completionHandler(.newData)
  }
  
  // FCM mesajları için özel handling - iOS'ta RemoteMessage yok
  func messaging(_ messaging: Messaging, didReceiveMessage userInfo: [AnyHashable: Any]) {
    print("📨 FCM didReceiveMessage: \(userInfo)")
    
    // Notification content'ini kontrol et
    if let aps = userInfo["aps"] as? [String: Any] {
      print("📱 APS content: \(aps)")
      
      if let alert = aps["alert"] as? [String: Any] {
        print("🔔 Alert: \(alert)")
        
        // Local notification oluştur (test için)
        if let title = alert["title"] as? String,
           let body = alert["body"] as? String {
          
          let content = UNMutableNotificationContent()
          content.title = title
          content.body = body
          content.sound = UNNotificationSound.default
          
          let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
          UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
              print("❌ FCM local notification hatası: \(error)")
            } else {
              print("✅ FCM local notification eklendi")
            }
          }
        }
      }
    }
    
    if let data = userInfo["data"] as? [String: Any] {
      print("📊 FCM Data: \(data)")
    }
  }
  
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      didReceive response: UNNotificationResponse,
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
    print("🔔 didReceive notification response: \(response.notification.request.content.title)")
    completionHandler()
  }
}

// Native Ad Factory for iOS - Programmatik versiyon (XIB kullanmıyor)
class NativeAdFactory : FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: NativeAd,
                       customOptions: [AnyHashable : Any]? = nil) -> NativeAdView? {
        // Programmatik NativeAdView
        let adView = NativeAdView()
        adView.translatesAutoresizingMaskIntoConstraints = false
        adView.backgroundColor = .white
        adView.layer.cornerRadius = 8
        adView.layer.borderWidth = 1
        adView.layer.borderColor = UIColor.systemGray4.cgColor
        adView.clipsToBounds = true

        // Container
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            container.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12)
        ])

        // MediaView (ANA görsel/video buraya)
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.backgroundColor = .secondarySystemBackground
        container.addSubview(mediaView)
        adView.mediaView = mediaView

        // Icon
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 6
        iconView.clipsToBounds = true
        container.addSubview(iconView)
        adView.iconView = iconView

        // Headline (zorunlu)
        let headlineLabel = UILabel()
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = .boldSystemFont(ofSize: 16)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 2
        container.addSubview(headlineLabel)
        adView.headlineView = headlineLabel

        // Body (opsiyonel)
        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 3
        container.addSubview(bodyLabel)
        adView.bodyView = bodyLabel

        // Advertiser (opsiyonel)
        let advertiserLabel = UILabel()
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        advertiserLabel.font = .systemFont(ofSize: 12)
        advertiserLabel.textColor = .tertiaryLabel
        container.addSubview(advertiserLabel)
        adView.advertiserView = advertiserLabel

        // CTA (önerilir)
        let ctaButton = UIButton(type: .system)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.backgroundColor = .systemBlue
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        ctaButton.layer.cornerRadius = 8
        container.addSubview(ctaButton)
        adView.callToActionView = ctaButton

        // MediaView aspect ratio: width/height
        // mediaContent artık optional değil; oran 0 ise güvenli varsayılan kullan
        let mediaAspect = nativeAd.mediaContent.aspectRatio
        let aspectRatio = mediaAspect > 0 ? mediaAspect : (16.0/9.0)
        let mediaHeight = mediaView.heightAnchor.constraint(
            equalTo: mediaView.widthAnchor,
            multiplier: CGFloat(1.0 / aspectRatio)
        )
        mediaHeight.priority = UILayoutPriority.defaultHigh

        NSLayoutConstraint.activate([
            // MediaView üstte tam genişlik
            mediaView.topAnchor.constraint(equalTo: container.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mediaHeight,

            // Icon
            iconView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 10),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            // Headline
            headlineLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 10),
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            headlineLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            // Body
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 6),
            bodyLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            // Advertiser
            advertiserLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 6),
            advertiserLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            advertiserLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            // CTA
            ctaButton.topAnchor.constraint(equalTo: advertiserLabel.bottomAnchor, constant: 10),
            ctaButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            ctaButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ctaButton.heightAnchor.constraint(equalToConstant: 44),
            ctaButton.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Verileri bağla (mediaContent non-optional)
        let mediaContent = nativeAd.mediaContent
        mediaView.mediaContent = mediaContent
        mediaView.isHidden = false

        (adView.headlineView as? UILabel)?.text = nativeAd.headline

        if let body = nativeAd.body, !body.isEmpty {
            (adView.bodyView as? UILabel)?.text = body
            adView.bodyView?.isHidden = false
        } else {
            adView.bodyView?.isHidden = true
        }

        if let cta = nativeAd.callToAction, !cta.isEmpty {
            (adView.callToActionView as? UIButton)?.setTitle(cta, for: .normal)
            adView.callToActionView?.isHidden = false
        } else {
            adView.callToActionView?.isHidden = true
        }

        if let icon = nativeAd.icon?.image {
            (adView.iconView as? UIImageView)?.image = icon
            adView.iconView?.isHidden = false
        } else {
            adView.iconView?.isHidden = true
        }

        (adView.advertiserView as? UILabel)?.text = nativeAd.advertiser ?? ""

        // En sonda nativeAd'ı bağla
        adView.nativeAd = nativeAd

        return adView
    }
}
