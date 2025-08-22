import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/contract_viewmodel.dart';
import 'membership_contract_view.dart';
import 'kvkk_contract_view.dart';
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

    // Önce üyelik sözleşmesi göster
    final membershipAccepted = await _showMembershipDialog();

    // Eğer üyelik sözleşmesi reddedildiyse işlemi durdur
    if (membershipAccepted != true) {
      _showErrorSnackBar(
        'Kayıt işlemi için üyelik sözleşmesi kabul edilmelidir.',
      );
      return;
    }

    // KVKK metni zaten _showMembershipDialog içinde gösterildi
    // Burada sadece kayıt işlemini başlat

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
      policy: true, // Üyelik sözleşmesi kabul edildi
      kvkk: true, // KVKK kabul edildi
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

        // Kayıt başarılı, doğrudan email verification sayfasına yönlendir
        Logger.debug(
          '✅ Kayıt başarılı, email verification sayfasına yönlendiriliyor...',
          tag: 'RegisterView',
        );

        // Email verification sayfasına yönlendir
        Navigator.of(context).pushReplacementNamed(
          '/email-verification',
          arguments: {
            'email': _emailController.text.trim(),
            'codeToken':
                null, // codeToken email verification sayfasında alınacak
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

  Future<bool?> _showMembershipDialog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MembershipContractView(
          onContractAccepted: (accepted) {
            Navigator.of(context).pop(accepted);
          },
        ),
      ),
    );

    if (result == true) {
      // Üyelik sözleşmesi kabul edildi, KVKK'ya geç
      _showKvkkDialog();
      return true;
    } else {
      // Üyelik sözleşmesi reddedildi
      Logger.info('❌ Üyelik sözleşmesi reddedildi', tag: 'RegisterView');
      return false;
    }
  }

  void _showKvkkDialog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => KvkkContractView(
          onContractAccepted: (accepted) {
            Navigator.of(context).pop(accepted);
          },
        ),
      ),
    );

    if (result == true) {
      // KVKK kabul edildi
      Logger.info('✅ KVKK aydınlatma metni kabul edildi', tag: 'RegisterView');
    } else {
      // KVKK reddedildi
      Logger.info('❌ KVKK aydınlatma metni reddedildi', tag: 'RegisterView');
    }
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

          // Sözleşme Link'leri
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              children: [
                Text(
                  'Kayıt olarak aşağıdaki sözleşmeleri kabul etmiş sayılırsınız:',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showMembershipDialog,
                      child: Text(
                        'Üyelik Sözleşmesi',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      ' ve ',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: _showKvkkDialog,
                      child: Text(
                        'KVKK Aydınlatma Metni',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

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
