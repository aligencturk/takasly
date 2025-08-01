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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/auth/1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 20), // Üst kısım için çok daha fazla esnek boşluk
                
                // E-posta ve Şifre alanları ile Kayıt Ol/Şifremi Unuttum seçenekleri
                const _EmailPasswordForm(),

                const Spacer(flex: 2), // Orta boşluk
                
                // Alt kısımdaki butonlar
                const _BottomButtons(),
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
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

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
        // Login başarılı olduktan sonra UserViewModel'i de güncelle
        if (authViewModel.currentUser != null) {
          userViewModel.setCurrentUser(authViewModel.currentUser!);
        }
        
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

// E-posta ve şifre formunu ayrı bir widget olarak tanımla
class _EmailPasswordForm extends StatefulWidget {
  const _EmailPasswordForm();

  @override
  State<_EmailPasswordForm> createState() => _EmailPasswordFormState();
}

// Alt kısımdaki butonları ayrı bir widget olarak tanımla
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
        const SizedBox(height: 380), // Üst boşluk
        
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
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'E-posta',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              labelStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 12), // E-posta ve şifre arası boşluk artırıldı
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
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Şifre',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
        const SizedBox(height: 1), // Şifre ve butonlar arası boşluk azaltıldı
        
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
                  color: Colors.white,
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
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24), // Butonlar ve giriş butonu arası boşluk
 
        ElevatedButton(
          onPressed: () => _submitLogin(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Giriş Yap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitLogin(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    final success = await authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        if (authViewModel.currentUser != null) {
          userViewModel.setCurrentUser(authViewModel.currentUser!);
        }
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
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'veya',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
        // Google ve Apple ile Giriş - Tek satır
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => _handleGoogleLogin(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide.none,
                  ),
                  icon: const Icon(Icons.g_mobiledata, size: 18),
                  label: const Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => _handleAppleLogin(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide.none,
                  ),
                  icon: const Icon(Icons.apple, size: 18),
                  label: const Text(
                    'Apple',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Test butonları (geliştirme için)
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleTestLogin(context, 'ali'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Test Ali', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleTestLogin(context, 'ridvan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Test Ridvan', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Google ile giriş
  void _handleGoogleLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google ile giriş özelliği yakında!')),
    );
  }

  // Apple ile giriş
  void _handleAppleLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple ile giriş özelliği yakında!')),
    );
  }

  // Test login
  Future<void> _handleTestLogin(BuildContext context, String testUser) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

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
        if (authViewModel.currentUser != null) {
          userViewModel.setCurrentUser(authViewModel.currentUser!);
        }
        
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
}


