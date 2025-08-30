import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
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
import 'viewmodels/general_viewmodel.dart';
import 'viewmodels/contract_viewmodel.dart';
import 'viewmodels/remote_config_viewmodel.dart';
import 'viewmodels/onboarding_viewmodel.dart';
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
import 'models/product.dart';
import 'utils/logger.dart';
import 'services/profanity_service.dart';
import 'services/notification_service.dart';

/// FCM Background Message Handler
/// Bu fonksiyon uygulama background veya terminate durumundayken
/// gelen FCM mesajlarını işler

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Burada ağır iş yapmayın. Genelde log/analitik yeterli olur.
}

/// Bildirim tıklamasını işler
/// Android için notification channel oluşturur
Future<void> _createNotificationChannel() async {
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android için notification channel oluştur
      // Bu işlem Android manifest'te tanımlanan channel ID ile uyumlu olmalı
    }
  } catch (e) {
    Logger.error('Notification channel oluşturma hatası: $e');
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

    // FCM Background Message Handler'ı sadece desteklenen platformlarda ayarla (Android/iOS)
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
          // iOS için optimize edilmiş başlatma
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
            try {
              await messaging.setAutoInitEnabled(true);
            } catch (e) {
              Logger.warning('iOS FCM auto-init hatası: $e');
            }
          }

          // FCM token'ı al
          String? token = await messaging.getToken();

          // Foreground message listener'ı başlat
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            if (message.notification != null) {
              // Foreground notification handling
            }

            if (message.data.isNotEmpty) {
              // Data message handling
            }
          });

          // Android için notification channel oluştur
          if (defaultTargetPlatform == TargetPlatform.android) {
            await _createNotificationChannel();
          }
        } else {
          Logger.warning(
            'FCM izinleri reddedildi: ${settings.authorizationStatus}',
          );
        }

        // ProfanityService'i başlat
        try {
          await ProfanityService.instance.initialize();
        } catch (e) {
          Logger.error('ProfanityService başlatma hatası: $e');
        }

        // NotificationService'i başlat
        try {
          await NotificationService.instance.init();
        } catch (e) {
          Logger.error('NotificationService başlatma hatası: $e');
        }
      } catch (e) {
        Logger.error('FCM başlatılırken hata: $e');
      }
    }
  } catch (e) {
    Logger.error('Firebase başlatılırken hata: $e');
  }

  // Cache servisini başlat
  try {
    await CacheService().initialize();
  } catch (e) {
    Logger.error('Cache servisi başlatılırken hata: $e');
  }

  // AdMob'u başlat (WidgetsFlutterBinding.ensureInitialized() sonrası)
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    Logger.error('AdMob başlatılırken hata: $e');
    // AdMob başlatılamasa bile uygulama çalışmaya devam etsin
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
              try {
                adViewModel.initializeAdMob();
              } catch (e) {
                Logger.error('AdMob başlatma hatası: $e');
              }
            });
            return adViewModel;
          },
        ),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileDetailViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => GeneralViewModel()),
        ChangeNotifierProvider(create: (_) => ContractViewModel()),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(
          create: (context) {
            final remoteConfigViewModel = RemoteConfigViewModel();
            // Remote Config'i güvenli bir şekilde başlat
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                remoteConfigViewModel.initialize();
              } catch (e) {
                Logger.error('Remote Config başlatma hatası: $e');
              }
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
              try {
                // Context'in mounted olduğundan emin ol
                if (!context.mounted) {
                  Logger.warning(
                    'Context is not mounted, skipping provider setup',
                  );
                  return;
                }

                final authViewModel = Provider.of<AuthViewModel>(
                  context,
                  listen: false,
                );
                final notificationViewModel =
                    Provider.of<NotificationViewModel>(context, listen: false);
                authViewModel.setNotificationViewModel(notificationViewModel);
                // Uygulama açılışında iOS/Android fark etmeksizin FCM'i başlatmayı dene
                // Kullanıcı login ise, topic aboneliği ve izin akışı kurulacak
                // Login değilse, izinler ve token yine alınır; login sonrası topic'e abone olunur
                if (!notificationViewModel.fcmInitialized) {
                  notificationViewModel.initializeFCM();
                }
              } catch (e) {
                Logger.error('Provider bağlantı hatası: $e');
              }
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
              final product = args?['product'] as Product?;
              final productId = args?['productId'] as String?;

              if (product != null) {
                // Doğrudan Product objesi ile
                return MaterialPageRoute(
                  builder: (context) => EditProductView(product: product),
                );
              } else if (productId != null && productId.isNotEmpty) {
                // ProductId ile - product detayını yükle ve EditProductView'a geç
                return MaterialPageRoute(
                  builder: (context) => _ProductDetailLoader(
                    productId: productId,
                    onProductLoaded: (loadedProduct) =>
                        EditProductView(product: loadedProduct),
                  ),
                );
              } else {
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Hata')),
                    body: Center(child: Text('Ürün bilgisi bulunamadı')),
                  ),
                );
              }

            case '/product-detail':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) =>
                    ProductDetailView(productId: args?['productId'] ?? ''),
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
                builder: (context) =>
                    TradeDetailView(offerID: args?['offerID'] ?? 0),
              );

            case '/start-trade':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) =>
                    StartTradeView(receiverProduct: args?['receiverProduct']),
              );

            case '/chat-detail':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => ChatDetailView(chat: args?['chat']),
              );

            default:
              return MaterialPageRoute(builder: (context) => const HomeView());
          }
        },
        onUnknownRoute: (settings) {
          Logger.warning('Bilinmeyen route: ${settings.name}');
          return MaterialPageRoute(builder: (context) => const HomeView());
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
                  bodyColor: Theme.of(
                    context,
                  ).primaryTextTheme.bodyLarge?.color,
                  displayColor: Theme.of(
                    context,
                  ).primaryTextTheme.displayLarge?.color,
                ),
              ),
              child: DefaultTextStyle(
                style: DefaultTextStyle.of(context).style.copyWith(
                  fontWeight:
                      FontWeight.w400, // Varsayılan font weight'i normalize et
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

// ProductId ile product detayını yükleyip EditProductView'a yönlendiren widget
class _ProductDetailLoader extends StatefulWidget {
  final String productId;
  final Widget Function(Product) onProductLoaded;

  const _ProductDetailLoader({
    required this.productId,
    required this.onProductLoaded,
  });

  @override
  State<_ProductDetailLoader> createState() => _ProductDetailLoaderState();
}

class _ProductDetailLoaderState extends State<_ProductDetailLoader> {
  @override
  void initState() {
    super.initState();
    // Build tamamlandıktan sonra product'ı yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  Future<void> _loadProduct() async {
    try {
      final productViewModel = context.read<ProductViewModel>();
      final product = await productViewModel.getProductDetail(widget.productId);

      if (product != null && mounted) {
        // Product yüklendi, EditProductView'a yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => widget.onProductLoaded(product),
          ),
        );
      } else if (mounted) {
        // Product bulunamadı, hata sayfası göster
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('Hata')),
              body: Center(child: Text('Ürün bulunamadı')),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('Hata')),
              body: Center(child: Text('Ürün yüklenirken hata oluştu: $e')),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yükleniyor...')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ürün detayları yükleniyor...'),
          ],
        ),
      ),
    );
  }
}
