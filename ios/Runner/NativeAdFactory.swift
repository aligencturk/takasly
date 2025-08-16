import GoogleMobileAds
import UIKit

class NativeAdFactory: NSObject, FLTNativeAdFactory {
    
    func createNativeAd(_ nativeAd: NativeAd, customOptions: [AnyHashable : Any]? = nil) -> NativeAdView? {
        NSLog("iOS NativeAdFactory: Native ad oluşturuluyor...")
        
        // Programatik olarak NativeAdView oluştur
        let adView = NativeAdView()
        adView.backgroundColor = UIColor.systemBackground
        
        // Native ad'ı configure et
        configureNativeAdView(adView, with: nativeAd)
        
        NSLog("✅ iOS NativeAdFactory: Native ad başarıyla oluşturuldu")
        return adView
    }
    
    private func configureNativeAdView(_ adView: NativeAdView, with nativeAd: NativeAd) {
        // Container view
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(containerView)
        
        // Icon image view
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)
        adView.iconView = iconView
        
        // Headline label
        let headlineView = UILabel()
        headlineView.font = UIFont.boldSystemFont(ofSize: 17)
        headlineView.textColor = UIColor.label
        headlineView.numberOfLines = 2
        headlineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headlineView)
        adView.headlineView = headlineView
        
        // Body label
        let bodyView = UILabel()
        bodyView.font = UIFont.systemFont(ofSize: 13)
        bodyView.textColor = UIColor.secondaryLabel
        bodyView.numberOfLines = 2
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bodyView)
        adView.bodyView = bodyView
        
        // Advertiser label
        let advertiserView = UILabel()
        advertiserView.font = UIFont.systemFont(ofSize: 10)
        advertiserView.textColor = UIColor.tertiaryLabel
        advertiserView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(advertiserView)
        adView.advertiserView = advertiserView
        
        // Call to action button
        let ctaButton = UIButton(type: .system)
        ctaButton.backgroundColor = UIColor.systemBlue
        ctaButton.setTitleColor(UIColor.white, for: .normal)
        ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        ctaButton.layer.cornerRadius = 8
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ctaButton)
        adView.callToActionView = ctaButton
        
        // Media view
        let mediaView = MediaView()
        mediaView.backgroundColor = UIColor.systemGray6
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mediaView)
        adView.mediaView = mediaView
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Container view constraints
            containerView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),
            
            // Icon constraints
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),
            
            // Headline constraints
            headlineView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            headlineView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            headlineView.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -12),
            
            // Body constraints
            bodyView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 4),
            bodyView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            bodyView.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -12),
            
            // Advertiser constraints
            advertiserView.topAnchor.constraint(equalTo: bodyView.bottomAnchor, constant: 4),
            advertiserView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            advertiserView.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -12),
            
            // CTA button constraints
            ctaButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            ctaButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            ctaButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            ctaButton.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            ctaButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Media view constraints
            mediaView.topAnchor.constraint(equalTo: advertiserView.bottomAnchor, constant: 4),
            mediaView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mediaView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            mediaView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            mediaView.heightAnchor.constraint(lessThanOrEqualToConstant: 120)
        ])
        
        // Set content from native ad
        setNativeAdContent(adView: adView, nativeAd: nativeAd)
        
        // Set the native ad
        adView.nativeAd = nativeAd
        
        NSLog("iOS NativeAdFactory: Native ad configured")
    }
    
    private func setNativeAdContent(adView: NativeAdView, nativeAd: NativeAd) {
        // Headline
        if let headlineView = adView.headlineView as? UILabel {
            if let headline = nativeAd.headline, !headline.isEmpty {
                headlineView.text = headline
                headlineView.isHidden = false
            } else {
                headlineView.isHidden = true
            }
        }
        
        // Body text (fallback'li)
        if let bodyView = adView.bodyView as? UILabel {
            var bodyText = ""
            
            if let body = nativeAd.body, !body.isEmpty {
                bodyText = body
            } else if let advertiser = nativeAd.advertiser, !advertiser.isEmpty {
                bodyText = "Sponsor: \(advertiser)"
            } else if let store = nativeAd.store, !store.isEmpty {
                bodyText = "Mağaza: \(store)"
            } else if let price = nativeAd.price, !price.isEmpty {
                bodyText = "Fiyat: \(price)"
            } else if let callToAction = nativeAd.callToAction, !callToAction.isEmpty {
                bodyText = callToAction
            } else {
                bodyText = "Sponsorlu içerik"
            }
            
            bodyView.text = bodyText
            bodyView.isHidden = false
        }
        
        // Call to action button
        if let ctaButton = adView.callToActionView as? UIButton {
            var ctaText = "İncele"
            
            if let callToAction = nativeAd.callToAction, !callToAction.isEmpty {
                switch callToAction.lowercased() {
                case let cta where cta.contains("install") || cta.contains("yükle"):
                    ctaText = "Yükle"
                case let cta where cta.contains("shop") || cta.contains("alışveriş"):
                    ctaText = "Alışveriş"
                case let cta where cta.contains("play") || cta.contains("oyna"):
                    ctaText = "Oyna"
                case let cta where cta.contains("download") || cta.contains("indir"):
                    ctaText = "İndir"
                case let cta where cta.contains("visit") || cta.contains("ziyaret"):
                    ctaText = "Ziyaret Et"
                default:
                    ctaText = callToAction.count > 15 ? "İncele" : callToAction
                }
            }
            
            ctaButton.setTitle(ctaText, for: .normal)
            ctaButton.isHidden = false
            ctaButton.isEnabled = true
        }
        
        // Icon
        if let iconView = adView.iconView as? UIImageView {
            if let icon = nativeAd.icon {
                iconView.image = icon.image
                iconView.isHidden = false
            } else {
                iconView.isHidden = true
            }
        }
        
        // Advertiser
        if let advertiserView = adView.advertiserView as? UILabel {
            if let advertiser = nativeAd.advertiser, !advertiser.isEmpty {
                advertiserView.text = advertiser
                advertiserView.isHidden = false
            } else {
                advertiserView.isHidden = true
            }
        }
        
        // Media view
        if let mediaView = adView.mediaView {
            let mediaContent = nativeAd.mediaContent
            mediaView.mediaContent = mediaContent
            mediaView.isHidden = false
        }
    }
}
