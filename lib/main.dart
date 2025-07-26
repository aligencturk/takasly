import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/trade_viewmodel.dart';
import 'views/splash_view.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/email_verification_view.dart';
import 'views/auth/reset_password_view.dart';
import 'views/home/home_view.dart';
import 'views/product/product_detail_view.dart';
import 'views/trade/trade_view.dart';
import 'views/profile/profile_view.dart';
import 'core/constants.dart';
import 'core/app_theme.dart'; // Yeni temayı import et

void main() {
  runApp(const TakaslyApp());
}

class TakaslyApp extends StatelessWidget {
  const TakaslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductViewModel()),
        ChangeNotifierProvider(
          create: (context) {
            final authViewModel = AuthViewModel();
            final productViewModel = context.read<ProductViewModel>();
            authViewModel.setProductViewModel(productViewModel);
            return authViewModel;
          },
        ),
        ChangeNotifierProvider(create: (context) => UserViewModel()),
        ChangeNotifierProvider(create: (context) => TradeViewModel()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // Yeni temayı uygula
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashView(),
          '/login': (context) => const LoginView(),
          '/register': (context) => const RegisterView(),
          '/home': (context) => const HomeView(),
          '/profile': (context) => const ProfileView(),
          '/trade': (context) => const TradeView(),
          '/reset-password': (context) => const ResetPasswordView(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/product-detail':
              final productId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => ProductDetailView(productId: productId),
              );
            case '/email-verification':
              final email = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => EmailVerificationView(email: email),
              );
            default:
              return MaterialPageRoute(builder: (context) => const HomeView());
          }
        },
      ),
    );
  }
}
