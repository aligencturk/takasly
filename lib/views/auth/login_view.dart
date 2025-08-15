import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/social_auth_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';
import '../../utils/device_id.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  void initState() {
    super.initState();
    Logger.info('LoginView initialized', tag: 'LoginView');
    // Otomatik giriş kontrolü kaldırıldı - her seferinde login isteniyor
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Transform.translate(
        offset: const Offset(0, 0),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/auth/1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29.0),
              child: Column(
                children: [
                  const Spacer(flex: 24),
                  const _EmailPasswordForm(),
                  const Spacer(flex: 3),
                  const _BottomButtons(),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailPasswordForm extends StatefulWidget {
  const _EmailPasswordForm();

  @override
  State<_EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _BottomButtons extends StatefulWidget {
  const _BottomButtons();

  @override
  State<_BottomButtons> createState() => _BottomButtonsState();
}

class _EmailPasswordFormState extends State<_EmailPasswordForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // E-posta input
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'E-posta',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              labelStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),

        const SizedBox(height: 5),

        // Şifre input
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Şifre',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              labelStyle: const TextStyle(color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 1),

        // Şifremi Unuttum ve Kayıt Ol butonları
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/reset-password');
              },
              child: const Text(
                'Şifremi Unuttum',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              child: const Text(
                'Kayıt Ol',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        ElevatedButton(
          onPressed: () => _submitLogin(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Giriş Yap',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _submitLogin(BuildContext context) async {
    Logger.debug('_submitLogin called', tag: 'LoginView');
    Logger.debug('Email: ${_emailController.text.trim()}', tag: 'LoginView');
    Logger.debug(
      'Password: ${_passwordController.text.trim().isNotEmpty ? "provided" : "empty"}',
      tag: 'LoginView',
    );

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Giriş yapılıyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    Logger.debug('Login result: $success', tag: 'LoginView');
    if (!success) {
      Logger.error(
        'Login failed: ${authViewModel.errorMessage}',
        tag: 'LoginView',
      );
    }

    // Loading dialog'u kapat
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (mounted) {
      if (success) {
        Logger.info('Login successful, navigating to home', tag: 'LoginView');
        if (authViewModel.currentUser != null) {
          Logger.debug(
            'Setting current user: ${authViewModel.currentUser!.name}',
            tag: 'LoginView',
          );
          userViewModel.setCurrentUser(authViewModel.currentUser!);
        }
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Logger.warning('Login failed, showing error message', tag: 'LoginView');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authViewModel.errorMessage ?? 'Giriş başarısız oldu.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _BottomButtonsState extends State<_BottomButtons> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Veya ayırıcı
        Row(
          children: [
            Expanded(
              child: Container(height: 1, color: Colors.white.withOpacity(0.3)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'veya',
                style: TextStyle(color: AppTheme.primary, fontSize: 14),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),

        const SizedBox(height: 26),

        // Google ve Apple ile Giriş
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleGoogleLogin(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/google_icon.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(width: 20, height: 20);
                            },
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Google ile Giriş',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleAppleLogin(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.apple,
                            size: 22,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Apple ile Giriş',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // Google ile giriş
  Future<void> _handleGoogleLogin(BuildContext context) async {
    try {
      Logger.info('Google giriş başlatılıyor', tag: 'LoginView');

      // Loading dialog göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Google ile giriş yapılıyor...'),
                ],
              ),
            ),
          ),
        ),
      );

      final authVm = Provider.of<AuthViewModel>(context, listen: false);

      Logger.info('Google Sign-In başlatılıyor...', tag: 'LoginView');

      final Map<String, String?>? googleTokens = await SocialAuthService
          .instance
          .signInWithGoogleAndGetTokens();

      if (googleTokens == null ||
          googleTokens['accessToken'] == null ||
          googleTokens['idToken'] == null) {
        Logger.warning('Google tokenları alınamadı', tag: 'LoginView');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google oturum açılamadı. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final String googleAccessToken = googleTokens['accessToken']!;
      final String googleIdToken = googleTokens['idToken']!;

      Logger.info('Google tokenları başarıyla alındı', tag: 'LoginView');
      Logger.info(
        'Google tokenları alındı, giriş yapılıyor - Email: ${googleTokens['email']}, Name: ${googleTokens['displayName']}',
        tag: 'LoginView',
      );

      final String deviceID = await DeviceIdHelper.getOrCreateDeviceId();
      final String? fcmToken = await NotificationService.instance.getFCMToken();

      Logger.info(
        'Device ID: $deviceID, FCM Token: ${fcmToken?.substring(0, 20)}...',
        tag: 'LoginView',
      );

      final success = await authVm.loginWithGoogle(
        googleAccessToken: googleAccessToken,
        googleIdToken: googleIdToken,
        deviceID: deviceID,
        fcmToken: fcmToken,
      );

      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      if (success) {
        final userViewModel = Provider.of<UserViewModel>(
          context,
          listen: false,
        );
        if (authVm.currentUser != null) {
          userViewModel.setCurrentUser(authVm.currentUser!);
        }

        Logger.info('Google giriş başarılı', tag: 'LoginView');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Logger.error(
          'Google giriş başarısız: ${authVm.errorMessage}',
          tag: 'LoginView',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authVm.errorMessage ?? 'Google ile giriş başarısız oldu.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e, s) {
      Logger.error('Google giriş hatası: $e', stackTrace: s, tag: 'LoginView');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen hata: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Apple ile giriş
  Future<void> _handleAppleLogin(BuildContext context) async {
    try {
      Logger.info('Apple giriş başlatılıyor', tag: 'LoginView');

      // Loading dialog göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Apple ile giriş yapılıyor...'),
                ],
              ),
            ),
          ),
        ),
      );

      final authVm = Provider.of<AuthViewModel>(context, listen: false);

      Logger.info('Apple Sign-In başlatılıyor...', tag: 'LoginView');

      final Map<String, String?>? appleTokens = await SocialAuthService.instance
          .signInWithAppleAndGetTokens(); // DÜZELTİLDİ: Apple servisi çağrılıyor

      if (appleTokens == null || appleTokens['idToken'] == null) {
        Logger.warning('Apple idToken alınamadı', tag: 'LoginView');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apple oturumu açılamadı. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final String appleIdToken = appleTokens['idToken']!;

      Logger.info('Apple tokenları başarıyla alındı', tag: 'LoginView');
      Logger.info(
        'Apple tokenları alındı, giriş yapılıyor - Email: ${appleTokens['email']}, Name: ${appleTokens['displayName']}',
        tag: 'LoginView',
      );

      final String deviceID = await DeviceIdHelper.getOrCreateDeviceId();
      final String? fcmToken = await NotificationService.instance.getFCMToken();

      Logger.info(
        'Device ID: $deviceID, FCM Token: ${fcmToken?.substring(0, 20)}...',
        tag: 'LoginView',
      );

      final success = await authVm.loginWithApple(
        appleIdToken: appleIdToken,
        deviceID: deviceID,
        fcmToken: fcmToken,
      );

      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      if (success) {
        final userViewModel = Provider.of<UserViewModel>(
          context,
          listen: false,
        );
        if (authVm.currentUser != null) {
          userViewModel.setCurrentUser(authVm.currentUser!);
        }

        Logger.info('Apple giriş başarılı', tag: 'LoginView');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Logger.error(
          'Apple giriş başarısız: ${authVm.errorMessage}',
          tag: 'LoginView',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authVm.errorMessage ?? 'Apple ile giriş başarısız oldu.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e, s) {
      Logger.error('Apple giriş hatası: $e', stackTrace: s, tag: 'LoginView');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen hata: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
