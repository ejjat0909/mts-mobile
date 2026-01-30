import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mts/core/utils/color_utils.dart';
import 'package:mts/data/models/table/table_model.dart';

class SquareTable extends StatelessWidget {
  final TableModel tableModel;
  final String? seats;
  final int? status;
  double? size;

  SquareTable({
    super.key,
    required this.tableModel,
    this.status,
    this.seats,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    size ??= 90;

    double seatHeight = size! / 10;
    double seatWidth = size! / 1.7;
    double seatGap = size! / 10;
    double fontSize = size! / 3.6;
    double subFontSize = size! / 7.1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: seatHeight,
          width: seatWidth,
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
        ),
        SizedBox(height: seatGap),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: seatWidth,
              width: seatHeight,
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
            ),
            SizedBox(width: seatGap),
            Container(
              alignment: Alignment.center,
              height: size,
              width: size,
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
                  AutoSizeText(
                    tableModel.name ?? '',
                    style: TextStyle(fontSize: fontSize),
                    maxFontSize:
                        tableModel.name != null && tableModel.name!.length < 5
                            ? fontSize
                            : fontSize - 8,
                    minFontSize: 10,
                  ),
                  seats != null
                      ? Text(
                        '$seats seats',
                        style: TextStyle(fontSize: subFontSize),
                      )
                      : Container(),
                ],
              ),
            ),
            SizedBox(width: seatGap),
            Container(
              height: seatWidth,
              width: seatHeight,
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
            ),
          ],
        ),
        SizedBox(height: seatGap),
        Container(
          height: seatHeight,
          width: seatWidth,
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
        ),
      ],
    );
  }
}
