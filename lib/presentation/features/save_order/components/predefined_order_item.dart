import 'package:flutter/material.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/presentation/common/widgets/table_name_row.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PredefinedOrderItem extends StatelessWidget {
  final PredefinedOrderModel predefinedOrderModel;
  final String? tableName;
  final Function() press;
  final int index; // For alternating colors

  const PredefinedOrderItem({
    super.key,
    required this.predefinedOrderModel,
    required this.press,
    required this.index,
    this.tableName,
  });

  Color? getBackgroundColor(bool isReversed) {
    if (!isReversed) {
      return index.isEven ? Colors.grey[300] : white;
    } else {
      return index.isEven ? white : Colors.grey[300];
    }
  }

  bool getTableExists() {
    if (tableName != null && tableName!.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTable = getTableExists();
    final iconData = hasTable ? TableModel.getIcon() : FontAwesomeIcons.receipt;

    return InkWell(
      onTap: press,
      child: Container(
        color: getBackgroundColor(false), // Alternating strips
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8), // adjust for circle size
              decoration: BoxDecoration(
                color: getBackgroundColor(true), // circle background color
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 20.0,
                color: hasTable ? kPrimaryColor : getBackgroundColor(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Predefined order name
                  Text(
                    predefinedOrderModel.name!,
                    style: textStyleNormal(fontWeight: FontWeight.bold),
                  ),
                  // Table name row (reusing your existing widget)
                  if (hasTable) ...[
                    const SizedBox(height: 4),
                    TableNameRow(
                      hasTable: false,
                      tableName: tableName!,
                      textColor: kPrimaryColor,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }
}
