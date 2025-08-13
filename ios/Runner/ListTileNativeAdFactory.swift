import Foundation
import GoogleMobileAds
import UIKit

final class ListTileNativeAdFactory: NSObject, GADNativeAdFactory {
  func createNativeAd(_ nativeAd: GADNativeAd, with options: GADNativeAdViewAdOptions?) -> GADNativeAdView {
    let adView = GADNativeAdView(frame: .zero)

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = UIColor.white
    container.layer.cornerRadius = 12
    container.layer.borderWidth = 1
    container.layer.borderColor = UIColor(white: 0.82, alpha: 1).cgColor

    // Views
    let headlineLabel = UILabel()
    headlineLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    headlineLabel.numberOfLines = 2

    let bodyLabel = UILabel()
    bodyLabel.font = UIFont.systemFont(ofSize: 13)
    bodyLabel.textColor = UIColor.darkGray
    bodyLabel.numberOfLines = 2

    let iconView = UIImageView()
    iconView.contentMode = .scaleAspectFill
    iconView.layer.cornerRadius = 8
    iconView.clipsToBounds = true
    iconView.widthAnchor.constraint(equalToConstant: 56).isActive = true
    iconView.heightAnchor.constraint(equalToConstant: 56).isActive = true

    let ctaButton = UIButton(type: .system)
    ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    ctaButton.setTitleColor(.white, for: .normal)
    ctaButton.backgroundColor = UIColor(red: 0.20, green: 0.45, blue: 0.90, alpha: 1.0)
    ctaButton.layer.cornerRadius = 8
    ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

    let vStack = UIStackView()
    vStack.axis = .vertical
    vStack.spacing = 4
    vStack.translatesAutoresizingMaskIntoConstraints = false
    vStack.addArrangedSubview(headlineLabel)
    vStack.addArrangedSubview(bodyLabel)

    let hStack = UIStackView()
    hStack.axis = .horizontal
    hStack.alignment = .center
    hStack.distribution = .fill
    hStack.spacing = 12
    hStack.translatesAutoresizingMaskIntoConstraints = false
    hStack.addArrangedSubview(iconView)
    hStack.addArrangedSubview(vStack)
    hStack.addArrangedSubview(ctaButton)

    container.addSubview(hStack)
    adView.addSubview(container)

    NSLayoutConstraint.activate([
      container.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      container.topAnchor.constraint(equalTo: adView.topAnchor),
      container.bottomAnchor.constraint(equalTo: adView.bottomAnchor),

      hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
      hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
      hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
      hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
    ])

    // Map native assets
    adView.headlineView = headlineLabel
    adView.bodyView = bodyLabel
    adView.iconView = iconView
    adView.callToActionView = ctaButton

    headlineLabel.text = nativeAd.headline
    bodyLabel.text = nativeAd.body
    if let icon = nativeAd.icon { iconView.image = icon.image } else { iconView.isHidden = true }
    ctaButton.setTitle(nativeAd.callToAction, for: .normal)
    ctaButton.isUserInteractionEnabled = false

    adView.nativeAd = nativeAd
    return adView
  }
}



