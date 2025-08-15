import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';

class EmailVerificationView extends StatefulWidget {
  final String email;
  final String codeToken;

  const EmailVerificationView({
    super.key,
    required this.email,
    required this.codeToken,
  });

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late String _currentCodeToken;

  @override
  void initState() {
    super.initState();
    _currentCodeToken = widget.codeToken;

    // Otomatik resend kaldırıldı; kullanıcı manuel tetikleyecek
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'E-posta Doğrulama',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // MARK: - Header Section
              _buildHeaderSection(),

              const SizedBox(height: 40),

              // MARK: - Form Section
              _buildFormSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Header Section
  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Icon Container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 40,
            color: AppTheme.primary,
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          'E-posta Doğrulama',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Email Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle
        Text(
          'E-posta adresinize gönderilen 6 haneli doğrulama kodunu girin',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // MARK: - Form Section
  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MARK: - Verification Code Field
            _buildVerificationCodeField(),

            const SizedBox(height: 24),

            // MARK: - Submit Button
            _buildSubmitButton(),

            const SizedBox(height: 16),

            // MARK: - Resend Code Button
            _buildResendCodeButton(),

            const SizedBox(height: 16),

            // MARK: - Skip Verification Option
            _buildSkipSection(),
          ],
        ),
      ),
    );
  }

  // MARK: - Verification Code Field
  Widget _buildVerificationCodeField() {
    return TextFormField(
      controller: _codeController,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Doğrulama Kodu',
        hintText: '6 haneli kodu girin',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Doğrulama kodu gerekli';
        }
        if (value.length < 6) {
          return 'Doğrulama kodu 6 haneli olmalıdır';
        }
        return null;
      },
    );
  }

  // MARK: - Submit Button
  Widget _buildSubmitButton() {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Column(
          children: [
            // Error Message
            if (authViewModel.hasError) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authViewModel.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: authViewModel.isLoading
                    ? null
                    : () => _handleEmailVerification(authViewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: authViewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Doğrula',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // MARK: - Resend Code Button
  Widget _buildResendCodeButton() {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return TextButton(
          onPressed: authViewModel.isLoading
              ? null
              : () => _resendVerificationCode(),
          child: Text(
            'Kodu Tekrar Gönder',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  // MARK: - Skip Section
  Widget _buildSkipSection() {
    return Column(
      children: [
        TextButton(
          onPressed: () => _showSkipVerificationDialog(),
          child: const Text(
            'Bu adımı atla',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // MARK: - Business Logic
  void _handleEmailVerification(AuthViewModel authViewModel) async {
    if (!_formKey.currentState!.validate()) return;

    Logger.debug(
      'E-posta doğrulama başlatılıyor...',
      tag: 'EmailVerificationView',
    );

    authViewModel.clearError();

    final success = await authViewModel.checkEmailVerificationCode(
      code: _codeController.text.trim(),
      codeToken: _currentCodeToken,
    );

    if (mounted) {
      if (success) {
        Logger.debug(
          'E-posta doğrulama başarılı',
          tag: 'EmailVerificationView',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta adresiniz başarıyla doğrulandı'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Login sayfasına geri dön
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Logger.error(
          'E-posta doğrulama başarısız: ${authViewModel.errorMessage}',
          tag: 'EmailVerificationView',
        );
      }
    }
  }

  void _showSkipVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Doğrulamayı Atlama',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'E-posta adresinizi henüz doğrulamadan devam etmek üzeresiniz.',
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                '• Hesabınız bazı kullanıcılar tarafından doğrulanmamış olarak görünebilir.',
              ),
              SizedBox(height: 6),
              Text(
                '• Dilediğiniz zaman ayarlar bölümünden e-posta doğrulamasını tamamlayabilirsiniz.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Devam Et'),
            ),
          ],
        );
      },
    );
  }

  void _resendVerificationCode() async {
    Logger.debug(
      'Doğrulama kodu tekrar gönderiliyor...',
      tag: 'EmailVerificationView',
    );

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    authViewModel.clearError();

    // User token'ı al
    final userToken = authViewModel.currentUser?.token;
    if (userToken == null || userToken.isEmpty) {
      Logger.error('User token bulunamadı', tag: 'EmailVerificationView');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kullanıcı bilgileri bulunamadı. Lütfen tekrar giriş yapın.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final response = await authViewModel.resendEmailVerificationCodeWithToken(
      userToken: userToken,
    );

    if (mounted) {
      if (response != null) {
        Logger.debug(
          'Doğrulama kodu tekrar gönderildi',
          tag: 'EmailVerificationView',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğrulama kodu e-posta adresinize gönderildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Yeni codeToken varsa güncelle
        if (response.containsKey('codeToken') &&
            response['codeToken'] != null) {
          final newCodeToken = response['codeToken'].toString();
          setState(() {
            _currentCodeToken = newCodeToken;
          });
          Logger.debug(
            'Yeni codeToken alındı ve güncellendi: ${newCodeToken.substring(0, 10)}...',
            tag: 'EmailVerificationView',
          );
        }
      } else {
        Logger.error(
          'Doğrulama kodu gönderilemedi: ${authViewModel.errorMessage}',
          tag: 'EmailVerificationView',
        );

        // 417 hatası veya diğer hatalar için kullanıcıya bilgi ver
        String errorMessage = authViewModel.errorMessage ?? 'Kod gönderilemedi';

        // 417 hatası için özel mesaj
        if (errorMessage.contains('Zorunlu değerler boş gönderilemez')) {
          errorMessage =
              'E-posta adresi geçersiz. Lütfen profil sayfanızdan e-posta adresinizi kontrol edin.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
