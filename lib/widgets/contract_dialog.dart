import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../core/app_theme.dart';
import '../utils/logger.dart';

class ContractDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ContractDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Devam etmeden önce lütfen okuyun',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: content.isNotEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Html(
                        data: content,
                        style: {
                          "body": Style(
                            fontSize: FontSize(14),
                            lineHeight: LineHeight(1.5),
                            color: Colors.black87,
                          ),
                          "h1": Style(
                            fontSize: FontSize(18),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            margin: Margins.only(bottom: 16),
                          ),
                          "h2": Style(
                            fontSize: FontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            margin: Margins.only(bottom: 12, top: 20),
                          ),
                          "h3": Style(
                            fontSize: FontSize(15),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            margin: Margins.only(bottom: 10, top: 16),
                          ),
                          "h4": Style(
                            fontSize: FontSize(14),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            margin: Margins.only(bottom: 8, top: 14),
                          ),
                          "p": Style(margin: Margins.only(bottom: 12)),
                          "ul": Style(
                            margin: Margins.only(bottom: 12, left: 20),
                          ),
                          "li": Style(margin: Margins.only(bottom: 6)),
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

            // Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Kapat',
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
                      onPressed: onAccept,
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
                        'Anladım',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
