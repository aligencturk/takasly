import Flutter
import UIKit
import GoogleSignIn
import AppTrackingTransparency
import AdSupport
import Firebase
import FirebaseMessaging
import UserNotifications
import GoogleMobileAds
import google_mobile_ads // FLTNativeAdFactory ve FLTGoogleMobileAdsPlugin için

// MARK: - iOS Native Ad Factory (XIB'siz basit layout)
class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: NativeAd, customOptions: [AnyHashable : Any]? = nil) -> NativeAdView? {
        let adView = NativeAdView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100))
        adView.backgroundColor = .systemBackground

        let headline = UILabel()
        headline.translatesAutoresizingMaskIntoConstraints = false
        headline.font = UIFont.boldSystemFont(ofSize: 16)
        headline.numberOfLines = 2
        headline.text = nativeAd.headline
        adView.headlineView = headline

        let body = UILabel()
        body.translatesAutoresizingMaskIntoConstraints = false
        body.font = UIFont.systemFont(ofSize: 14)
        body.textColor = .secondaryLabel
        body.numberOfLines = 2
        body.text = nativeAd.body
        adView.bodyView = body

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        if let img = nativeAd.images?.first?.image { imageView.image = img }
        adView.imageView = imageView

        let advertiser = UILabel()
        advertiser.translatesAutoresizingMaskIntoConstraints = false
        advertiser.font = UIFont.systemFont(ofSize: 12)
        advertiser.textColor = .tertiaryLabel
        advertiser.text = nativeAd.advertiser
        adView.advertiserView = advertiser

        let stack = UIStackView(arrangedSubviews: [headline, body, advertiser])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(imageView)
        adView.addSubview(stack)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: adView.topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            stack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: adView.centerYAnchor)
        ])

        adView.nativeAd = nativeAd
        return adView
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase
    FirebaseApp.configure()
    NSLog("🔥 Firebase yapılandırıldı")

    GeneratedPluginRegistrant.register(with: self)

    // Google Mobile Ads – yeni API
    MobileAds.shared.start(completionHandler: { _ in
      NSLog("📱 Google Mobile Ads başlatıldı")
    })

    // iOS NativeAdFactory kaydı (Android ile aynı factoryId)
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "listTile",
      nativeAdFactory: ListTileNativeAdFactory()
    )

    setupPushNotifications(application)

    if #available(iOS 14, *) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        ATTrackingManager.requestTrackingAuthorization { _ in }
      }
    }

    // Google Sign-In
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let clientId = plist["CLIENT_ID"] as? String {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      NSLog("Google Sign-In konfigürasyonu başarılı: %@", clientId)
    } else {
      NSLog("⚠️ GoogleService-Info.plist yok veya CLIENT_ID eksik")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupPushNotifications(_ application: UIApplication) {
    NSLog("📱 iOS Push bildirim setup başlıyor...")
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
        NSLog("📝 Push izni: \(granted ? "VERİLDİ ✅" : "REDDEDİLDİ ❌")")
        if let error = error { NSLog("⚠️ Push izin hatası: \(error.localizedDescription)") }
        DispatchQueue.main.async { application.registerForRemoteNotifications() }
      }
    } else {
      let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    Messaging.messaging().delegate = self
    NSLog("✅ Push setup tamamlandı")
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "listTile")
    super.applicationWillTerminate(application)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if GIDSignIn.sharedInstance.handle(url) { return true }
    return super.application(app, open: url, options: options)
  }

  // MARK: - Remote Notifications
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    NSLog("📱 APNs Token: \(String(token.prefix(20)))...")
  }

  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    NSLog("❌ APNs kayıt hatası: \(error.localizedDescription)")
  }

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if let messageID = userInfo["gcm.message_id"] {
      NSLog("📊 FCM Message ID: \(messageID)")
    }
    completionHandler(.newData)
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
    if let messageID = response.notification.request.content.userInfo["gcm.message_id"] {
      NSLog("📊 Tıklanan FCM Message ID: \(messageID)")
    }
    completionHandler()
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken = fcmToken else { return }
    NSLog("🔑 FCM Token güncellendi: \(String(fcmToken.prefix(20)))...")
    UserDefaults.standard.set(fcmToken, forKey: "fcm_token")
  }
}
