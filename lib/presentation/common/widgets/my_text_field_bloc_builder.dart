import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class MyTextFieldBlocBuilder extends StatelessWidget {
  final TextFieldBloc textFieldBloc;
  final String labelText;
  final TextStyle? style;
  final String hintText;
  final Widget? trailingIcon;
  final Widget? leading;
  final bool isObscureText;
  final bool isLabelBold;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization? textCapitalization;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final Function()? onEditingComplete;
  final Function()? onTap;
  final bool isHighlightValue;
  final bool isManuallyEdited;
  final bool isEnabled;
  final FocusNode? focusNode;
  final SuffixButton? suffixButton;
  final Widget? clearTextIcon;

  const MyTextFieldBlocBuilder({
    super.key,
    required this.textFieldBloc,
    this.onSubmitted,
    this.labelText = '',
    this.trailingIcon,
    this.style,
    this.leading,
    this.isObscureText = false,
    this.isLabelBold = false,
    this.hintText = '',
    this.decoration,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization,
    this.onEditingComplete,
    this.onChanged,
    this.isHighlightValue = false,
    this.isManuallyEdited = false,
    this.isEnabled = true,
    this.onTap,
    this.focusNode,
    this.suffixButton,
    this.clearTextIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 7.5),
        Text(
          labelText,
          style:
              style ??
              TextStyle(
                fontWeight: isLabelBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        TextFieldBlocBuilder(
          focusNode: focusNode,
          isEnabled: isEnabled,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          onSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textFieldBloc: textFieldBloc,
          onTap: onTap,
          textStyle: TextStyle(
            color: kPrimaryColor,
            backgroundColor:
                isHighlightValue && !isManuallyEdited
                    ? kPrimaryBgColor
                    : Colors.transparent,
          ),

          // Show eyes
          suffixButton:
              isObscureText ? SuffixButton.obscureText : (suffixButton),
          obscureTextTrueIcon:
              isObscureText
                  ? const Icon(Iconsax.eye_slash, color: kTextGray)
                  : null,
          obscureTextFalseIcon:
              isObscureText
                  ? const Icon(Iconsax.eye, color: kPrimaryColor)
                  : null,
          clearTextIcon: clearTextIcon,
          decoration:
              decoration ??
              InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.never,
                prefixIcon: leading,
                prefixIconColor: kTextGray,
                suffixIcon: trailingIcon,
                suffixIconColor: kTextGray,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: kTextGray),
                  gapPadding: 10,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kPrimaryColor),
                  gapPadding: 10,
                ),
                contentPadding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: kTextGray),
                  gapPadding: 10,
                ),
                fillColor: white,
                filled: true,
                labelStyle: AppTheme.normalTextStyle(fontSize: 16),
                // labelText: labelText,
                hintText: hintText,
                hintStyle: AppTheme.normalTextStyle(
                  color: kTextGray.withValues(alpha: 0.5),
                ),
              ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}
