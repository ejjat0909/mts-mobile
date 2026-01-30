import 'package:flutter/widgets.dart';
import 'package:mts/core/config/constants.dart';

class TableLabel extends StatelessWidget {
  final String tableName;
  const TableLabel({super.key, required this.tableName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(width: 0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        tableName,
        textAlign: TextAlign.start,
        style: const TextStyle(
          color: canvasColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }
}
