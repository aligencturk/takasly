import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../viewmodels/contract_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';

class KvkkContractView extends StatefulWidget {
  final Function(bool) onContractAccepted;

  const KvkkContractView({Key? key, required this.onContractAccepted})
    : super(key: key);

  @override
  State<KvkkContractView> createState() => _KvkkContractViewState();
}

class _KvkkContractViewState extends State<KvkkContractView> {
  bool _isLoading = true;
  String _contractContent = '';

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  Future<void> _loadContract() async {
    try {
      Logger.info('🔒 KVKK metni yükleniyor...', tag: 'KvkkContractView');

      final contractViewModel = Provider.of<ContractViewModel>(
        context,
        listen: false,
      );

      final success = await contractViewModel.loadKvkkContract();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            _contractContent = contractViewModel.kvkkContractContent;
            Logger.info(
              '✅ KVKK metni başarıyla yüklendi',
              tag: 'KvkkContractView',
            );
          } else {
            Logger.error('❌ KVKK metni yüklenemedi', tag: 'KvkkContractView');
            _contractContent =
                'KVKK metni yüklenirken hata oluştu. Lütfen tekrar deneyin.';
          }
        });
      }
    } catch (e) {
      Logger.error('❌ KVKK yükleme hatası: $e', tag: 'KvkkContractView');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _contractContent =
              'KVKK metni yüklenirken beklenmeyen bir hata oluştu: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KVKK Aydınlatma Metni'),
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
                          'KVKK metni yüklenemedi',
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
