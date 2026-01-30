import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/widgets/custom_text_field_bloc_builder.dart';

/// A text field that selects all text on first focus
class SelectAllTextField extends StatefulWidget {
  final TextFieldBloc textFieldBloc;
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

  const SelectAllTextField({
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
    this.suffixButton = SuffixButton.clearText,
  });

  @override
  SelectAllTextFieldState createState() => SelectAllTextFieldState();
}

class SelectAllTextFieldState extends State<SelectAllTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _hasSelectedAll = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    // Create a controller to manage text selection
    _controller = TextEditingController(text: widget.textFieldBloc.value);

    // Listen to focus changes
    _focusNode.addListener(_handleFocusChange);

    // Listen to text field bloc changes
    widget.textFieldBloc.stream.listen((state) {
      // Update controller text if it's different
      if (_controller.text != state.value) {
        _controller.text = state.value;
      }
    });
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && !_hasSelectedAll) {
      // Select all text on first focus
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      _hasSelectedAll = true;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextFieldBlocBuilder(
      textFieldBloc: widget.textFieldBloc,
      enableOnlyWhenFormBlocCanSubmit: widget.enableOnlyWhenFormBlocCanSubmit,
      isEnabled: widget.isEnabled,
      errorBuilder: widget.errorBuilder,
      padding: widget.padding,
      decoration: widget.decoration,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textStyle: widget.textStyle,
      textColor: widget.textColor,
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
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
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
      suffixButton: widget.suffixButton,
      focusNode: _focusNode,
    );
  }
}
