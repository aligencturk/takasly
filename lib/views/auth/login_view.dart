import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../core/app_theme.dart'; // Yeni temayı import et

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Yeni temadan stilleri al
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Arka plan rengini temadan al
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Takasly',
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kullanmadığın eşyaları takasla, yenile.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),

                const SizedBox(height: 48),

                // E-posta ile Giriş Formu
                const _LoginForm(),

                const SizedBox(height: 24),

                // Ayırıcı
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('veya', style: textTheme.bodyMedium),
                    ),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // Sosyal Medya Butonları
                _buildSocialLoginButton(
                  context,
                  icon: Icons.g_mobiledata_rounded, // Google ikonu
                  label: 'Google ile devam et',
                  onPressed: () => _handleGoogleLogin(context),
                ),
                const SizedBox(height: 16),
                _buildSocialLoginButton(
                  context,
                  icon: Icons.apple_rounded,
                  label: 'Apple ile devam et',
                  onPressed: () => _handleAppleLogin(context),
                ),

                const SizedBox(height: 24),

                // Test Butonları
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Test Hesapları',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleTestLogin(context, 'ali'),
                        icon: const Icon(Icons.person, size: 16),
                        label: const Text('Ali Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade800,
                          elevation: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleTestLogin(context, 'ridvan'),
                        icon: const Icon(Icons.person, size: 16),
                        label: const Text('Rıdvan Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade800,
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Kayıt Ol Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Hesabın yok mu?", style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => _showRegisterScreen(context),
                      child: Text(
                        'Kayıt Ol',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sosyal medya butonları için yardımcı metod
  Widget _buildSocialLoginButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  // Google ile giriş
  void _handleGoogleLogin(BuildContext context) {
    // TODO: Google ile giriş entegrasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google ile giriş özelliği yakında!')),
    );
  }

  // Apple ile giriş
  void _handleAppleLogin(BuildContext context) {
    // TODO: Apple ile giriş entegrasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple ile giriş özelliği yakında!')),
    );
  }

  // Test login
  Future<void> _handleTestLogin(BuildContext context, String testUser) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    String email, password;
    if (testUser == 'ali') {
      email = 'alitalipgencturk@gmail.com';
      password = '151281';
    } else {
      email = 'ridvan.dasdelen@gmail.com';
      password = '123a';
    }

    print('🧪 Test login başlatılıyor: $testUser ($email)');

    final success = await authViewModel.login(email, password);

    if (context.mounted) {
      if (success) {
        print('🧪 Test login başarılı: $testUser');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        print(
          '🧪 Test login başarısız: $testUser - ${authViewModel.errorMessage}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test login başarısız: ${authViewModel.errorMessage ?? 'Bilinmeyen hata'}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Kayıt ekranını göster
  void _showRegisterScreen(BuildContext context) {
    Navigator.of(context).pushNamed('/register');
  }
}

// Giriş formunu ayrı bir widget olarak tanımla
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Giriş başarılıysa ana ekrana yönlendir
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Lütfen geçerli bir e-posta adresi girin.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen şifrenizi girin.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/reset-password');
              },
              child: Text(
                'Şifremi Unuttum',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              return ElevatedButton(
                onPressed: authViewModel.isLoading ? null : _submitLogin,
                child: authViewModel.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Giriş Yap'),
              );
            },
          ),
        ],
      ),
    );
  }
}
