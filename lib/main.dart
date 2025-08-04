import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/error_handler_service.dart';
import 'services/admob_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/trade_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/ad_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'viewmodels/user_profile_detail_viewmodel.dart';
import 'views/splash_view.dart';
import 'utils/logger.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Performans optimizasyonları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Ekran yönlendirmesini sabitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

      // Firebase'i başlat
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      Logger.info('✅ Firebase başarıyla başlatıldı');
    } catch (e) {
      Logger.error('❌ Firebase başlatılırken hata: $e');
    }

  // AdMob'u başlat (arka planda)
  try {
    await MobileAds.instance.initialize();
    Logger.info('✅ AdMob başarıyla başlatıldı');
  } catch (e) {
    Logger.error('❌ AdMob başlatılırken hata: $e');
  }

  // Cache servisini başlat
  try {
    await CacheService().initialize();
    Logger.info('✅ Cache servisi başarıyla başlatıldı');
  } catch (e) {
    Logger.error('❌ Cache servisi başlatılırken hata: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => TradeViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => AdViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileDetailViewModel()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
                 home: SplashVideoPage(),
        builder: (context, child) {
          // Performans optimizasyonları
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // Text scaling'i devre dışı bırak
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
