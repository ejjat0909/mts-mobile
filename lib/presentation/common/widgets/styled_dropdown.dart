import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/input_decoration.dart';

class StyledDropdown<T> extends StatelessWidget {
  const StyledDropdown({
    super.key,
    required this.list,
    required this.setDropdownValue,
    required this.items,
    this.isHaveBorder = true,
    this.selected,
  });

  final List<T> list;
  final ValueSetter<T> setDropdownValue;
  final T? selected;
  final List<DropdownMenuItem<T>> items;
  final bool isHaveBorder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField2<T>(
        isDense: true,
        isExpanded: true,
        enableFeedback: false,
        decoration: textFieldInputDecoration2(isHaveBorder: isHaveBorder),
        value: selected,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: kHeader,
          overflow: TextOverflow.ellipsis,
        ),
        dropdownStyleData: DropdownStyleData(
          // use root navigator means isFullScreen for the dropdown size
          useRootNavigator: true,
          elevation: 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
            border: Border.all(color: kDisabledText),
          ),
          offset: const Offset(0, 0),
          scrollbarTheme: ScrollbarThemeData(
            interactive: true,
            radius: const Radius.circular(2),
            thickness: WidgetStateProperty.all<double>(6),
            thumbVisibility: WidgetStateProperty.all<bool>(true),
          ),
        ),
        onChanged: (T? value) {
          // Set dropdown value when the user selects an item.
          setDropdownValue(value as T);
        },
        items: items,
      ),
    );
  }
}
