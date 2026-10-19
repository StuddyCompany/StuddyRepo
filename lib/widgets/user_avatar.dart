import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_icon.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.size, this.url, this.bytes});

  final double size;
  final String? url;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final placeholder = AppIcon(AppIcons.avatarPlaceholder, size: size);

    if (bytes != null) {
      return ClipOval(
        child: Image.memory(bytes!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      );
    }
    return placeholder;
  }
}