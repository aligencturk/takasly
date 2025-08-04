import Flutter
import UIKit
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Native ad factory'yi kaydet
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
        self,
        factoryId: "listTile",
        nativeAdFactory: NativeAdFactory()
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Native ad factory'yi temizle
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "listTile")
  }
}

// Native Ad Factory for iOS
class NativeAdFactory : FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd,
                       customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        let nibView = Bundle.main.loadNibNamed("NativeAdView", owner: nil, options: nil)!.first
        let nativeAdView = nibView as! GADNativeAdView
        
        // Headline
        (nativeAdView.headlineView as! UILabel).text = nativeAd.headline
        
        // Body
        (nativeAdView.bodyView as! UILabel).text = nativeAd.body
        
        // Call to action
        (nativeAdView.callToActionView as! UIButton).setTitle(nativeAd.callToAction, for: .normal)
        
        // Icon
        (nativeAdView.iconView as! UIImageView).image = nativeAd.icon?.image
        
        // Star rating
        (nativeAdView.starRatingView as! UIImageView).image = imageOfStars(from: nativeAd.starRating)
        
        // Advertiser
        (nativeAdView.advertiserView as! UILabel).text = nativeAd.advertiser
        
        // Store
        (nativeAdView.storeView as! UILabel).text = nativeAd.store
        
        // Price
        (nativeAdView.priceView as! UILabel).text = nativeAd.price
        
        nativeAdView.nativeAd = nativeAd
        
        return nativeAdView
    }
    
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else { return nil }
        let starCount = Int(rating)
        let imageName = "stars_\(starCount)"
        return UIImage(named: imageName)
    }
}
