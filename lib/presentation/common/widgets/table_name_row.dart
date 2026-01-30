import 'package:flutter/material.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class TableNameRow extends StatelessWidget {
  final bool hasTable;
  final Color textColor;
  const TableNameRow({
    super.key,

    required this.tableName,
    this.textColor = kTextGray,
    this.hasTable = true,
  });

  final String tableName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasTable) ...[
          Icon(TableModel.getIcon(), color: textColor, size: 20),
          5.widthBox,
        ],

        Flexible(
          child: Text(
            tableName,

            // "${'table'.tr()} ${widget.saleModel!.tableName}",
            style: textStyleItalic(color: textColor),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }
}
