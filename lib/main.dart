import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'services/cache_service.dart';
import 'services/error_handler_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/trade_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/ad_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'viewmodels/user_profile_detail_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'viewmodels/remote_config_viewmodel.dart';
import 'views/splash_view.dart';
import 'views/home/home_view.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/reset_password_view.dart';
import 'views/auth/email_verification_view.dart';
import 'views/product/add_product_view.dart';
import 'views/product/edit_product_view.dart';
import 'views/product/product_detail_view.dart';
import 'views/profile/profile_view.dart';
import 'views/profile/edit_profile_view.dart';
import 'views/profile/settings_view.dart';
import 'views/profile/change_password_view.dart';
import 'views/profile/user_profile_detail_view.dart';
import 'views/trade/trade_view.dart';
import 'views/trade/trade_detail_view.dart';
import 'views/trade/start_trade_view.dart';
import 'views/chat/chat_list_view.dart';
import 'views/chat/chat_detail_view.dart';
import 'views/notifications/notification_list_view.dart';
import 'utils/logger.dart';

/// FCM Background Message Handler
/// Bu fonksiyon uygulama background veya terminate durumundayken
/// gelen FCM mesajlarını işler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Logger.debug('FCM Background Message: ${message.notification?.title}', tag: 'FCM_BG');
  
  // Background'da gelen mesajları işle
  if (message.notification != null) {
    Logger.debug('Background notification: ${message.notification!.title} - ${message.notification!.body}', tag: 'FCM_BG');
  }
  
  if (message.data.isNotEmpty) {
    Logger.debug('Background data: ${message.data}', tag: 'FCM_BG');
  }
}

