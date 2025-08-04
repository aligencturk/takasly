package com.rivorya.takaslyapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    
    private var isNativeAdFactoryRegistered = false
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            // Native Ad Factory'yi kaydet
            GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine,
                "listTile",
                NativeAdFactory(context)
            )
            isNativeAdFactoryRegistered = true
        } catch (e: Exception) {
            // Hata durumunda log'la ama uygulamayı durdurma
            e.printStackTrace()
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            // Native Ad Factory'yi temizle
            if (isNativeAdFactoryRegistered) {
                GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
                isNativeAdFactoryRegistered = false
            }
        } catch (e: Exception) {
            // Hata durumunda log'la ama uygulamayı durdurma
            e.printStackTrace()
        } finally {
            super.cleanUpFlutterEngine(flutterEngine)
        }
    }
    
    override fun onDestroy() {
        try {
            // Ek temizlik işlemleri
            if (isNativeAdFactoryRegistered) {
                // Flutter engine hala mevcutsa temizle
                flutterEngine?.let { engine ->
                    GoogleMobileAdsPlugin.unregisterNativeAdFactory(engine, "listTile")
                }
                isNativeAdFactoryRegistered = false
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            super.onDestroy()
        }
    }
} 