import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../core/app_theme.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Transform.translate(
        offset: Offset(0, -MediaQuery.of(context).viewInsets.bottom * 0.5),
        child: Container(
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
                  const Spacer(flex: 26),
                  const _EmailPasswordForm(),
                  const Spacer(flex: 3),
                  const _BottomButtons(),
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
        const SizedBox(height: 100),
        
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
        
        const SizedBox(height: 12),
        
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
        
        const SizedBox(height: 24),
        
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
        
        const SizedBox(height: 16),
        
        // Google ve Apple ile Giriş
        Row(
          children: [
            Expanded(
              child: SizedBox(
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
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
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
        
        const SizedBox(height: 16),
        
        // Test butonları (geliştirme için)
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