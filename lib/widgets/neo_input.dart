import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:material_ui/material_ui.dart';
import '../theme/neo_theme.dart';

class NeoInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;

  const NeoInput({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.obscureText = false,
    this.inputFormatters,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label!.toUpperCase(),
                style: NeoText.label(10, color: ink)),
          ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          inputFormatters: inputFormatters,
          style: textStyle ??
              NeoText.body(14, weight: FontWeight.w600, color: ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: NeoText.body(14, color: ink.withValues(alpha: 0.4)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: ink, size: 20)
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: Neo.paper(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NeoRadius.reg),
              borderSide: BorderSide(color: ink, width: 3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NeoRadius.reg),
              borderSide: const BorderSide(color: NeoColors.yellow, width: 3),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NeoRadius.reg),
              borderSide: const BorderSide(color: NeoColors.red, width: 3),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NeoRadius.reg),
              borderSide: const BorderSide(color: NeoColors.red, width: 3),
            ),
            errorStyle: NeoText.body(11, color: NeoColors.red),
          ),
        ),
      ],
    );
  }
}