import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants.dart';

class EmailVerificationView extends StatefulWidget {
  final String email;
  
  const EmailVerificationView({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'E-posta Doğrulama',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Email Verification Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 50,
                    color: Color(0xFF2196F3),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'E-posta Doğrulama',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Email Display
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                const Text(
                  'E-posta adresinize gönderilen doğrulama kodunu girin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Form Container
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Verification Code Field
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Doğrulama Kodu',
                            hintText: 'E-postanıza gelen kodu girin',
                            prefixIcon: Icon(Icons.verified_user_outlined),
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
                              return ErrorMessages.fieldRequired;
                            }
                            if (value.length < 4) {
                              return 'Doğrulama kodu en az 4 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        Consumer<AuthViewModel>(
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
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
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
                                ElevatedButton(
                                  onPressed: authViewModel.isLoading 
                                      ? null 
                                      : () => _handleEmailVerification(authViewModel),
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
                                      : const Text('Doğrula'),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Resend Code Button
                                TextButton(
                                  onPressed: authViewModel.isLoading 
                                      ? null 
                                      : () => _resendVerificationCode(),
                                  child: const Text(
                                    'Kodu Tekrar Gönder',
                                    style: TextStyle(
                                      color: Color(0xFF2196F3),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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

  void _handleEmailVerification(AuthViewModel authViewModel) async {
    if (!_formKey.currentState!.validate()) return;
    
    authViewModel.clearError();
    
    final success = await authViewModel.checkEmailVerificationCode(
      email: widget.email,
      code: _codeController.text.trim(),
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(SuccessMessages.emailVerificationSuccess),
          backgroundColor: Colors.green,
        ),
      );
      
      // Login sayfasına geri dön
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _resendVerificationCode() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    authViewModel.clearError();
    
    final success = await authViewModel.resendEmailVerificationCode(
      email: widget.email,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(SuccessMessages.verificationCodeResent),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? 'Kod gönderilemedi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 