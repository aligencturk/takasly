import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/report_viewmodel.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../utils/logger.dart';

class ReportDialog extends StatefulWidget {
  final int reportedUserID;
  final String reportedUserName;
  final int? productID;
  final int? offerID;

  const ReportDialog({
    Key? key,
    required this.reportedUserID,
    required this.reportedUserName,
    this.productID,
    this.offerID,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  bool _isCustomReason = false;

  final List<String> _predefinedReasons = [
    'Uygunsuz davranış sergiledi',
    'Sahte ürün sattı',
    'İletişim kurmuyor',
    'Takas teklifini kabul etmiyor',
    'Kötü niyetli davranış',
    'Spam mesaj gönderiyor',
    'Diğer',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onReasonChanged(String? reason) {
    setState(() {
      _selectedReason = reason;
      _isCustomReason = reason == 'Diğer';
      if (!_isCustomReason) {
        _reasonController.text = reason ?? '';
      } else {
        _reasonController.clear();
      }
    });
  }

  Future<void> _submitReport() async {
    final reason = _isCustomReason ? _reasonController.text.trim() : _selectedReason;
    
    if (reason == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen şikayet sebebini belirtin'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final reportViewModel = context.read<ReportViewModel>();
      
      // SharedPreferences'dan token al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString(AppConstants.userTokenKey);
      
      if (userToken == null || userToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Oturum bilgisi bulunamadı'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final success = await reportViewModel.reportUser(
        userToken: userToken,
        reportedUserID: widget.reportedUserID,
        reason: reason,
        productID: widget.productID,
        offerID: widget.offerID,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Şikayetiniz başarıyla gönderildi'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reportViewModel.errorMessage),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('ReportDialog: Şikayet gönderme hatası - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Beklenmeyen bir hata oluştu'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.defaultBorderRadius),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.error,
                          AppTheme.error.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.error.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.report_problem_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kullanıcı Şikayet Et',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          widget.reportedUserName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Şikayet sebebi seçimi
                    Text(
                      'Şikayet Sebebi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Önceden tanımlı sebepler - Grid layout
                    if (!_isCustomReason) ...[
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _predefinedReasons.length,
                          itemBuilder: (context, index) {
                            final reason = _predefinedReasons[index];
                            final isSelected = _selectedReason == reason;
                            
                            return GestureDetector(
                              onTap: () => _onReasonChanged(reason),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppTheme.primary.withValues(alpha: 0.1)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppTheme.primary
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: reason,
                                      groupValue: _selectedReason,
                                      onChanged: _onReasonChanged,
                                      activeColor: AppTheme.primary,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: isSelected 
                                              ? AppTheme.primary
                                              : AppTheme.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Özel sebep girişi
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _reasonController,
                            maxLines: null,
                            expands: true,
                            maxLength: 200,
                            decoration: InputDecoration(
                              hintText: 'Şikayet sebebinizi yazın...',
                              hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                              counterText: '',
                            ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'İptal',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Consumer<ReportViewModel>(
                            builder: (context, reportViewModel, child) {
                              return ElevatedButton(
                                onPressed: reportViewModel.isLoading ? null : _submitReport,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: reportViewModel.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.report_problem_outlined,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Şikayet Et',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 