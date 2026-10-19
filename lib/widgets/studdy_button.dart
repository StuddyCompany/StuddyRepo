import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StuddyButton extends StatelessWidget {
  const StuddyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(40),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.white,
                    ),
                  )
                : Text(label, style: AppText.button),
          ),
        ),
      ),
    );
  }
}
