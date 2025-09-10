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
        ],
      ),
    );
  }
}
