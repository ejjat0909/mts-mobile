// ignore: must_be_immutable
import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

// can be used when the item is from enum
class MyDropdownBlocBuilder extends StatelessWidget {
  SelectFieldBloc selectFieldBloc;
  FieldItem Function(BuildContext, dynamic)? itemBuilder;
  final String? label;
  final String? hint;
  void Function(dynamic)? onChanged;
  final bool isEnabled;

  MyDropdownBlocBuilder({
    super.key,
    required this.selectFieldBloc,
    this.itemBuilder,
    this.label,
    this.onChanged,
    this.hint,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label != null
            ? Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  label!,
                  style: AppTheme.normalTextStyle(color: kBlackColor),
                ),
              ],
            )
            : const SizedBox(),
        DropdownFieldBlocBuilder(
          hint: hint != null ? Text(hint!) : null,
          isEnabled: isEnabled,
          onChanged: onChanged,
          showEmptyItem: false,
          selectFieldBloc: selectFieldBloc,
          itemBuilder:
              itemBuilder ??
              (context, itemData) => FieldItem(
                child: DropdownMenuItem(
                  value: itemData.toString(),
                  child: Text(itemData.toString()),
                ),
              ),
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                width: 1.0,
                color: Colors.black.withValues(alpha: 0.33),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                width: 1.0,
                color: Colors.black.withValues(alpha: 0.33),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            fillColor: Colors.white,
            filled: true,
            labelStyle: AppTheme.normalTextStyle(color: kTextGray),
          ),
        ),
      ],
    );
  }
}
