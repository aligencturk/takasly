package com.rivorya.takaslyapp

import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    
    private var isNativeAdFactoryRegistered = false
    private val TAG = "MainActivity"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            Log.d(TAG, "Native Ad Factory kaydediliyor...")
            
            // Native Ad Factory'yi kaydet
            GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine,
                "listTile",
                NativeAdFactory(context)
            )
            isNativeAdFactoryRegistered = true
            Log.d(TAG, "Native Ad Factory başarıyla kaydedildi")
        } catch (e: Exception) {
            Log.e(TAG, "Native Ad Factory kaydedilirken hata: ${e.message}")
            e.printStackTrace()
            isNativeAdFactoryRegistered = false
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            // Native Ad Factory'yi temizle
            if (isNativeAdFactoryRegistered) {
                Log.d(TAG, "Native Ad Factory temizleniyor...")
                GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
                isNativeAdFactoryRegistered = false
                Log.d(TAG, "Native Ad Factory başarıyla temizlendi")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Native Ad Factory temizlenirken hata: ${e.message}")
            e.printStackTrace()
        } finally {
            super.cleanUpFlutterEngine(flutterEngine)
        }
    }
    
    override fun onDestroy() {
        try {
            // Ek temizlik işlemleri
            if (isNativeAdFactoryRegistered) {
                Log.d(TAG, "onDestroy: Native Ad Factory temizleniyor...")
                // Flutter engine hala mevcutsa temizle
                flutterEngine?.let { engine ->
                    GoogleMobileAdsPlugin.unregisterNativeAdFactory(engine, "listTile")
                }
                isNativeAdFactoryRegistered = false
                Log.d(TAG, "onDestroy: Native Ad Factory temizlendi")
            }
        } catch (e: Exception) {
            Log.e(TAG, "onDestroy: Native Ad Factory temizlenirken hata: ${e.message}")
            e.printStackTrace()
        } finally {
            super.onDestroy()
        }
    }
} 