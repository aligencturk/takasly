import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordObscure = true;
  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Şifre Değiştir',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Şifre Güvenliği',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hesabınızın güvenliği için güçlü bir şifre belirleyin',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Mevcut Şifre
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  hintText: 'Mevcut şifrenizi girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordObscure = !_isCurrentPasswordObscure;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                obscureText: _isCurrentPasswordObscure,
                validator: _validateCurrentPassword,
              ),

              const SizedBox(height: 16),

              // Yeni Şifre
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  hintText: 'Yeni şifrenizi belirleyin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordObscure = !_isNewPasswordObscure;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                obscureText: _isNewPasswordObscure,
                validator: _validateNewPassword,
              ),

              const SizedBox(height: 16),

              // Şifre Tekrar
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar',
                  hintText: 'Yeni şifrenizi tekrar girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                obscureText: _isConfirmPasswordObscure,
                validator: _validateConfirmPassword,
              ),

              const SizedBox(height: 24),

              // Error Message
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  if (authViewModel.hasError) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authViewModel.errorMessage!,
                              style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Şifreniz en az ${AppConstants.minPasswordLength} karakter olmalıdır. Güvenlik için büyük/küçük harf, rakam ve özel karakter kullanmanızı öneririz.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    return ElevatedButton(
                      onPressed: authViewModel.isLoading ? null : _handlePasswordChange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: authViewModel.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Şifreyi Güncelle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Validation Methods
  String? _validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.fieldRequired;
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.fieldRequired;
    }
    if (value.length < AppConstants.minPasswordLength) {
      return ErrorMessages.weakPassword;
    }
    if (value == _currentPasswordController.text) {
      return 'Yeni şifre mevcut şifre ile aynı olamaz';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.fieldRequired;
    }
    if (value != _newPasswordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  // Business Logic
  Future<void> _handlePasswordChange() async {
    Logger.info('🔄 ChangePasswordView._handlePasswordChange() başlatılıyor...', tag: 'ChangePasswordView');

    if (!_formKey.currentState!.validate()) {
      Logger.warning('❌ Form validation başarısız', tag: 'ChangePasswordView');
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    Logger.debug('🔍 Şifre değiştirme parametreleri:', tag: 'ChangePasswordView');
    Logger.debug('🔑 Mevcut şifre: ${currentPassword.length} karakter', tag: 'ChangePasswordView');
    Logger.debug('🔑 Yeni şifre: ${newPassword.length} karakter', tag: 'ChangePasswordView');
    Logger.debug('🔑 Şifre tekrar: ${confirmPassword.length} karakter', tag: 'ChangePasswordView');

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.clearError();

    try {
      // Direkt şifre değiştirme (e-posta doğrulaması olmadan)
      Logger.debug('📤 Direkt şifre değiştirme işlemi başlatılıyor...', tag: 'ChangePasswordView');
      
      final updateSuccess = await authViewModel.updateUserPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordAgain: confirmPassword,
      );

      if (updateSuccess) {
        Logger.info('✅ Şifre başarıyla güncellendi', tag: 'ChangePasswordView');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(SuccessMessages.passwordUpdateSuccess),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadius,
              ),
            ),
          );

          // Sayfayı kapat
          Navigator.of(context).pop();
        }
      } else {
        Logger.error('❌ Şifre güncelleme hatası: ${authViewModel.errorMessage}', tag: 'ChangePasswordView');
      }

    } catch (e) {
      Logger.error('💥 Şifre değiştirme işleminde exception: $e', tag: 'ChangePasswordView', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Şifre değiştirme işleminde bir hata oluştu'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadius,
          ),
        ),
      );
    }
  }
} 