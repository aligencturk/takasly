package com.rivorya.takaslyapp

import android.content.Context
import android.os.Build
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    
    private var isNativeAdFactoryRegistered = false
    private val TAG = "MainActivity"
    private val CHANNEL = "takasly/immersive_mode"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method channel'ı ayarla
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableImmersiveMode" -> {
                    enableImmersiveMode()
                    result.success(null)
                }
                "disableImmersiveMode" -> {
                    disableImmersiveMode()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
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
    
    override fun onResume() {
        super.onResume()
        // Immersive mode'u aktif et
        enableImmersiveMode()
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            enableImmersiveMode()
        }
    }
    
    private fun enableImmersiveMode() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                )
            }
            
            // Status bar'ı tamamen gizle
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                window.attributes.layoutInDisplayCutoutMode = 
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
            
            Log.d(TAG, "Immersive mode aktif edildi")
        } catch (e: Exception) {
            Log.e(TAG, "Immersive mode aktif edilemedi: ${e.message}")
        }
    }
    
    private fun disableImmersiveMode() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
            }
            
            // Status bar'ı geri getir
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                window.attributes.layoutInDisplayCutoutMode = 
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT
            }
            
            Log.d(TAG, "Immersive mode deaktif edildi")
        } catch (e: Exception) {
            Log.e(TAG, "Immersive mode deaktif edilemedi: ${e.message}")
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