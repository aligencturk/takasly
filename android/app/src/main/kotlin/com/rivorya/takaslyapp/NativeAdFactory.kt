package com.rivorya.takaslyapp

import android.content.Context
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import com.google.android.gms.ads.nativead.MediaView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    private val TAG = "NativeAdFactory"

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        Log.d(TAG, "Native ad oluşturuluyor...")
        
        val nativeAdView = try {
            LayoutInflater.from(context)
                .inflate(R.layout.native_ad_layout, null) as NativeAdView
        } catch (e: Exception) {
            Log.e(TAG, "Layout inflate hatası: ${e.message}")
            throw e
        }

        try {
            // Media (ürün görseli gibi) - headline/body/cta ile çakışmaması için uygun scale
            nativeAdView.mediaView = nativeAdView.findViewById<MediaView>(R.id.ad_media)
            try {
                nativeAd.mediaContent?.let { media ->
                    nativeAdView.mediaView?.mediaContent = media
                    nativeAdView.mediaView?.setImageScaleType(ImageView.ScaleType.CENTER_CROP)
                }
            } catch (e: Exception) {
                Log.w(TAG, "MediaContent atama hatası: ${e.message}")
            }

            // Headline
            nativeAdView.headlineView = nativeAdView.findViewById(R.id.ad_headline)
            if (nativeAd.headline != null && nativeAd.headline!!.isNotEmpty()) {
                (nativeAdView.headlineView as TextView).text = nativeAd.headline
                nativeAdView.headlineView?.visibility = View.VISIBLE
            } else {
                nativeAdView.headlineView?.visibility = View.GONE
            }

            // Body (fallback'li)
            nativeAdView.bodyView = nativeAdView.findViewById(R.id.ad_body)
            try {
                val bodyCandidate = when {
                    !nativeAd.body.isNullOrBlank() -> nativeAd.body
                    !nativeAd.advertiser.isNullOrBlank() -> "Sponsor: ${nativeAd.advertiser}"
                    !nativeAd.store.isNullOrBlank() -> "Mağaza: ${nativeAd.store}"
                    !nativeAd.price.isNullOrBlank() -> "Fiyat: ${nativeAd.price}"
                    !nativeAd.callToAction.isNullOrBlank() -> nativeAd.callToAction
                    else -> "Sponsorlu içerik"
                }

                (nativeAdView.bodyView as TextView).text = bodyCandidate
                nativeAdView.bodyView?.visibility = View.VISIBLE
            } catch (e: Exception) {
                Log.w(TAG, "Body metni ayarlanırken hata: ${e.message}")
                // En kötü senaryoda boş bırakma, kullanıcıya en azından sponsorlu bilgisini göster
                (nativeAdView.bodyView as TextView).text = "Sponsorlu içerik"
                nativeAdView.bodyView?.visibility = View.VISIBLE
            }

            // Call to action (NativeAdView gereklilikleri için clickable view) - container + label ile
            val ctaButton = nativeAdView.findViewById<Button>(R.id.ad_call_to_action)
            nativeAdView.callToActionView = ctaButton
            try {
                val ctaText = when {
                    !nativeAd.callToAction.isNullOrBlank() -> nativeAd.callToAction
                    !nativeAd.price.isNullOrBlank() -> "Satın Al"
                    !nativeAd.store.isNullOrBlank() -> "Yükle"
                    !nativeAd.advertiser.isNullOrBlank() -> "İncele"
                    else -> "İncele"
                }
                ctaButton.text = ctaText
                ctaButton.visibility = View.VISIBLE
                ctaButton.isClickable = true
                ctaButton.isEnabled = true
            } catch (e: Exception) {
                Log.w(TAG, "CTA metni ayarlanırken hata: ${e.message}")
                try {
                    ctaButton.text = "İncele"
                    ctaButton.visibility = View.VISIBLE
                } catch (_: Exception) {}
            }

            // Advertiser
            nativeAdView.advertiserView = nativeAdView.findViewById(R.id.ad_advertiser)
            val advertiserText = if (nativeAd.advertiser.isNullOrEmpty()) "" else nativeAd.advertiser
            (nativeAdView.advertiserView as TextView).text = advertiserText
            nativeAdView.advertiserView?.visibility = if (advertiserText.isNullOrEmpty()) View.GONE else View.VISIBLE



            // Native ad'ı view'a bağla
            try {
                nativeAdView.setNativeAd(nativeAd)
                Log.d(TAG, "Native ad başarıyla oluşturuldu")
            } catch (e: Exception) {
                Log.e(TAG, "Native ad bağlama hatası: ${e.message}")
                throw e
            }

        } catch (e: Exception) {
            Log.e(TAG, "Native ad oluşturma hatası: ${e.message}")
            
            // Hata durumunda minimum görünüm sağla
            try {
                Log.d(TAG, "Minimum native ad görünümü oluşturuluyor...")
                
                nativeAdView.headlineView = nativeAdView.findViewById(R.id.ad_headline)
                if (nativeAd.headline != null && nativeAd.headline!!.isNotEmpty()) {
                    (nativeAdView.headlineView as TextView).text = nativeAd.headline
                    nativeAdView.headlineView?.visibility = View.VISIBLE
                }
                
                val ctaButton2 = nativeAdView.findViewById<Button>(R.id.ad_call_to_action)
                nativeAdView.callToActionView = ctaButton2
                val fallbackCta = if (!nativeAd.callToAction.isNullOrBlank()) nativeAd.callToAction else "İncele"
                ctaButton2.text = fallbackCta
                ctaButton2.visibility = View.VISIBLE
                
                nativeAdView.setNativeAd(nativeAd)
                Log.d(TAG, "Minimum native ad görünümü başarıyla oluşturuldu")
            } catch (e2: Exception) {
                Log.e(TAG, "Minimum native ad görünümü oluşturma hatası: ${e2.message}")
                
                // Son çare olarak sadece native ad'ı bağla
                try {
                    nativeAdView.setNativeAd(nativeAd)
                    Log.d(TAG, "Son çare native ad bağlama başarılı")
                } catch (e3: Exception) {
                    Log.e(TAG, "Son çare native ad bağlama hatası: ${e3.message}")
                    throw e3
                }
            }
        }

        return nativeAdView
    }
} 