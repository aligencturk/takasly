import UIKit
import Flutter
import GoogleMobileAds       // NativeAd, NativeAdView, MediaView
import google_mobile_ads     // FLTNativeAdFactory, FLTGoogleMobileAdsPlugin
import Firebase
import UserNotifications
import AppTrackingTransparency

class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(_ nativeAd: NativeAd,
                      customOptions: [AnyHashable : Any]? = nil) -> NativeAdView? {
    // XIB kullanıyorsan:
    guard let adView = Bundle.main.loadNibNamed("ListTileNativeAdView",
                                                owner: nil,
                                                options: nil)?.first as? NativeAdView else {
      NSLog("❌ XIB yüklenemedi")
      return nil
    }

    (adView.headlineView as? UILabel)?.text = nativeAd.headline
    (adView.bodyView as? UILabel)?.text = nativeAd.body
    (adView.advertiserView as? UILabel)?.text = nativeAd.advertiser

    if let img = nativeAd.images?.first?.image {
      (adView.imageView as? UIImageView)?.image = img
    }

    adView.mediaView?.mediaContent = nativeAd.mediaContent
    // CTA View kullanıcı etkileşimi Google Ads tarafından yönetilir:
    adView.callToActionView?.isUserInteractionEnabled = false

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

    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    // Google Mobile Ads SDK 11+
    MobileAds.shared.start(completionHandler: nil)

    // Tek KAYIT: factoryId Dart ile aynı olmalı ("listTile")
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "listTile",
      nativeAdFactory: ListTileNativeAdFactory()
    )

    if #available(iOS 14, *) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        ATTrackingManager.requestTrackingAuthorization { _ in }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "listTile")
    super.applicationWillTerminate(application)
  }
}
