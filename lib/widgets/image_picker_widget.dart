import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:takasly/services/pick_crop_service.dart';
import 'package:takasly/utils/logger.dart';

/// Fotoğraf seçme ve düzenleme widget'ı
/// Galeriden veya kameradan fotoğraf seçer, crop ekranında düzenleme yapar
class ImagePickerWidget extends StatefulWidget {
  final double? aspectRatio;
  final int maxImageSizeMB;
  final Function(Uint8List imageBytes)? onImageSelected;
  final Function(String error)? onError;
  final String? initialImageUrl;
  final bool showPreview;
  final double width;
  final double height;
  final String? placeholderText;

  const ImagePickerWidget({
    super.key,
    this.aspectRatio,
    this.maxImageSizeMB = 10,
    this.onImageSelected,
    this.onError,
    this.initialImageUrl,
    this.showPreview = true,
    this.width = 200,
    this.height = 200,
    this.placeholderText,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Görsel önizleme
        if (widget.showPreview) ...[
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildImagePreview(),
          ),
          const SizedBox(height: 16),
        ],

        // Butonlar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Galeri',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Kamera',
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),

        // Yükleniyor göstergesi
        if (_isLoading) ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ],
      ],
    );
  }

  /// Görsel önizleme widget'ı
  Widget _buildImagePreview() {
    if (_selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _selectedImageBytes!,
          fit: BoxFit.cover,
          width: widget.width,
          height: widget.height,
        ),
      );
    } else if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          widget.initialImageUrl!,
          fit: BoxFit.cover,
          width: widget.width,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  /// Placeholder widget'ı
  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            widget.placeholderText ?? 'Fotoğraf Seç',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Aksiyon butonu widget'ı
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : onTap,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  /// Fotoğraf seçme işlemi
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      Logger.debug('🖼️ ImagePickerWidget - Starting image pick from $source');

      final Uint8List? imageBytes = await PickCropService.pickAndCropImage(
        source: source,
        aspectRatio: widget.aspectRatio,
        compressQuality: 85,
      );

      if (imageBytes != null) {
        // Boyut kontrolü
        if (!PickCropService.isImageSizeAcceptable(
          imageBytes,
          maxSizeMB: widget.maxImageSizeMB.toDouble(),
        )) {
          final String errorMessage =
              'Fotoğraf boyutu çok büyük. Maksimum ${widget.maxImageSizeMB}MB olmalı.';
          Logger.warning(
            '🖼️ ImagePickerWidget - Image size too large: ${PickCropService.formatImageSize(imageBytes)}',
          );

          if (widget.onError != null) {
            widget.onError!(errorMessage);
          } else {
            _showErrorSnackBar(errorMessage);
          }
          return;
        }

        setState(() {
          _selectedImageBytes = imageBytes;
        });

        Logger.debug(
          '🖼️ ImagePickerWidget - Image selected successfully: ${PickCropService.formatImageSize(imageBytes)}',
        );

        if (widget.onImageSelected != null) {
          widget.onImageSelected!(imageBytes);
        }
      } else {
        Logger.debug('🖼️ ImagePickerWidget - Image selection cancelled');
      }
    } catch (e) {
      Logger.error('🖼️ ImagePickerWidget - Error picking image: $e');

      final String errorMessage =
          'Fotoğraf seçilirken bir hata oluştu. Lütfen tekrar deneyin.';

      if (widget.onError != null) {
        widget.onError!(errorMessage);
      } else {
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Hata mesajı göster
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Seçilen görseli temizle
  void clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  /// Seçilen görseli al
  Uint8List? get selectedImageBytes => _selectedImageBytes;
}
