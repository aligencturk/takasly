import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profanity_check_result.dart';
import '../services/profanity_service.dart';
import '../utils/logger.dart';
import '../core/app_theme.dart';

class ProfanityCheckTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
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

  const ProfanityCheckTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
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
  });

  @override
  State<ProfanityCheckTextField> createState() => _ProfanityCheckTextFieldState();
}

class _ProfanityCheckTextFieldState extends State<ProfanityCheckTextField> {
  ProfanityCheckResult? _lastCheckResult;
  bool _isChecking = false;
  Timer? _debounceTimer;

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
      Logger.info('✅ ProfanityCheckTextField - ProfanityService başlatıldı');
    } catch (e) {
      Logger.error('❌ ProfanityCheckTextField - ProfanityService başlatılamadı: $e');
    }
  }

  void _onTextChanged(String value) {
    // Debounce ile küfür kontrolü yap
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkProfanity(value);
    });

    // Parent callback'i çağır
    widget.onChanged?.call(value);
  }

  Future<void> _checkProfanity(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _lastCheckResult = null;
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
        });

        if (result.hasProfanity) {
          Logger.info('🚫 ProfanityCheckTextField - Uygunsuz içerik tespit edildi: ${result.detectedWord}');
        }
      }
    } catch (e) {
      Logger.error('❌ ProfanityCheckTextField - Küfür kontrolü hatası: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  String? _validateText(String? value) {
    // Önce custom validator'ı çalıştır
    final customValidation = widget.validator?.call(value);
    if (customValidation != null) {
      return customValidation;
    }

    // Küfür kontrolü
    if (_lastCheckResult?.hasProfanity == true) {
      return _lastCheckResult!.message ?? 'Uygunsuz içerik tespit edildi';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          inputFormatters: widget.inputFormatters,
          onChanged: _onTextChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: _validateText,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            helperText: widget.helperText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: widget.border ?? OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: widget.enabledBorder ?? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: widget.focusedBorder ?? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            errorBorder: widget.errorBorder ?? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: widget.focusedErrorBorder ?? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
          ),
        ),
        
        // Küfür uyarısı
        if (widget.showProfanityWarning && _lastCheckResult?.hasProfanity == true)
          _buildProfanityWarning(),
      ],
    );
  }

  Widget _buildSuffixIcon() {
    if (_isChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_lastCheckResult?.hasProfanity == true) {
      return Icon(
        Icons.warning_amber_rounded,
        color: _getWarningColor(),
        size: 20,
      );
    }

    if (_lastCheckResult?.hasProfanity == false) {
      return const Icon(
        Icons.check_circle_outline,
        color: Colors.green,
        size: 20,
      );
    }

    return widget.suffixIcon ?? const SizedBox.shrink();
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
