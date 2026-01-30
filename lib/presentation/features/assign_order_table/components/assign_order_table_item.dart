import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/common/widgets/table_name_row.dart';
import 'package:mts/presentation/common/widgets/text_with_badge.dart';

class AssignOrderTableItem extends StatefulWidget {
  final SaleModel? saleModel;
  final Function() onAssign;
  final bool isHead;
  final bool isHaveOrder;

  const AssignOrderTableItem({
    super.key,
    required this.saleModel,
    required this.onAssign,
    this.isHead = false,
    this.isHaveOrder = true,
  });

  @override
  State<AssignOrderTableItem> createState() => _AssignOrderTableItemState();
}

class _AssignOrderTableItemState extends State<AssignOrderTableItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isHead ? kPrimaryLightColor : white,
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              widget.isHead
                  ? 'runningNumber'.tr()
                  : widget.saleModel?.runningNumber.toString() ?? '',
              style:
                  widget.isHead
                      ? AppTheme.normalTextStyle(fontWeight: FontWeight.bold)
                      : AppTheme.normalTextStyle(),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 3,
            child:
                widget.isHead
                    ? Text(
                      'orderName'.tr(),
                      style: AppTheme.normalTextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.start,
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                widget.saleModel?.name ?? '',
                                style: AppTheme.normalTextStyle(),
                                textAlign: TextAlign.start,
                              ),
                            ),
                            5.widthBox,
                            TextWithBadge(
                              text: widget.saleModel?.orderOptionName,
                              textColor: kBadgeTextYellow,
                              backgroundColor: kBadgeBgYellow,
                            ),
                          ],
                        ),
                        widget.saleModel?.tableId != null
                            ? TableNameRow(
                              tableName: widget.saleModel?.tableName ?? '',
                            )
                            : Container(),
                        widget.saleModel?.remarks != null &&
                                widget.saleModel!.remarks!.isNotEmpty
                            ? Text(
                              widget.saleModel?.remarks ?? '',
                              style: AppTheme.italicTextStyle(),
                              textAlign: TextAlign.start,
                            )
                            : Container(),

                        widget.isHead
                            ? const SizedBox.shrink()
                            : Text(
                              DateTimeUtils.getDateTimeFormat(
                                widget.saleModel?.updatedAt,
                              ),
                              style: AppTheme.italicTextStyle(),
                            ),
                      ],
                    ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              widget.isHead
                  ? 'staff'.tr()
                  : widget.saleModel?.staffName ?? 'null',
              style:
                  widget.isHead
                      ? AppTheme.normalTextStyle(fontWeight: FontWeight.bold)
                      : AppTheme.normalTextStyle(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child:
                widget.isHead
                    ? Text(
                      "",
                      style: AppTheme.normalTextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    )
                    : ButtonTertiary(
                      text: 'assign'.tr(),
                      onPressed: widget.onAssign,
                    ),
          ),
        ],
      ),
    );
  }
}
