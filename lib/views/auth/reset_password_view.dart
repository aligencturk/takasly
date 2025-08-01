import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';

class ResetPasswordView extends StatefulWidget {
  final String? email;
  
  const ResetPasswordView({
    super.key,
    this.email,
  });

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Password Visibility States
  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  
  // Token storage
  String? _codeToken;
  String? _passToken;

  // Step management
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step titles
  final List<String> _stepTitles = [
    'E-posta Doğrulama',
    'Kod Girişi',
    'Yeni Şifre',
  ];

  // Step icons
  final List<IconData> _stepIcons = [
    Icons.email_outlined,
    Icons.verified_user_outlined,
    Icons.lock_reset_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _initializeEmailField();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Step Progress Header
          _buildStepProgressHeader(),
          
          // Main Content
          Expanded(
            child: Form(
              key: _formKey,
              child: _buildCurrentStep(),
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // MARK: - AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      title: Text(
          'Şifre Sıfırla',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      centerTitle: true,
    );
  }

  // MARK: - Step Progress Header
  Widget _buildStepProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
                      ),
                    ],
                  ),
      child: Column(
        children: [
          // Step indicator
          Row(
            children: [
              Text(
                'Adım ${_currentStep + 1} / $_totalSteps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _stepTitles[_currentStep],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
          
          const SizedBox(height: 16),
          
          // Step dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = _isStepCompleted(index);
              final isCurrent = index == _currentStep;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    if (index <= _currentStep || (index == _currentStep + 1 && _canGoToNextStep())) {
                      setState(() {
                        _currentStep = index;
                      });
                    }
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green
                          : isCurrent 
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // MARK: - Navigation Buttons
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _currentStep > 0 ? _previousStep : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.primary),
              ),
              child: const Text('Geri'),
            ),
          ),
          const SizedBox(width: 16),
                    Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_canGoToNextStep()) {
                  switch (_currentStep) {
                    case 0: // E-posta adımı
                      _handleResetPassword();
                      break;
                    case 1: // Kod doğrulama adımı
                      _handleCodeVerification();
                      break;
                    case 2: // Şifre güncelleme adımı
                      _handlePasswordUpdate();
                      break;
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _canGoToNextStep() ? AppTheme.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_getButtonText()),
            ),
          ),
                    ],
                  ),
    );
  }

  // MARK: - Step Management
  bool _canGoToNextStep() {
    bool canGo = false;
    switch (_currentStep) {
      case 0: // E-posta Doğrulama
        canGo = _emailController.text.trim().isNotEmpty && 
                RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim());
        break;
      case 1: // Kod Girişi
        canGo = _codeController.text.trim().isNotEmpty && 
                _codeController.text.trim().length >= 4;
        break;
      case 2: // Yeni Şifre
        canGo = _newPasswordController.text.trim().isNotEmpty && 
                _confirmPasswordController.text.trim().isNotEmpty &&
                _newPasswordController.text.trim() == _confirmPasswordController.text.trim() &&
                _newPasswordController.text.trim().length >= AppConstants.minPasswordLength;
        break;
      default:
        canGo = false;
    }
    return canGo;
  }

  void _nextStep() {
    if (_canGoToNextStep() && _currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _isStepCompleted(int step) {
    switch (step) {
      case 0: 
        return _emailController.text.trim().isNotEmpty && 
               RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim());
      case 1: 
        return _codeController.text.trim().isNotEmpty && 
               _codeController.text.trim().length >= 4;
      case 2: 
        return _newPasswordController.text.trim().isNotEmpty && 
               _confirmPasswordController.text.trim().isNotEmpty &&
               _newPasswordController.text.trim() == _confirmPasswordController.text.trim() &&
               _newPasswordController.text.trim().length >= AppConstants.minPasswordLength;
      default: 
        return false;
    }
  }

  // MARK: - Current Step Content
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildCodeStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const Center(child: Text('Bilinmeyen adım'));
    }
  }

  // MARK: - Step Content
  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[0],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      'E-posta Doğrulama',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Şifre sıfırlama kodunu alacağınız e-posta adresini girin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
                     // Form field
                        TextFormField(
                          controller: _emailController,
             decoration: InputDecoration(
               labelText: 'E-posta Adresi',
               hintText: 'E-posta adresinizi girin',
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
               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          keyboardType: TextInputType.emailAddress,
             validator: _validateEmail,
             onChanged: (value) {
               setState(() {}); // Trigger rebuild for button state
             },
           ),
          
          const SizedBox(height: 24),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'E-posta adresinize şifre sıfırlama kodu gönderilecektir',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[1],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doğrulama Kodu',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'E-postanıza gönderilen doğrulama kodunu girin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
                     // Form field
                        TextFormField(
                          controller: _codeController,
             decoration: InputDecoration(
                            labelText: 'Doğrulama Kodu',
               hintText: 'E-postanıza gelen 6 haneli kod',
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
               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          keyboardType: TextInputType.text,
             validator: _validateVerificationCode,
             onChanged: (value) {
               setState(() {}); // Trigger rebuild for button state
             },
           ),
          
          const SizedBox(height: 24),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kod e-postanıza gönderildi. Spam klasörünü kontrol etmeyi unutmayın',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[2],
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yeni Şifre',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Güvenli bir yeni şifre belirleyin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
                     // Form fields
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
             onChanged: (value) {
               setState(() {}); // Trigger rebuild for button state
             },
           ),
          
          const SizedBox(height: 24),
          
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Şifre Tekrar',
                            hintText: 'Şifrenizi tekrar girin',
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
             onChanged: (value) {
               setState(() {}); // Trigger rebuild for button state
                          },
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
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Şifreniz en az ${AppConstants.minPasswordLength} karakter olmalıdır',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Validation Methods
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.fieldRequired;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return ErrorMessages.invalidEmail;
    }
    return null;
  }

  String? _validateVerificationCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.fieldRequired;
    }
    if (value.length < 4) {
      return 'Doğrulama kodu en az 4 karakter olmalıdır';
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

  // MARK: - Helper Methods
  void _initializeEmailField() {
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  void _disposeControllers() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Kod Gönder';
      case 1:
        return 'Kodu Doğrula';
      case 2:
        return 'Şifreyi Güncelle';
      default:
        return 'İleri';
    }
  }

  // MARK: - Business Logic
  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    Logger.debug('Şifre sıfırlama işlemi başlatılıyor...', tag: 'ResetPasswordView');
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.clearError();
    
    // E-posta ile şifre sıfırlama isteği gönder
    final forgotPasswordSuccess = await authViewModel.forgotPassword(
      _emailController.text.trim(),
    );
    
    if (!forgotPasswordSuccess) {
      Logger.error('Şifre sıfırlama isteği başarısız: ${authViewModel.errorMessage}', tag: 'ResetPasswordView');
      return;
    }
    
    Logger.debug('Şifre sıfırlama isteği başarılı, kod gönderildi', tag: 'ResetPasswordView');
    
    // Kullanıcıya kod gönderildiğini bildir
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Şifre sıfırlama kodu e-posta adresinize gönderildi'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadius,
          ),
        ),
      );
      
      // Bir sonraki adıma geç
      _nextStep();
    }
  }

  void _handleCodeVerification() async {
    if (!_formKey.currentState!.validate()) return;
    
    Logger.debug('Kod doğrulama işlemi başlatılıyor...', tag: 'ResetPasswordView');
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.clearError();
    
    // Şifre sıfırlama kodunu doğrula ve passToken al
    final response = await authViewModel.checkPasswordResetCode(
      code: _codeController.text.trim(),
      email: _emailController.text.trim(),
    );
    
    if (response == null) {
      Logger.error('Kod doğrulama hatası: ${authViewModel.errorMessage}', tag: 'ResetPasswordView');
      return;
    }
    
    // PassToken'ı sakla
    if (response.containsKey('passToken')) {
      _passToken = response['passToken'];
      Logger.debug('PassToken alındı: ${_passToken!.substring(0, 10)}...', tag: 'ResetPasswordView');
    } else {
      Logger.error('PassToken bulunamadı', tag: 'ResetPasswordView');
      authViewModel.setError('Doğrulama token\'ı bulunamadı. Lütfen tekrar deneyin.');
      return;
    }
    
    Logger.debug('Kod doğrulama başarılı', tag: 'ResetPasswordView');
    _nextStep();
  }

  void _handlePasswordUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    
    Logger.debug('Şifre güncelleme işlemi başlatılıyor...', tag: 'ResetPasswordView');
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.clearError();
    
    // Saklanan passToken'ı kullan
    if (_passToken == null || _passToken!.isEmpty) {
      Logger.error('PassToken bulunamadı', tag: 'ResetPasswordView');
      authViewModel.setError('Doğrulama token\'ı bulunamadı. Lütfen tekrar deneyin.');
      return;
    }
    
    final success = await authViewModel.updatePassword(
      passToken: _passToken!,
      password: _newPasswordController.text.trim(),
      passwordAgain: _confirmPasswordController.text.trim(),
    );
    
    if (success) {
      Logger.debug('Şifre başarıyla güncellendi', tag: 'ResetPasswordView');
      _handleSuccess();
    } else {
      Logger.error('Şifre güncelleme hatası: ${authViewModel.errorMessage}', tag: 'ResetPasswordView');
    }
  }

  void _handleSuccess() {
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
      
      // Login sayfasına geri dön
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
} 