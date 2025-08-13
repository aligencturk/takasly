import Flutter
import UIKit
import GoogleSignIn
import GoogleMobileAds
import google_mobile_ads
import AppTrackingTransparency
import AdSupport

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Google Mobile Ads başlat ve Native Ad Factory kaydet
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "listTile",
      nativeAdFactory: ListTileNativeAdFactory()
    )

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

  override func applicationWillTerminate(_ application: UIApplication) {
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "listTile")
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
}
