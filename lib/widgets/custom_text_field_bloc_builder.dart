import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

/// A custom implementation of TextFieldBlocBuilder that supports custom clear behavior
class CustomTextFieldBlocBuilder extends StatefulWidget {
  final TextFieldBloc<dynamic> textFieldBloc;
  final bool enableOnlyWhenFormBlocCanSubmit;
  final bool isEnabled;
  final FieldBlocErrorBuilder? errorBuilder;
  final EdgeInsetsGeometry? padding;
  final InputDecoration decoration;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? textStyle;
  final Color? textColor;
  final bool? obscureText;
  final TextAlign? textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool? showCursor;
  final bool autofocus;
  final bool autocorrect;
  final int maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final Brightness? keyboardAppearance;
  final bool enableInteractiveSelection;
  final GestureTapCallback? onTap;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final FocusNode? nextFocusNode;
  final bool readOnly;
  final bool focusOnValidationFailed;
  final Widget? clearTextIcon;
  final SuffixButton? suffixButton;
  final FocusNode? focusNode;

  const CustomTextFieldBlocBuilder({
    super.key,
    required this.textFieldBloc,
    this.enableOnlyWhenFormBlocCanSubmit = false,
    this.isEnabled = true,
    this.errorBuilder,
    this.padding,
    this.decoration = const InputDecoration(),
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textStyle,
    this.textColor,
    this.obscureText,
    this.textAlign,
    this.textAlignVertical,
    this.textDirection,
    this.showCursor,
    this.autofocus = false,
    this.autocorrect = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.keyboardAppearance,
    this.enableInteractiveSelection = true,
    this.onTap,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
    this.nextFocusNode,
    this.readOnly = false,
    this.focusOnValidationFailed = true,
    this.clearTextIcon,
    // Default to using our custom clear behavior
    this.suffixButton = SuffixButton.clearText,
    this.focusNode,
  });

  @override
  State<CustomTextFieldBlocBuilder> createState() =>
      _CustomTextFieldBlocBuilderState();
}

class _CustomTextFieldBlocBuilderState
    extends State<CustomTextFieldBlocBuilder> {
  @override
  Widget build(BuildContext context) {
    final InputDecoration customDecoration =
        widget.suffixButton == SuffixButton.clearText
            ? widget.decoration.copyWith(suffixIcon: _buildCustomClearButton())
            : widget.decoration;

    return TextFieldBlocBuilder(
      textFieldBloc: widget.textFieldBloc,
      enableOnlyWhenFormBlocCanSubmit: widget.enableOnlyWhenFormBlocCanSubmit,
      isEnabled: widget.isEnabled,
      errorBuilder: widget.errorBuilder,
      padding: widget.padding,
      decoration: customDecoration,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textStyle: widget.textStyle,
      textColor:
          widget.textColor != null
              ? WidgetStateProperty.all(widget.textColor)
              : null,
      obscureText: widget.obscureText,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      textDirection: widget.textDirection,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      keyboardAppearance: widget.keyboardAppearance,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      onTap: widget.onTap,
      buildCounter: widget.buildCounter,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      nextFocusNode: widget.nextFocusNode,
      readOnly: widget.readOnly,
      focusOnValidationFailed: widget.focusOnValidationFailed,
      clearTextIcon: widget.clearTextIcon,
      // Use a custom suffix button that calls our custom clear method
      suffixButton:
          widget.suffixButton == SuffixButton.clearText
              ? null // We'll handle this with a custom builder
              : widget.suffixButton,
      focusNode: widget.focusNode,
    );
  }

  Widget _buildCustomClearButton() {
    return StreamBuilder<TextFieldBlocState<dynamic>>(
      stream: widget.textFieldBloc.stream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final hasValue = state?.value != null && state!.value.isNotEmpty;

        return AnimatedOpacity(
          opacity: hasValue ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: widget.clearTextIcon ?? const Icon(Icons.clear),
            onPressed: hasValue ? _handleCustomClear : null,
          ),
        );
      },
    );
  }

  void _handleCustomClear() {
    // Check if the textFieldBloc has a custom clear method in extraData
    final extraData = widget.textFieldBloc.state.extraData;
    final customClear = extraData is Map ? extraData['customClear'] : null;
    if (customClear != null && customClear is Function) {
      customClear();
    } else {
      // Fall back to the default clear behavior
      widget.textFieldBloc.clear();
    }
  }
}