/// Android için notification channel oluşturur
Future<void> _createNotificationChannel() async {
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android için notification channel oluştur
      // Bu işlem Android manifest'te tanımlanan channel ID ile uyumlu olmalı
      Logger.info('✅ Android notification channel manifest\'te tanımlı');
    }
  } catch (e) {
    Logger.error('❌ Notification channel oluşturma hatası: $e');
  }
}

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
    
    // FCM Background Message Handler'ı sadece desteklenen platformlarda ayarla (Android/iOS)
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS)) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      Logger.info('✅ FCM Background Handler ayarlandı');
      
      // FCM'i başlat
      try {
        final messaging = FirebaseMessaging.instance;
        
        // Notification permissions'ları iste
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          Logger.info('✅ FCM izinleri verildi');
          
          // iOS: APNS token hazır değilse FCM token alamayız. Kısa bekleme/retry yapalım
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
            try {
              // iOS simülatör için sandbox mod ayarla
              await messaging.setAutoInitEnabled(true);
              
              const int maxAttempts = 15; // ~7.5sn (artırdık)
              String? apnsToken;
              for (int attempt = 1; attempt <= maxAttempts; attempt++) {
                apnsToken = await messaging.getAPNSToken();
                if (apnsToken != null && apnsToken.isNotEmpty) {
                  Logger.info('✅ APNS Token hazır: ${apnsToken.substring(0, 12)}...');
                  break;
                }
                Logger.info('⏳ APNS token bekleniyor... ($attempt/$maxAttempts)');
                await Future.delayed(const Duration(milliseconds: 500));
              }
              if (apnsToken == null || apnsToken.isEmpty) {
                Logger.warning('⚠️ APNS token halen hazır değil; FCM token gecikebilir');
                // iOS simülatörde bazen APNS token gelmez, yine de FCM token almayı dene
                Logger.info('🔄 iOS simülatör: APNS token olmadan FCM token deneniyor...');
              }
            } catch (e) {
              Logger.warning('⚠️ APNS token beklerken uyarı: $e');
            }
          }

          // FCM token'ı al
          String? token = await messaging.getToken();
          if (token != null) {
            Logger.info('✅ FCM Token alındı: $token');
          }
          
          // Foreground message listener'ı başlat
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            Logger.info('🔔 Foreground FCM Message alındı: ${message.notification?.title}');
            
            if (message.notification != null) {
              Logger.info('📱 Notification: ${message.notification!.title} - ${message.notification!.body}');
            }
            
            if (message.data.isNotEmpty) {
              Logger.info('📊 Data: ${message.data}');
            }
          });
          
          // Background'dan açılan mesajları dinle
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            Logger.info('🔄 Background FCM Message ile uygulama açıldı: ${message.notification?.title}');
            
            if (message.notification != null) {
              Logger.info('📱 Background Notification: ${message.notification!.title} - ${message.notification!.body}');
            }
            
            if (message.data.isNotEmpty) {
              Logger.info('📊 Background Data: ${message.data}');
            }
          });
          
          // Android için notification channel oluştur
          if (defaultTargetPlatform == TargetPlatform.android) {
            await _createNotificationChannel();
          }
          
          Logger.info('✅ FCM başarıyla başlatıldı');
        } else {
          Logger.warning('⚠️ FCM izinleri reddedildi: ${settings.authorizationStatus}');
        }
      } catch (e) {
        Logger.error('❌ FCM başlatılırken hata: $e');
      }
    } else {
      Logger.info('ℹ️ FCM Background Handler bu platformda desteklenmiyor');
    }
  } catch (e) {
    Logger.error('❌ Firebase başlatılırken hata: $e');
  }

  // Cache servisini başlat
  try {
    await CacheService().initialize();
    Logger.info('✅ Cache servisi başarıyla başlatıldı');
  } catch (e) {
    Logger.error('❌ Cache servisi başlatılırken hata: $e');
  }

  // AdMob'u başlat (WidgetsFlutterBinding.ensureInitialized() sonrası)
  try {
    Logger.info('🚀 AdMob başlatılıyor...');
    await MobileAds.instance.initialize();
    Logger.info('✅ AdMob başarıyla başlatıldı');
  } catch (e) {
    Logger.error('❌ AdMob başlatılırken hata: $e');
    // AdMob başlatılamasa bile uygulama çalışmaya devam etsin
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
        ChangeNotifierProvider(
          create: (context) {
            final adViewModel = AdViewModel();
            // AdMob'u güvenli bir şekilde başlat
            WidgetsBinding.instance.addPostFrameCallback((_) {
              adViewModel.initializeAdMob();
            });
            return adViewModel;
          },
        ),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileDetailViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(
          create: (context) {
            final remoteConfigViewModel = RemoteConfigViewModel();
            // Remote Config'i güvenli bir şekilde başlat
            WidgetsBinding.instance.addPostFrameCallback((_) {
              remoteConfigViewModel.initialize();
            });
            return remoteConfigViewModel;
          },
        ),
      ],
             child: MaterialApp(
         title: AppConstants.appName,
         debugShowCheckedModeBanner: false,
         theme: AppTheme.lightTheme,
         navigatorKey: ErrorHandlerService.navigatorKey, // Navigator key ekle
         home: Builder(
           builder: (context) {
             // ViewModel'ler arasında bağlantı kur
             WidgetsBinding.instance.addPostFrameCallback((_) {
               final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
               final notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false);
               authViewModel.setNotificationViewModel(notificationViewModel);
             });
             return SplashVideoPage();
           },
         ),
                   routes: {
            '/home': (context) => const HomeView(),
            '/login': (context) => const LoginView(),
            '/register': (context) => const RegisterView(),
            '/reset-password': (context) => const ResetPasswordView(),
            '/profile': (context) => const ProfileView(),
            '/edit-profile': (context) => const EditProfileView(),
            '/settings': (context) => const SettingsView(),
            '/change-password': (context) => const ChangePasswordView(),
            '/trade': (context) => const TradeView(),
            '/chat-list': (context) => const ChatListView(),
            '/notifications': (context) => const NotificationListView(),
          },
          onGenerateRoute: (settings) {
            Logger.info('🔄 Route oluşturuluyor: ${settings.name}');
            
            switch (settings.name) {
              case '/email-verification':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => EmailVerificationView(
                    email: args?['email'] ?? '',
                    codeToken: args?['codeToken'] ?? '',
                  ),
                );
                
              case '/add-product':
                return MaterialPageRoute(
                  builder: (context) => const AddProductView(),
                );
                
              case '/edit-product':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => EditProductView(
                    product: args?['product'],
                  ),
                );
                
              case '/product-detail':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => ProductDetailView(
                    productId: args?['productId'] ?? '',
                  ),
                );
                
              case '/user-profile-detail':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => UserProfileDetailView(
                    userId: args?['userId'] ?? '',
                    userToken: args?['userToken'] ?? '',
                  ),
                );
                
              case '/trade-detail':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => TradeDetailView(
                    offerID: args?['offerID'] ?? 0,
                  ),
                );
                
              case '/start-trade':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => StartTradeView(
                    receiverProduct: args?['receiverProduct'],
                  ),
                );
                
              case '/chat-detail':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => ChatDetailView(
                    chat: args?['chat'],
                  ),
                );
                
              default:
                return MaterialPageRoute(
                  builder: (context) => const HomeView(),
                );
            }
          },
         onUnknownRoute: (settings) {
           Logger.warning('🚨 Bilinmeyen route: ${settings.name}');
           return MaterialPageRoute(
             builder: (context) => const HomeView(),
           );
         },
         builder: (context, child) {
           // Kalın metin ve text scaling kontrolü
           return MediaQuery(
             data: MediaQuery.of(context).copyWith(
               textScaleFactor: 1.0, // Text scaling'i devre dışı bırak
               boldText: false, // Kalın metin ayarını devre dışı bırak
               // Font weight kontrolü
               platformBrightness: MediaQuery.of(context).platformBrightness,
             ),
             child: Theme(
               data: Theme.of(context).copyWith(
                 // Font weight'leri normalize et
                 textTheme: Theme.of(context).textTheme.apply(
                   bodyColor: Theme.of(context).textTheme.bodyLarge?.color,
                   displayColor: Theme.of(context).textTheme.displayLarge?.color,
                 ),
                 // Tüm text stillerini normalize et
                 primaryTextTheme: Theme.of(context).primaryTextTheme.apply(
                   bodyColor: Theme.of(context).primaryTextTheme.bodyLarge?.color,
                   displayColor: Theme.of(context).primaryTextTheme.displayLarge?.color,
                 ),
               ),
               child: DefaultTextStyle(
                 style: DefaultTextStyle.of(context).style.copyWith(
                   fontWeight: FontWeight.w400, // Varsayılan font weight'i normalize et
                 ),
                 child: child!,
               ),
             ),
           );
         },
       ),
    );
  }
}
