import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../viewmodels/contract_viewmodel.dart';
import '../../core/app_theme.dart';
import '../../widgets/loading_widget.dart';
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
          }
        });
      }
    } catch (e) {
      Logger.error(
        'Contract yükleme hatası: $e',
        tag: 'MembershipContractView',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onAcceptContract() {
    if (_isContractAccepted) {
      widget.onContractAccepted(true);
      Navigator.of(context).pop();
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
    Navigator.of(context).pop();
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
                ? const Center(child: LoadingWidget())
                : _contractContent.isNotEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Html(
                      data: _contractContent,
                      style: {
                        "body": Style(
                          fontSize: FontSize(16),
                          lineHeight: LineHeight(1.6),
                          color: Colors.black87,
                        ),
                        "h1": Style(
                          fontSize: FontSize(20),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          margin: Margins.only(bottom: 20),
                        ),
                        "h2": Style(
                          fontSize: FontSize(18),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          margin: Margins.only(bottom: 16, top: 24),
                        ),
                        "h3": Style(
                          fontSize: FontSize(16),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          margin: Margins.only(bottom: 14, top: 20),
                        ),
                        "h4": Style(
                          fontSize: FontSize(15),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          margin: Margins.only(bottom: 12, top: 18),
                        ),
                        "p": Style(margin: Margins.only(bottom: 16)),
                        "ul": Style(margin: Margins.only(bottom: 16, left: 24)),
                        "li": Style(margin: Margins.only(bottom: 8)),
                        "strong": Style(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        "a": Style(
                          color: AppTheme.primary,
                          textDecoration: TextDecoration.underline,
                        ),
                      },
                    ),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Sözleşme içeriği yüklenemedi',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
          ),

          // Checkbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
                        _isContractAccepted = !_isContractAccepted;
                      });
                    },
                    child: const Text(
                      'Üyelik sözleşmesini okudum ve kabul ediyorum',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onDeclineContract,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reddet',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onAcceptContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kabul Et',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
