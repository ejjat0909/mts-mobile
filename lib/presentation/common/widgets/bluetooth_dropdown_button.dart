import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';

class BluetoothDropdownButton<T> extends StatefulWidget {
  final List<DropdownMenuItem<T>>? items;
  final void Function(T?)? onChanged;
  final T? value;

  const BluetoothDropdownButton({
    super.key,
    required this.items,
    required this.onChanged,
    required this.value,
  });

  @override
  State<BluetoothDropdownButton<T>> createState() =>
      _BluetoothDropdownButtonState<T>();
}

class _BluetoothDropdownButtonState<T>
    extends State<BluetoothDropdownButton<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.33),
          width: 1.0,
        ),
        color: Colors.white,
      ),
      child: DropdownButton<T>(
        items: widget.items,
        onChanged: widget.onChanged,
        value: widget.value,
        underline: Container(),
        style: AppTheme.normalTextStyle(),
        isExpanded: true,
        enableFeedback: true,
        borderRadius: BorderRadius.circular(5),
        icon: const Padding(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }
}
