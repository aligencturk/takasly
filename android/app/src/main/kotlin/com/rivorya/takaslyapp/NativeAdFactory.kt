package com.rivorya.takaslyapp

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        try {
            // Headline
            nativeAdView.headlineView = nativeAdView.findViewById(R.id.ad_headline)
            if (nativeAd.headline != null) {
                (nativeAdView.headlineView as TextView).text = nativeAd.headline
                nativeAdView.headlineView?.visibility = View.VISIBLE
            } else {
                nativeAdView.headlineView?.visibility = View.GONE
            }

            // Body
            nativeAdView.bodyView = nativeAdView.findViewById(R.id.ad_body)
            if (nativeAd.body == null || nativeAd.body!!.isEmpty()) {
                nativeAdView.bodyView?.visibility = View.GONE
            } else {
                nativeAdView.bodyView?.visibility = View.VISIBLE
                (nativeAdView.bodyView as TextView).text = nativeAd.body
            }

            // Call to action
            nativeAdView.callToActionView = nativeAdView.findViewById(R.id.ad_call_to_action)
            if (nativeAd.callToAction == null || nativeAd.callToAction!!.isEmpty()) {
                nativeAdView.callToActionView?.visibility = View.GONE
            } else {
                nativeAdView.callToActionView?.visibility = View.VISIBLE
                (nativeAdView.callToActionView as Button).text = nativeAd.callToAction
            }

            // Icon
            nativeAdView.iconView = nativeAdView.findViewById(R.id.ad_icon)
            if (nativeAd.icon == null) {
                nativeAdView.iconView?.visibility = View.GONE
            } else {
                try {
                    (nativeAdView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
                    nativeAdView.iconView?.visibility = View.VISIBLE
                } catch (e: Exception) {
                    nativeAdView.iconView?.visibility = View.GONE
                }
            }

            // Star rating
            nativeAdView.starRatingView = nativeAdView.findViewById(R.id.ad_stars)
            if (nativeAd.starRating == null) {
                nativeAdView.starRatingView?.visibility = View.GONE
            } else {
                try {
                    (nativeAdView.starRatingView as RatingBar).rating = nativeAd.starRating!!.toFloat()
                    nativeAdView.starRatingView?.visibility = View.VISIBLE
                } catch (e: Exception) {
                    nativeAdView.starRatingView?.visibility = View.GONE
                }
            }

            // Advertiser
            nativeAdView.advertiserView = nativeAdView.findViewById(R.id.ad_advertiser)
            if (nativeAd.advertiser == null || nativeAd.advertiser!!.isEmpty()) {
                nativeAdView.advertiserView?.visibility = View.GONE
            } else {
                nativeAdView.advertiserView?.visibility = View.VISIBLE
                (nativeAdView.advertiserView as TextView).text = nativeAd.advertiser
            }

            // Store
            nativeAdView.storeView = nativeAdView.findViewById(R.id.ad_store)
            if (nativeAd.store == null || nativeAd.store!!.isEmpty()) {
                nativeAdView.storeView?.visibility = View.GONE
            } else {
                nativeAdView.storeView?.visibility = View.VISIBLE
                (nativeAdView.storeView as TextView).text = nativeAd.store
            }

            // Price
            nativeAdView.priceView = nativeAdView.findViewById(R.id.ad_price)
            if (nativeAd.price == null || nativeAd.price!!.isEmpty()) {
                nativeAdView.priceView?.visibility = View.GONE
            } else {
                nativeAdView.priceView?.visibility = View.VISIBLE
                (nativeAdView.priceView as TextView).text = nativeAd.price
            }

            // Native ad'ı view'a bağla
            nativeAdView.setNativeAd(nativeAd)

        } catch (e: Exception) {
            // Hata durumunda minimum görünüm sağla
            try {
                nativeAdView.headlineView = nativeAdView.findViewById(R.id.ad_headline)
                if (nativeAd.headline != null) {
                    (nativeAdView.headlineView as TextView).text = nativeAd.headline
                    nativeAdView.headlineView?.visibility = View.VISIBLE
                }
                
                nativeAdView.callToActionView = nativeAdView.findViewById(R.id.ad_call_to_action)
                if (nativeAd.callToAction != null) {
                    (nativeAdView.callToActionView as Button).text = nativeAd.callToAction
                    nativeAdView.callToActionView?.visibility = View.VISIBLE
                }
                
                nativeAdView.setNativeAd(nativeAd)
            } catch (e2: Exception) {
                // Son çare olarak sadece native ad'ı bağla
                nativeAdView.setNativeAd(nativeAd)
            }
        }

        return nativeAdView
    }
} 