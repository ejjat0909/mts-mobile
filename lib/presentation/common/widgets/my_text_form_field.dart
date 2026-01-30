import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';

class MyTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String labelText;
  final TextStyle? style;
  final String hintText;
  final IconData? trailingIcon;
  final Widget? leading;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization? textCapitalization;
  final Function(String)? onChanged;
  final Function()? onEditingComplete;
  final Function()? trailingIconOnPress;
  final EdgeInsets scrollPadding;
  final Color trailingIconColor;

  const MyTextFormField({
    super.key,
    required this.labelText,
    this.style,
    required this.hintText,
    this.trailingIcon,
    this.leading,
    this.decoration,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization,
    this.onChanged,
    this.onEditingComplete,
    this.controller,
    this.focusNode,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.trailingIconOnPress,
    this.trailingIconColor = kTextGray,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: style,
      scrollPadding: scrollPadding,
      controller: controller,
      focusNode: focusNode,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      onEditingComplete: onEditingComplete,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration:
          decoration ??
          InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            prefixIcon: leading,
            prefixIconColor: kTextGray,
            suffixIcon: IconButton(
              onPressed: trailingIconOnPress,
              icon: Icon(trailingIcon, size: 26, color: trailingIconColor),
            ),
            suffixIconColor: kTextGray,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryLightColor),
              gapPadding: 10,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimaryLightColor),
              gapPadding: 10,
            ),
            contentPadding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: kPrimaryLightColor),
              gapPadding: 10,
            ),
            fillColor: Colors.white,
            filled: true,
            labelStyle: AppTheme.normalTextStyle(fontSize: 16),
            labelText: labelText,
            hintText: hintText,
          ),
    );
  }
}
