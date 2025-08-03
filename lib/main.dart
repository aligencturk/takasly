import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/trade_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/user_profile_detail_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'views/splash_view.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/email_verification_view.dart';
import 'views/auth/reset_password_view.dart';
import 'views/home/home_view.dart';
import 'views/trade/trade_view.dart';
import 'views/profile/profile_view.dart';
import 'views/chat/chat_list_view.dart';
import 'views/location_test_view.dart';
import 'views/product/add_product_view.dart';
import 'core/constants.dart';
import 'core/app_theme.dart';
import 'utils/logger.dart';
import 'services/cache_service.dart';
import 'services/error_handler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Logger.info('🚀 Takasly App Starting...');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  Logger.info('✅ Firebase initialized successfully');
  
  // Cache service'i initialize et
  await CacheService().initialize();
  Logger.info('✅ Cache service initialized successfully');
  
  // Cache stats'ı logla
  await CacheService().logCacheStats();
  
  runApp(const TakaslyApp());
}

class TakaslyApp extends StatelessWidget {
  const TakaslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.info('🏗️ Building TakaslyApp...');
    
    return MultiProvider(
      providers: [
        // UserViewModel'i önce oluştur (diğer ViewModel'ler buna bağımlı olabilir)
        ChangeNotifierProvider(create: (context) => UserViewModel()),
        ChangeNotifierProvider(create: (context) => ProductViewModel()),
        ChangeNotifierProvider(
          create: (context) {
            Logger.info('🔧 Creating AuthViewModel...');
            final authViewModel = AuthViewModel();
            final productViewModel = context.read<ProductViewModel>();
            authViewModel.setProductViewModel(productViewModel);
            Logger.info('✅ AuthViewModel created and configured');
            return authViewModel;
          },
        ),
        ChangeNotifierProvider(create: (context) => TradeViewModel()),
        ChangeNotifierProvider(create: (context) => ChatViewModel()),
        ChangeNotifierProvider(create: (context) => UserProfileDetailViewModel()),
        ChangeNotifierProvider(create: (context) => ReportViewModel()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: ErrorHandlerService.navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => SplashVideoPage(),
          '/login': (context) => const LoginView(),
          '/register': (context) => const RegisterView(),
          '/home': (context) => const HomeView(),
          '/profile': (context) => const ProfileView(),
          '/trade': (context) => const TradeView(),
          '/reset-password': (context) => const ResetPasswordView(),
          '/chats': (context) => const ChatListView(),
          '/location-test': (context) => const LocationTestView(),
          '/add-product': (context) => const AddProductView(),
        },
        onGenerateRoute: (settings) {
          Logger.info('🛣️ Generating route for: ${settings.name}');
          switch (settings.name) {
            case '/email-verification':
              final args = settings.arguments as Map<String, String>;
              final email = args['email'] ?? '';
              final codeToken = args['codeToken'] ?? '';
              return MaterialPageRoute(
                builder: (context) => EmailVerificationView(
                  email: email,
                  codeToken: codeToken,
                ),
              );
            default:
              Logger.warning('⚠️ Unknown route: ${settings.name}, redirecting to home');
              return MaterialPageRoute(builder: (context) => const HomeView());
          }
        },
      ),
    );
  }
}
