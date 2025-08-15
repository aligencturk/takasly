import GoogleMobileAds
import UIKit

class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd, customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        let nibView = Bundle.main.loadNibNamed("ListTileNativeAdView", owner: nil, options: nil)?.first as? GADNativeAdView
        
        // Başlık
        (nibView?.headlineView as? UILabel)?.text = nativeAd.headline
        
        // Açıklama
        (nibView?.bodyView as? UILabel)?.text = nativeAd.body
        nibView?.bodyView?.isHidden = nativeAd.body == nil
        
        // Reklamveren adı
        (nibView?.advertiserView as? UILabel)?.text = nativeAd.advertiser
        
        // Resim
        if let image = nativeAd.images?.first?.image {
            (nibView?.imageView as? UIImageView)?.image = image
        }
        
        nibView?.nativeAd = nativeAd
        return nibView
    }
}
