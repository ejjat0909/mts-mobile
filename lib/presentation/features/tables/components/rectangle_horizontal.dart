import 'package:flutter/material.dart';
import 'package:mts/core/utils/color_utils.dart';
import 'package:mts/data/models/table/table_model.dart';

class RectangleHorizontal extends StatelessWidget {
  final TableModel tableModel;
  final String? seats;
  final int? status;
  double? size;

  RectangleHorizontal({
    super.key,
    required this.tableModel,
    this.status,
    this.seats,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    size ??= 90;

    double tableWidth = size! * 2; // Make it wider for horizontal rectangle
    double tableHeight = size!;
    double fontSize = size! / 3.6;
    double subFontSize = size! / 7.1;

    return Container(
      alignment: Alignment.center,
      height: tableHeight,
      width: tableWidth,
      decoration: BoxDecoration(
        color: ColorUtils.getTableStatusColor(tableModel),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: -4,
            blurRadius: 35,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            tableModel.name ?? '',
            style: TextStyle(fontSize: fontSize),
            // maxFontSize:
            //     tableModel.name != null && tableModel.name!.length < 5
            //         ? fontSize
            //         : fontSize - 8,
            // minFontSize: 10,
          ),
          seats != null
              ? Text('$seats seats', style: TextStyle(fontSize: subFontSize))
              : Container(),
        ],
      ),
    );
  }
}
