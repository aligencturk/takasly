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

        // Headline
        nativeAdView.headlineView = nativeAdView.findViewById(R.id.ad_headline)
        (nativeAdView.headlineView as TextView).text = nativeAd.headline

        // Body
        nativeAdView.bodyView = nativeAdView.findViewById(R.id.ad_body)
        if (nativeAd.body == null) {
            nativeAdView.bodyView?.visibility = View.INVISIBLE
        } else {
            nativeAdView.bodyView?.visibility = View.VISIBLE
            (nativeAdView.bodyView as TextView).text = nativeAd.body
        }

        // Call to action
        nativeAdView.callToActionView = nativeAdView.findViewById(R.id.ad_call_to_action)
        if (nativeAd.callToAction == null) {
            nativeAdView.callToActionView?.visibility = View.INVISIBLE
        } else {
            nativeAdView.callToActionView?.visibility = View.VISIBLE
            (nativeAdView.callToActionView as Button).text = nativeAd.callToAction
        }

        // Icon
        nativeAdView.iconView = nativeAdView.findViewById(R.id.ad_icon)
        if (nativeAd.icon == null) {
            nativeAdView.iconView?.visibility = View.GONE
        } else {
            (nativeAdView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
            nativeAdView.iconView?.visibility = View.VISIBLE
        }

        // Star rating
        nativeAdView.starRatingView = nativeAdView.findViewById(R.id.ad_stars)
        if (nativeAd.starRating == null) {
            nativeAdView.starRatingView?.visibility = View.INVISIBLE
        } else {
            (nativeAdView.starRatingView as RatingBar).rating = nativeAd.starRating!!.toFloat()
            nativeAdView.starRatingView?.visibility = View.VISIBLE
        }

        // Advertiser
        nativeAdView.advertiserView = nativeAdView.findViewById(R.id.ad_advertiser)
        if (nativeAd.advertiser == null) {
            nativeAdView.advertiserView?.visibility = View.INVISIBLE
        } else {
            (nativeAdView.advertiserView as TextView).text = nativeAd.advertiser
            nativeAdView.advertiserView?.visibility = View.VISIBLE
        }

        // Store
        nativeAdView.storeView = nativeAdView.findViewById(R.id.ad_store)
        if (nativeAd.store == null) {
            nativeAdView.storeView?.visibility = View.INVISIBLE
        } else {
            (nativeAdView.storeView as TextView).text = nativeAd.store
            nativeAdView.storeView?.visibility = View.VISIBLE
        }

        // Price
        nativeAdView.priceView = nativeAdView.findViewById(R.id.ad_price)
        if (nativeAd.price == null) {
            nativeAdView.priceView?.visibility = View.INVISIBLE
        } else {
            (nativeAdView.priceView as TextView).text = nativeAd.price
            nativeAdView.priceView?.visibility = View.VISIBLE
        }

        nativeAdView.setNativeAd(nativeAd)

        return nativeAdView
    }
} 