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
              backgroundColor: Colors.green,
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.report_problem_rounded,
                    color: AppTheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kullanıcı Şikayet Et',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Şikayet sebebini belirtin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Kullanıcı bilgisi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.reportedUserName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Şikayet sebebi seçimi
            const Text(
              'Şikayet Sebebi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Önceden tanımlı sebepler
            if (!_isCustomReason) ...[
              ...List.generate(_predefinedReasons.length, (index) {
                final reason = _predefinedReasons[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: _onReasonChanged,
                    title: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppTheme.primary,
                  ),
                );
              }),
            ] else ...[
              // Özel sebep girişi
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Şikayet sebebinizi yazın...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<ReportViewModel>(
                    builder: (context, reportViewModel, child) {
                      return ElevatedButton(
                        onPressed: reportViewModel.isLoading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: reportViewModel.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Şikayet Et',
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
          ],
        ),
      ),
    );
  }
} 