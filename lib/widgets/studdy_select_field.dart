import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'studdy_text_field.dart';

class StuddySelectField extends StatelessWidget {
  const StuddySelectField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.errorText,
    this.labelColor = AppColors.navy,
  });

  final String label;
  final String? value;
  final String? errorText;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return StuddyFieldBox(
      errorText: errorText,
      onTap: onTap,
      child: Text(
        hasValue ? value! : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: hasValue
            ? AppText.field
            : AppText.field.copyWith(color: labelColor),
      ),
    );
  }
}
