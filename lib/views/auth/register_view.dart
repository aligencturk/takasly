import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
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

    // Önce kayıt işlemini dene (sözleşmeler olmadan)
    final success = await authViewModel.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: PhoneFormatter.prepareForApi(_phoneController.text.trim()),
      policy: false, // Geçici olarak false
      kvkk: false, // Geçici olarak false
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
        // Kayıt başarılı, şimdi sözleşmeleri göster
        Logger.debug(
          '✅ Kayıt başarılı, sözleşmeler gösteriliyor...',
          tag: 'RegisterView',
        );

        // Sözleşmeleri göster
        final membershipAccepted = await _showMembershipDialog();

        // Eğer sözleşmeler kabul edildiyse email verification'a git
        if (membershipAccepted == true) {
          Logger.debug(
            '✅ Sözleşmeler kabul edildi, email verification sayfasına yönlendiriliyor...',
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
          // Sözleşmeler reddedildi, kullanıcıyı bilgilendir
          Logger.debug(
            '❌ Sözleşmeler reddedildi, kayıt iptal ediliyor...',
            tag: 'RegisterView',
          );

          _showErrorSnackBar(
            'Kayıt işlemi için sözleşmeler kabul edilmelidir.',
          );
        }
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
    try {
      Logger.info(
        '📋 Üyelik sözleşmesi dialog\'u açılıyor...',
        tag: 'RegisterView',
      );

      // Loading state göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Sözleşme yükleniyor...'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MembershipContractView(
            onContractAccepted: (accepted) {
              Logger.info(
                '📋 Üyelik sözleşmesi sonucu: $accepted',
                tag: 'RegisterView',
              );
              Navigator.of(context).pop(accepted);
            },
          ),
        ),
      );

      Logger.info(
        '📋 Üyelik sözleşmesi dialog sonucu: $result',
        tag: 'RegisterView',
      );

      if (result == true) {
        // Üyelik sözleşmesi kabul edildi, KVKK'ya geç
        Logger.info(
          '✅ Üyelik sözleşmesi kabul edildi, KVKK dialog\'u açılıyor...',
          tag: 'RegisterView',
        );
        await _showKvkkDialog();
        return true;
      } else {
        // Üyelik sözleşmesi reddedildi
        Logger.info('❌ Üyelik sözleşmesi reddedildi', tag: 'RegisterView');
        return false;
      }
    } catch (e) {
      Logger.error(
        '❌ Üyelik sözleşmesi dialog hatası: $e',
        tag: 'RegisterView',
      );
      _showErrorSnackBar('Sözleşme açılırken hata oluştu: $e');
      return false;
    }
  }

  // Sadece görüntüleme amaçlı sözleşme dialog'u
  Future<void> _showMembershipDialogForViewing() async {
    try {
      Logger.info(
        '📋 Üyelik sözleşmesi görüntüleme dialog\'u açılıyor...',
        tag: 'RegisterView',
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MembershipContractView(
            onContractAccepted: (accepted) {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } catch (e) {
      Logger.error(
        '❌ Üyelik sözleşmesi görüntüleme dialog hatası: $e',
        tag: 'RegisterView',
      );
      _showErrorSnackBar('Sözleşme açılırken hata oluştu: $e');
    }
  }

  Future<void> _showKvkkDialog() async {
    try {
      Logger.info('🔒 KVKK dialog\'u açılıyor...', tag: 'RegisterView');

      // Loading state göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('KVKK metni yükleniyor...'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => KvkkContractView(
            onContractAccepted: (accepted) {
              Logger.info('🔒 KVKK sonucu: $accepted', tag: 'RegisterView');
              Navigator.of(context).pop(accepted);
            },
          ),
        ),
      );

      Logger.info('🔒 KVKK dialog sonucu: $result', tag: 'RegisterView');

      if (result == true) {
        // KVKK kabul edildi
        Logger.info(
          '✅ KVKK aydınlatma metni kabul edildi',
          tag: 'RegisterView',
        );

        // Başarı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Sözleşmeler kabul edildi!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // KVKK reddedildi
        Logger.info('❌ KVKK aydınlatma metni reddedildi', tag: 'RegisterView');
      }
    } catch (e) {
      Logger.error('❌ KVKK dialog hatası: $e', tag: 'RegisterView');
      _showErrorSnackBar('KVKK metni açılırken hata oluştu: $e');
    }
  }

  // Sadece görüntüleme amaçlı KVKK dialog'u
  Future<void> _showKvkkDialogForViewing() async {
    try {
      Logger.info(
        '🔒 KVKK görüntüleme dialog\'u açılıyor...',
        tag: 'RegisterView',
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => KvkkContractView(
            onContractAccepted: (accepted) {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } catch (e) {
      Logger.error('❌ KVKK görüntüleme dialog hatası: $e', tag: 'RegisterView');
      _showErrorSnackBar('KVKK metni açılırken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ad Soyad - klavye açıldığında daha az üst boşluk
          SizedBox(height: isKeyboardOpen ? 120 : 280),
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
                      onTap: () => _showMembershipDialogForViewing(),
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
                      onTap: () => _showKvkkDialogForViewing(),
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

          // Klavye açıldığında alt boşluk ekle
          if (isKeyboardOpen) SizedBox(height: 20),
        ],
      ),
    );
  }
}
