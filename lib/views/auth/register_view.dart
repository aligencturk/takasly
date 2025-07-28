import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/app_theme.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
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
            image: AssetImage('assets/auth/2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 140),
                  // Kayıt Formu
                  const _RegisterForm(),

                  const SizedBox(height: 16),

                  // Giriş Yap Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Zaten hesabın var mı?", style: textTheme.bodyMedium),
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
                ],
              ),
            ),
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
    final success = await authViewModel.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      policy: _acceptPolicy,
      kvkk: _acceptKvkk,
    );

    if (mounted) {
      if (success) {
        // Kayıt başarılıysa email doğrulama ekranına yönlendir
        Navigator.of(context).pushReplacementNamed(
          '/email-verification',
          arguments: _emailController.text.trim(),
        );
      } else {
        _showErrorSnackBar(
          authViewModel.errorMessage ?? 'Kayıt başarısız oldu.',
        );
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ad Soyad
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          const SizedBox(height: 8),

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
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value.trim())) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Telefon
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Telefon',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              hintText: '05XX XXX XX XX',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Telefon numarası gerekli';
              }
              // Türkiye telefon numarası formatı kontrolü
              final phoneRegex = RegExp(r'^(05)([0-9]{9})$');
              final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
              if (!phoneRegex.hasMatch(cleanPhone)) {
                return 'Geçerli bir telefon numarası girin (05XXXXXXXXX)';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

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
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

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
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre tekrarı gerekli';
              }
              if (value != _passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Kullanım Koşulları ve KVKK
          CheckboxListTile(
            value: _acceptPolicy,
            onChanged: (value) {
              setState(() {
                _acceptPolicy = value ?? false;
              });
            },
            title: Text(
              'Kullanım Koşullarını kabul ediyorum',
              style: const TextStyle(fontSize: 12),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: colorScheme.primary,
            dense: true,
          ),
          CheckboxListTile(
            value: _acceptKvkk,
            onChanged: (value) {
              setState(() {
                _acceptKvkk = value ?? false;
              });
            },
            title: Text(
              'KVKK Aydınlatma Metnini okudum ve kabul ediyorum',
              style: const TextStyle(fontSize: 12),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: colorScheme.primary,
            dense: true,
          ),
          const SizedBox(height: 16),

          // Kayıt Ol Butonu
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
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
