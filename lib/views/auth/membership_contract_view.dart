import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../viewmodels/contract_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';

class MembershipContractView extends StatefulWidget {
  final Function(bool) onContractAccepted;

  const MembershipContractView({Key? key, required this.onContractAccepted})
    : super(key: key);

  @override
  State<MembershipContractView> createState() => _MembershipContractViewState();
}

class _MembershipContractViewState extends State<MembershipContractView> {
  bool _isContractAccepted = false;
  bool _isLoading = true;
  String _contractContent = '';

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  Future<void> _loadContract() async {
    try {
      Logger.info(
        '📋 Üyelik sözleşmesi yükleniyor...',
        tag: 'MembershipContractView',
      );

      final contractViewModel = Provider.of<ContractViewModel>(
        context,
        listen: false,
      );

      final success = await contractViewModel.loadMembershipContract();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            _contractContent = contractViewModel.membershipContractContent;
            Logger.info(
              '✅ Üyelik sözleşmesi başarıyla yüklendi',
              tag: 'MembershipContractView',
            );
          } else {
            Logger.error(
              '❌ Üyelik sözleşmesi yüklenemedi',
              tag: 'MembershipContractView',
            );
            _contractContent =
                'Sözleşme yüklenirken hata oluştu. Lütfen tekrar deneyin.';
          }
        });
      }
    } catch (e) {
      Logger.error(
        '❌ Contract yükleme hatası: $e',
        tag: 'MembershipContractView',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _contractContent =
              'Sözleşme yüklenirken beklenmeyen bir hata oluştu: $e';
        });
      }
    }
  }

  void _onAcceptContract() {
    if (_isContractAccepted) {
      widget.onContractAccepted(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devam etmek için sözleşmeyi kabul etmelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDeclineContract() {
    widget.onContractAccepted(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üyelik Sözleşmesi'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  )
                : _contractContent.isNotEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Html(
                          data: _contractContent,
                          style: {
                            "body": Style(
                              fontSize: FontSize(16),
                              lineHeight: LineHeight(1.6),
                              color: Colors.black87,
                            ),
                          },
                        ),
                        const SizedBox(height: 20),
                        // Checkbox
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isContractAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _isContractAccepted = value ?? false;
                                  });
                                },
                                activeColor: AppTheme.primary,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isContractAccepted =
                                          !_isContractAccepted;
                                    });
                                  },
                                  child: const Text(
                                    'Üyelik sözleşmesini okudum ve kabul ediyorum',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Sözleşme yüklenemedi',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Lütfen tekrar deneyin',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),

          // Accept/Decline buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onDeclineContract,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Reddet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isContractAccepted ? _onAcceptContract : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Kabul Et',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
}
