import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profanity_check_result.dart';
import '../services/profanity_service.dart';
import '../utils/logger.dart';
import '../core/app_theme.dart';

class ProfanityCheckChatInput extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onSendPressed;
  final bool enabled;
  final bool readOnly;
  final String sensitivity; // 'low', 'medium', 'high'
  final bool showProfanityWarning;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final TextCapitalization? textCapitalization;

  const ProfanityCheckChatInput({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onSendPressed,
    this.enabled = true,
    this.readOnly = false,
    this.sensitivity = 'medium',
    this.showProfanityWarning = true,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.textCapitalization,
  });

  @override
  State<ProfanityCheckChatInput> createState() =>
      _ProfanityCheckChatInputState();
}

class _ProfanityCheckChatInputState extends State<ProfanityCheckChatInput> {
  ProfanityCheckResult? _lastCheckResult;
  bool _isChecking = false;
  Timer? _debounceTimer;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeProfanityService();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeProfanityService() async {
    try {
      await ProfanityService.instance.initialize();
      Logger.info('✅ ProfanityCheckChatInput - ProfanityService başlatıldı');
    } catch (e) {
      Logger.error(
        '❌ ProfanityCheckChatInput - ProfanityService başlatılamadı: $e',
      );
    }
  }

  void _onTextChanged(String value) {
    // Debounce ile küfür kontrolü yap
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _checkProfanity(value);
    });

    // Hata durumunu temizle
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }

    // Parent callback'i çağır
    widget.onChanged?.call(value);
  }

  Future<void> _checkProfanity(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _lastCheckResult = null;
        _hasError = false;
      });
      return;
    }

    if (!ProfanityService.instance.isInitialized) {
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      final result = ProfanityService.instance.checkText(
        text,
        sensitivity: widget.sensitivity,
      );

      if (mounted) {
        setState(() {
          _lastCheckResult = result;
          _isChecking = false;
          _hasError = result.hasProfanity;
        });

        if (result.hasProfanity) {
          Logger.info(
            '🚫 ProfanityCheckChatInput - Uygunsuz içerik tespit edildi: ${result.detectedWord}',
          );
        }
      }
    } catch (e) {
      Logger.error('❌ ProfanityCheckChatInput - Küfür kontrolü hatası: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _handleSend() {
    if (_hasError) {
      _showProfanityErrorDialog();
      return;
    }

    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      // Son bir küfür kontrolü daha yap
      if (ProfanityService.instance.isInitialized) {
        final result = ProfanityService.instance.checkText(
          text,
          sensitivity: widget.sensitivity,
        );

        if (result.hasProfanity) {
          // Küfür tespit edildi, state'i güncelle ve uyarı göster
          setState(() {
            _lastCheckResult = result;
            _hasError = true;
          });
          _showProfanityErrorDialog();
          return;
        }
      }

      // Küfür yoksa mesajı gönder
      widget.onSendPressed?.call();
    }
  }

  void _showProfanityErrorDialog() {
    final result = _lastCheckResult!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getWarningIcon(result.level),
              color: _getWarningColor(),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Uygunsuz İçerik'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message ?? 'Uygunsuz içerik tespit edildi'),
            if (result.detectedWord != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tespit edilen: "${result.detectedWord}"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Lütfen mesajınızı düzenleyip tekrar deneyin.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hasError ? Colors.red.shade400 : Colors.grey.shade300,
              width: _hasError ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Prefix icon
              if (widget.prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: widget.prefixIcon!,
                ),
                const SizedBox(width: 8),
              ],

              // Text input
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _handleSend(),
                  textCapitalization:
                      widget.textCapitalization ?? TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Mesajınızı yazın...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        widget.contentPadding ??
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              // Suffix icon (checking indicator or error)
              if (_isChecking || _hasError) ...[
                const SizedBox(width: 8),
                _buildStatusIcon(),
                const SizedBox(width: 8),
              ],

              // Send button
              Container(
                margin: const EdgeInsets.only(right: 4),
                child: IconButton(
                  onPressed: _handleSend,
                  icon: Icon(
                    Icons.send_rounded,
                    color: _hasError ? Colors.grey.shade400 : AppTheme.primary,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _hasError
                        ? Colors.grey.shade100
                        : AppTheme.primary.withOpacity(0.1),
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Küfür uyarısı
        if (widget.showProfanityWarning &&
            _lastCheckResult?.hasProfanity == true)
          _buildProfanityWarning(),
      ],
    );
  }

  Widget _buildStatusIcon() {
    if (_isChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_hasError) {
      return Icon(
        Icons.warning_amber_rounded,
        color: _getWarningColor(),
        size: 20,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildProfanityWarning() {
    final result = _lastCheckResult!;
    final color = _getWarningColor();
    final icon = _getWarningIcon(result.level);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message ?? 'Uygunsuz içerik tespit edildi',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getWarningColor() {
    switch (_lastCheckResult?.level) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getWarningIcon(String level) {
    switch (level) {
      case 'high':
        return Icons.block;
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.info_outline;
    }
  }
}
