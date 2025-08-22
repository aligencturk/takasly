import 'package:flutter/material.dart';
import 'user_block_dialog.dart';

class UserBlockButton extends StatelessWidget {
  final int userId;
  final String userName;
  final VoidCallback? onUserBlocked;
  final bool isOutlined;
  final String? customText;
  final IconData? customIcon;

  const UserBlockButton({
    Key? key,
    required this.userId,
    required this.userName,
    this.onUserBlocked,
    this.isOutlined = false,
    this.customText,
    this.customIcon,
  }) : super(key: key);

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserBlockDialog(
        userId: userId,
        userName: userName,
        onUserBlocked: onUserBlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = customText ?? 'Engelle';
    final buttonIcon = customIcon ?? Icons.block;

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: () => _showBlockDialog(context),
        icon: Icon(
          buttonIcon,
          size: 18,
          color: Colors.red[600],
        ),
        label: Text(
          buttonText,
          style: TextStyle(
            color: Colors.red[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _showBlockDialog(context),
      icon: Icon(
        buttonIcon,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        buttonText,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

/// Küçük boyutlu engelleme butonu
class UserBlockSmallButton extends StatelessWidget {
  final int userId;
  final String userName;
  final VoidCallback? onUserBlocked;
  final Color? backgroundColor;
  final Color? iconColor;

  const UserBlockSmallButton({
    Key? key,
    required this.userId,
    required this.userName,
    this.onUserBlocked,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserBlockDialog(
        userId: userId,
        userName: userName,
        onUserBlocked: onUserBlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: backgroundColor ?? Colors.red[200]!,
        ),
      ),
      child: IconButton(
        onPressed: () => _showBlockDialog(context),
        icon: Icon(
          Icons.block,
          size: 18,
          color: iconColor ?? Colors.red[600],
        ),
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        tooltip: '$userName kullanıcısını engelle',
      ),
    );
  }
}

/// Icon button olarak engelleme butonu
class UserBlockIconButton extends StatelessWidget {
  final int userId;
  final String userName;
  final VoidCallback? onUserBlocked;
  final Color? color;
  final double? size;

  const UserBlockIconButton({
    Key? key,
    required this.userId,
    required this.userName,
    this.onUserBlocked,
    this.color,
    this.size,
  }) : super(key: key);

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserBlockDialog(
        userId: userId,
        userName: userName,
        onUserBlocked: onUserBlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showBlockDialog(context),
      icon: Icon(
        Icons.block,
        color: color ?? Colors.red[600],
        size: size ?? 24,
      ),
      tooltip: '$userName kullanıcısını engelle',
    );
  }
}
