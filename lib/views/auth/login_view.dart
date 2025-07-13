import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../core/constants.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Koyu mavi/gri arka plan
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Logo
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Yeşil logo arka planı
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'logo',
                      style: TextStyle(
                    color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // İllüstrasyon görseli
                Container(
                  width: 280,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/login.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.swap_horiz,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Başlık metni
                const Text(
                  'Kullanmadığın Eşyaları\nTakaslayarak Yenile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Hadi Takaslayalım! butonu
                Container(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      _showLoginOptions(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Yeşil buton
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Hadi Takaslayalım!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // "veya" metni
                const Text(
                  'veya',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Google ile devam et butonu
                Container(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      _handleGoogleLogin(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151), // Koyu gri buton
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Google ile devam et',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Apple ile devam et butonu
                Container(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      _handleAppleLogin(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151), // Koyu gri buton
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.apple,
                    color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Apple ile devam et',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Kullanım koşulları metni
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: 'Devam ederek '),
                        TextSpan(
                          text: 'Kullanım Koşulları',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' ve '),
                        TextSpan(
                          text: 'Gizlilik Politikası',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '\'nı kabul ediyorsunuz'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Giriş Yap',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Burada mevcut login formu gösterilebilir
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Ana login formuna yönlendir
                _navigateToEmailLogin(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'E-posta ile Giriş Yap',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Kayıt ol sayfasına yönlendir
                _navigateToEmailRegister(context);
              },
              child: const Text('Hesabın yok mu? Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleLogin(BuildContext context) {
    // Google login implementasyonu buraya gelecek
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google ile giriş yakında aktif olacak'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleAppleLogin(BuildContext context) {
    // Apple login implementasyonu buraya gelecek
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple ile giriş yakında aktif olacak'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _navigateToEmailLogin(BuildContext context) {
    // E-posta ile giriş formuna yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailLoginView(),
      ),
    );
  }

  void _navigateToEmailRegister(BuildContext context) {
    // E-posta ile kayıt formuna yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailRegisterView(),
      ),
    );
  }
}

// E-posta ile giriş formu için ayrı widget
class EmailLoginView extends StatefulWidget {
  const EmailLoginView({super.key});

  @override
  State<EmailLoginView> createState() => _EmailLoginViewState();
}

class _EmailLoginViewState extends State<EmailLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Koyu tema
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Giriş Yap',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
              const SizedBox(height: 40),
              
              // Başlık
              const Text(
                'Tekrar Hoşgeldin!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Hesabına giriş yaparak takas yapmaya başla',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // E-posta alanı
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'E-posta adresiniz',
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta gereklidir';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Şifre alanı
              TextFormField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  hintText: 'Şifreniz',
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                                onPressed: () {
                                  setState(() {
                        _isObscure = !_isObscure;
                                  });
                                },
                  ),
                ),
                obscureText: _isObscure,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Şifre gereklidir';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              
              // Şifremi unuttum linki
              Align(
                alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                    // Şifremi unuttum sayfasına yönlendir
                  },
                  child: const Text(
                    'Şifremi Unuttum',
                    style: TextStyle(color: Color(0xFF10B981)),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Giriş butonu
              Consumer<AuthViewModel>(
                builder: (context, auth, child) {
                  return Container(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : () async {
                        print('🔐 Login button pressed');
                        try {
                          if (_formKey.currentState!.validate()) {
                            print('🔐 Form validated, attempting login...');
                            final success = await auth.login(
                              _emailController.text,
                              _passwordController.text,
                            );
                            
                            print('🔐 Login result: $success');
                            if (success) {
                              print('🔐 Login successful, setting user data...');
                              // Login başarılı - UserViewModel'a da kullanıcı bilgisini aktar
                              try {
                                final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                                if (auth.currentUser != null) {
                                  print('🔐 Setting current user: ${auth.currentUser!.email}');
                                  userViewModel.setCurrentUser(auth.currentUser!);
                                }
                                
                                print('🔐 Navigating to home...');
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/home',
                                  (route) => false,
                                );
                                print('🔐 Navigation completed');
                              } catch (e, stackTrace) {
                                print('❌ Error during user setup or navigation: $e');
                                print('❌ Stack trace: $stackTrace');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Navigasyon hatası: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              print('🔐 Login failed: ${auth.errorMessage}');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(auth.errorMessage ?? 'Giriş başarısız'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e, stackTrace) {
                          print('❌ Critical error during login: $e');
                          print('❌ Stack trace: $stackTrace');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kritik hata: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Kayıt ol linki
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmailRegisterView(),
                    ),
                  );
                },
                child: const Text(
                  'Hesabın yok mu? Kayıt Ol',
                  style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
          ),
        ),
      ),
    );
  }
}

// E-posta ile kayıt formu için ayrı widget
class EmailRegisterView extends StatefulWidget {
  const EmailRegisterView({super.key});

  @override
  State<EmailRegisterView> createState() => _EmailRegisterViewState();
}

class _EmailRegisterViewState extends State<EmailRegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isObscure = true;
  bool _policyAccepted = false;
  bool _kvkkAccepted = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Koyu tema
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Kayıt Ol',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Başlık
              const Text(
                'Hesap Oluştur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Takasly ailesine katılın ve değişim yapmaya başlayın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Ad alanı
                          TextFormField(
                            controller: _firstNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                              labelText: 'Ad',
                              hintText: 'Ad',
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                    return 'Ad gereklidir';
                              }
                              return null;
                            },
                          ),
              
                          const SizedBox(height: 16),
                          
              // Soyad alanı
                          TextFormField(
                            controller: _lastNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                              labelText: 'Soyad',
                              hintText: 'Soyad',
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                    return 'Soyad gereklidir';
                              }
                              return null;
                            },
                          ),
              
                          const SizedBox(height: 16),
                          
              // Telefon alanı
                          TextFormField(
                            controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                              labelText: 'Telefon',
                              hintText: '0555 123 45 67',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                    return 'Telefon gereklidir';
                              }
                              return null;
                            },
                          ),
              
                          const SizedBox(height: 16),
                        
              // E-posta alanı
                        TextFormField(
                          controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                            labelText: 'E-posta',
                            hintText: 'E-posta adresiniz',
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                    return 'E-posta gereklidir';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Geçerli bir e-posta adresi girin';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
              // Şifre alanı
                        TextFormField(
                          controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            hintText: 'Şifreniz',
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                            ),
                          ),
                          obscureText: _isObscure,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                    return 'Şifre gereklidir';
                            }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                        
              const SizedBox(height: 24),
              
              // Checkbox'lar
              CheckboxListTile(
                                value: _policyAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _policyAccepted = value ?? false;
                                  });
                                },
                title: const Text(
                  'Gizlilik Politikasını kabul ediyorum',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF10B981);
                  }
                  return Colors.transparent;
                }),
              ),
              
              CheckboxListTile(
                                value: _kvkkAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _kvkkAccepted = value ?? false;
                                  });
                                },
                title: const Text(
                  'KVKK metnini kabul ediyorum',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF10B981);
                  }
                  return Colors.transparent;
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Kayıt ol butonu
              Consumer<AuthViewModel>(
                builder: (context, auth, child) {
                  return Container(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          if (!_policyAccepted || !_kvkkAccepted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lütfen gerekli onayları verin'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          final success = await auth.register(
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                            password: _passwordController.text,
                            phone: _phoneController.text,
                            policy: _policyAccepted,
                            kvkk: _kvkkAccepted,
                          );
                          
                          if (success) {
                            // Kayıt başarılı - UserViewModel'a da kullanıcı bilgisini aktar
                            final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                            if (auth.currentUser != null) {
                              userViewModel.setCurrentUser(auth.currentUser!);
                            }
                            
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/home',
                              (route) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(auth.errorMessage ?? 'Kayıt başarısız'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Kayıt Ol',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Giriş yap linki
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmailLoginView(),
                    ),
                  );
                },
                child: const Text(
                  'Zaten hesabın var mı? Giriş Yap',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 