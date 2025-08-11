import Flutter
import UIKit
import google_mobile_ads
import Firebase
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase konfigürasyonu
    FirebaseApp.configure()
    
    // Bildirim için mesaj delegate'ini ayarla
    Messaging.messaging().delegate = self
    
    // iOS bildirim ayarları
    UNUserNotificationCenter.current().delegate = self

    // Bildirim izinlerini talep et
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional, .criticalAlert]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        if granted {
          print("iOS bildirim izinleri verildi")
        } else {
          print("iOS bildirim izinleri reddedildi: \(String(describing: error))")
        }
      }
    )
 
    // Bildirim kayıt ayarları
    application.registerForRemoteNotifications()
    
    // APNs ayarları
    if #available(iOS 10.0, *) {
      // iOS 10 ve üzeri için
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional, .criticalAlert]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      // iOS 9 ve altı için (daha eski sürümler için)
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    // Foreground bildirimleri için ayar
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    // Google Mobile Ads SDK başlatma (iOS) - güvenli başlatma
    MobileAds.shared.start { status in
      print("✅ AdMob iOS başlatıldı: \(status.adapterStatusesByClassName)")
    }
    
    // Flutter plugins kaydı
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
  
  // APNs token'ı Firebase'e bağla
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("APNs token alındı ve Firebase'e bağlanıyor")
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // APNs kayıt hatası durumunda
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("APNs kayıt hatası: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  
  // Arka plan bildirimleri için
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("Arka plan bildirimi alındı: \(userInfo)")
    
    // Bildirimi FirebaseMessaging'e ilet
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // Üst sınıfın metodunu çağır
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
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
}

// FCM Token yenileme davranışı için FirebaseMessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase Token güncellendi: \(String(describing: fcmToken))")
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}

// Foreground bildirim davranışı için UNUserNotificationCenterDelegate
@available(iOS 10.0, *)
extension AppDelegate {
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("Ön planda bildirim alındı: \(userInfo)")
    
    // Bildirimi FirebaseMessaging'e ilet
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // iOS 14+ için tüm bildirim seçeneklerini göster
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("Bildirime tıklandı: \(userInfo)")
    
    // Bildirimi FirebaseMessaging'e ilet
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
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
