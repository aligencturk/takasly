import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/logger.dart';
import '../../utils/phone_formatter.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(
      context,
    ).textTheme; // used above in header and footer
    final colorScheme = Theme.of(context).colorScheme;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/auth/2.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // İçerik bölümü (arka plan görseli üzerinden)
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    isKeyboardOpen ? 8 : 24,
                    24,
                    isKeyboardOpen ? 8 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kayıt Formu
                      const Expanded(
                        child: SingleChildScrollView(child: _RegisterForm()),
                      ),

                      // Giriş Yap Butonu
                      Visibility(
                        visible: !isKeyboardOpen,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Zaten hesabın var mı?",
                              style: textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Giriş Yap',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptPolicy = false;
  bool _acceptKvkk = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptPolicy) {
      _showErrorSnackBar('Lütfen kullanım koşullarını kabul edin.');
      return;
    }

    if (!_acceptKvkk) {
      _showErrorSnackBar('Lütfen KVKK metnini kabul edin.');
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    Logger.debug('🚀 Kayıt işlemi başlatılıyor...', tag: 'RegisterView');
    Logger.debug(
      '📧 Email: ${_emailController.text.trim()}',
      tag: 'RegisterView',
    );
    Logger.debug(
      '📱 Telefon: ${_phoneController.text.trim()}',
      tag: 'RegisterView',
    );

    final success = await authViewModel.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: PhoneFormatter.prepareForApi(_phoneController.text.trim()),
      policy: _acceptPolicy,
      kvkk: _acceptKvkk,
    );

    Logger.debug('📊 Kayıt sonucu: $success', tag: 'RegisterView');
    Logger.debug(
      '❌ AuthViewModel error: ${authViewModel.errorMessage}',
      tag: 'RegisterView',
    );
    Logger.debug(
      '👤 Current user: ${authViewModel.currentUser?.name}',
      tag: 'RegisterView',
    );

    if (mounted) {
      if (success) {
        // Kayıt başarılı -> codeToken mutlaka alınmalı, aksi halde yönlendirme yapılmaz
        Logger.debug(
          '✅ Kayıt başarılı, doğrulama kodu gönderilecek ve codeToken alınacak...',
          tag: 'RegisterView',
        );

        Map<String, dynamic>? resendResponse;

        // Her zaman userToken ile resend yap (email ile değil)
        String? tokenForResend = authViewModel.currentUser?.token;
        if (tokenForResend == null || tokenForResend.isEmpty) {
          // ViewModel üzerinden depodaki token'ı al
          tokenForResend = await authViewModel.getStoredUserToken();
        }

        if (tokenForResend == null || tokenForResend.isEmpty) {
          Logger.error(
            '❌ userToken bulunamadı, codeToken alınamadı',
            tag: 'RegisterView',
          );
          _showErrorSnackBar(
            'Kullanıcı token\'ı bulunamadı. Lütfen tekrar giriş yapın.',
          );
          return;
        }

        Logger.debug(
          '🔑 Token ile resend denemesi yapılıyor...',
          tag: 'RegisterView',
        );
        resendResponse = await authViewModel
            .resendEmailVerificationCodeWithToken(userToken: tokenForResend);
        Logger.debug(
          '🔑 Token ile resend response: $resendResponse',
          tag: 'RegisterView',
        );

        // 3) codeToken doğrula
        final String? codeToken =
            resendResponse != null &&
                resendResponse['codeToken'] != null &&
                resendResponse['codeToken'].toString().isNotEmpty
            ? resendResponse['codeToken'].toString()
            : null;

        if (codeToken == null) {
          Logger.error(
            '❌ codeToken alınamadı, yönlendirme iptal edildi',
            tag: 'RegisterView',
          );
          _showErrorSnackBar(
            'Doğrulama kodu gönderilemedi. Lütfen tekrar deneyin.',
          );
          return;
        }

        Logger.debug(
          '✅ codeToken hazır: ${codeToken.substring(0, 10)}...',
          tag: 'RegisterView',
        );

        Navigator.of(context).pushReplacementNamed(
          '/email-verification',
          arguments: {
            'email': _emailController.text.trim(),
            'codeToken': codeToken,
          },
        );
      } else {
        // Hata mesajını daha detaylı göster
        String errorMessage =
            authViewModel.errorMessage ?? 'Kayıt başarısız oldu.';
        Logger.error('❌ Kayıt hatası: $errorMessage', tag: 'RegisterView');

        // Eğer "Bilinmeyen bir hata oluştu" ise daha açıklayıcı mesaj ver
        if (errorMessage == 'Bilinmeyen bir hata oluştu') {
          errorMessage =
              'Kayıt işlemi sırasında bir sorun oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
        }

        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showKvkkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('KVKK Aydınlatma Metni'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bu aydınlatma metni, 6698 sayılı Kişisel Verilerin Korunması Kanunu ("Kanun") kapsamında, Rivorya Yazılım\'nın veri sorumlusu sıfatıyla hareket ettiği hallerde, Kanun\'un 10.maddesine uygun olarak, gerçek kişilere ("Veri Sahibi"), kişisel verilerinin toplanma, işlenme, saklanma, korunma ve imha süreç, şekil ve amaçları ile Kanun uyarınca haklarına ve haklarını kullanma yöntemlerine ilişkin bilgi verilmesi amacıyla hazırlanmıştır.',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  'Detaylı bilgi için aşağıdaki linke tıklayabilirsiniz:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final Uri url = Uri.parse(
                  'https://www.todobus.tr/kvkk-aydinlatma-metni',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Detaylı Görüntüle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ad Soyad
          SizedBox(height: 280),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ad gerekli';
                    }
                    if (value.trim().length < 2) {
                      return 'Ad en az 2 karakter olmalı';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Soyad gerekli';
                    }
                    if (value.trim().length < 2) {
                      return 'Soyad en az 2 karakter olmalı';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // E-posta
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'E-posta gerekli';
              }
              final email = value.trim();
              final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
              if (!emailRegex.hasMatch(email)) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Telefon
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            // Maskeyi kaldırıyoruz; kullanıcı tamamen serbest girsin
            inputFormatters: const [],
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Telefon',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              hintText: '05XXXXXXXXX',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Telefon numarası gerekli';
              }
              if (!PhoneFormatter.isValidPhoneNumber(value)) {
                return 'Geçerli bir telefon numarası girin (0(5XX) XXX XX XX)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Şifre
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Şifre gerekli';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Şifre Tekrar
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Şifre Tekrar',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Şifre tekrarı gerekli';
              if (value != _passwordController.text)
                return 'Şifreler eşleşmiyor';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Kullanım Koşulları ve KVKK
          CheckboxListTile(
            value: _acceptPolicy,
            onChanged: (value) {
              setState(() => _acceptPolicy = value ?? false);
            },
            title: const Text(
              'Kullanım Koşullarını kabul ediyorum',
              style: TextStyle(fontSize: 12),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: colorScheme.primary,
            dense: true,
          ),
          CheckboxListTile(
            value: _acceptKvkk,
            onChanged: (value) {
              setState(() => _acceptKvkk = value ?? false);
            },
            title: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                children: [
                  TextSpan(
                    text: 'KVKK Aydınlatma Metnini',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showKvkkDialog(context),
                  ),
                  const TextSpan(text: ' okudum ve kabul ediyorum'),
                ],
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: colorScheme.primary,
            dense: true,
          ),
          const SizedBox(height: 20),

          // Kayıt Ol Butonu
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, _) {
              return SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: authViewModel.isLoading ? null : _submitRegister,
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  child: authViewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Hesap Oluştur'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
