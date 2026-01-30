import 'package:flutter/material.dart';
import 'package:mts/core/utils/color_utils.dart';
import 'package:mts/data/models/table/table_model.dart';

class LineVertical extends StatelessWidget {
  final TableModel tableModel;
  final String? seats;
  final int? status;
  double? size;

  LineVertical({
    super.key,
    required this.tableModel,
    this.status,
    this.seats,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    size ??= 90;

    double tableWidth = size! * 0.2; // Make it much thinner for line shape
    double tableHeight = size! * 2; // Make it much taller for line shape

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
    );
  }
}
