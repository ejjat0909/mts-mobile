import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class CustomMyTextFieldBlocBuilder extends StatefulWidget {
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
  final SuffixButton? suffixButton;
  final Widget? clearTextIcon;
  final FocusNode? focusNode; // Add a focus node parameter

  const CustomMyTextFieldBlocBuilder({
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
    this.suffixButton,
    this.clearTextIcon,
    this.focusNode, // Add the focus node parameter
  });

  @override
  _CustomMyTextFieldBlocBuilderState createState() =>
      _CustomMyTextFieldBlocBuilderState();

  // Create a static method to request focus on a CustomMyTextFieldBlocBuilder
  static void requestFocus(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_CustomMyTextFieldBlocBuilderState>();
    if (state != null) {
      FocusScope.of(context).requestFocus(state._focusNode);
    }
  }
}

class _CustomMyTextFieldBlocBuilderState
    extends State<CustomMyTextFieldBlocBuilder> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _hasSelectedAll = false;

  @override
  void initState() {
    super.initState();

    // Use the provided focus node or create a new one
    _focusNode = widget.focusNode ?? FocusNode();

    // Create a controller to manage text selection
    _controller = TextEditingController(text: widget.textFieldBloc.value);

    // Listen to focus changes
    _focusNode.addListener(_handleFocusChange);

    // Listen to text field bloc changes
    widget.textFieldBloc.stream.listen((state) {
      // Update controller text if it's different
      if (_controller.text != state.value) {
        // Update the text
        _controller.text = state.value;

        // If this is the initial value and we have focus, select all text
        if (widget.isHighlightValue &&
            !widget.isManuallyEdited &&
            _focusNode.hasFocus &&
            !_hasSelectedAll) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
          _hasSelectedAll = true;
        }
      }
    });
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      if (!_hasSelectedAll &&
          widget.isHighlightValue &&
          !widget.isManuallyEdited) {
        // Select all text on first focus if it's the initial value
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
        _hasSelectedAll = true;
      }
    } else {
      // When focus is lost, reset the selection flag to allow selection on next focus
      _hasSelectedAll = false;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);

    // Only dispose the focus node if we created it
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          widget.labelText,
          style:
              widget.style ??
              TextStyle(
                fontWeight:
                    widget.isLabelBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        _buildTextField(),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildTextField() {
    return TextFieldBlocBuilder(
      focusNode: _focusNode,
      isEnabled: widget.isEnabled,
      textCapitalization: widget.textCapitalization ?? TextCapitalization.none,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textFieldBloc: widget.textFieldBloc,
      onTap: widget.onTap,
      textStyle: TextStyle(
        color: kPrimaryColor,
        backgroundColor:
            widget.isHighlightValue && !widget.isManuallyEdited
                ? kPrimaryBgColor
                : Colors.transparent,
      ),
      // Show eyes
      suffixButton:
          widget.isObscureText
              ? SuffixButton.obscureText
              : (widget.suffixButton),
      obscureTextTrueIcon:
          widget.isObscureText
              ? const Icon(Icons.visibility_off, color: kTextGray)
              : null,
      obscureTextFalseIcon:
          widget.isObscureText
              ? const Icon(Icons.visibility, color: kPrimaryColor)
              : null,
      clearTextIcon: widget.clearTextIcon,
      decoration:
          widget.decoration ??
          InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            prefixIcon: widget.leading,
            prefixIconColor: kTextGray,
            suffixIcon: widget.trailingIcon,
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
            hintText: widget.hintText,
            hintStyle: AppTheme.normalTextStyle(
              color: kTextGray.withValues(alpha: 0.5),
            ),
          ),
    );
  }
}
