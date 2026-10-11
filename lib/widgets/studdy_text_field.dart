import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StuddyTextField extends StatelessWidget {
  const StuddyTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.errorText,
    this.hintColor = AppColors.navy50,
    this.height = 56,
    this.textInset = 28,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final Color hintColor;
  final double height;
  final double textInset;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return StuddyFieldBox(
      errorText: errorText,
      height: height,
      textInset: textInset,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppText.field,
        cursorColor: AppColors.navy,
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppText.field.copyWith(color: hintColor),
        ),
      ),
    );
  }
}

class StuddyFieldBox extends StatelessWidget {
  const StuddyFieldBox({
    super.key,
    required this.child,
    this.errorText,
    this.onTap,
    this.height = 56,
    this.textInset = 28,
  });

  final Widget child;
  final String? errorText;
  final VoidCallback? onTap;
  final double height;
  final double textInset;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.fieldFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
            side: hasError
                ? const BorderSide(color: AppColors.navy)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: height,
              padding: EdgeInsets.only(left: textInset, right: 20),
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ),
        if (hasError)
          Positioned(
            left: 0,
            right: 0,
            top: height,
            child: Text(
              errorText!,
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ),
      ],
    );
  }
}
