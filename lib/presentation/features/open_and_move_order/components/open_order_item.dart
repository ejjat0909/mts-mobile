import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/widgets/table_name_row.dart';
import 'package:mts/presentation/common/widgets/text_with_badge.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class OpenOrderItem extends StatefulWidget {
  final SaleModel? saleModel; // boleh null sebab is head
  final bool isSelectSale;
  final Function(bool?) onChanged;
  final bool isHead;
  final bool isHaveOrder;
  final Function()? onPressed;

  const OpenOrderItem({
    super.key,
    this.saleModel,
    required this.isSelectSale,
    required this.onChanged,
    this.isHead = false,
    this.isHaveOrder = true,
    required this.onPressed,
  });

  @override
  State<OpenOrderItem> createState() => _OpenOrderItemState();
}

class _OpenOrderItemState extends State<OpenOrderItem> {
  // String saleCreatorName = '';
  // UserModel? userModel;
  // String? tableName;
  // StaffModel? staffModel = StaffModel();

  // final StaffFacade _staffFacade = ServiceLocator.get<StaffFacade>();
  // final UserFacade _userFacade = ServiceLocator.get<UserFacade>();

  // Future<void> getUserModel() async {
  //   if (widget.saleModel != null) {
  //     staffModel = await _staffFacade.getStaffModelById(
  //       widget.saleModel!.staffId!,
  //     );
  //     if (staffModel != null) {
  //       UserModel? user = await _userFacade.getUserModelByIdUser(
  //         staffModel!.userId!,
  //       );

  //       if (user != null) {
  //         userModel = user.copyWith().copyWith();
  //       } else {}
  //     }
  //   }
  //   setState(() {});
  // }

  // Future<void> getSaleCreatorName() async {
  //   if (userModel != null) {
  //     String tempName = userModel!.name!;

  //     if (!widget.isHead) {
  //       if (mounted) {
  //         TableModel? tableModel = Provider.of<TableLayoutNotifier>(
  //           context,
  //           listen: false,
  //         ).getTableModel(widget.saleModel!.tableId);
  //         if (tableModel?.id != null) {
  //           tableName = tableModel!.name;
  //         }
  //       }

  //       if (staffModel != null) {
  //         // userModel = await UserBloc.getUserModelByIdUser(staffModel.userId!) ??
  //         //     UserModel();
  //         // prints('tempName ${userModel!.name}');
  //         if (userModel!.id != null) {
  //           saleCreatorName = userModel!.name ?? 'noName'.tr();
  //         } else {
  //           saleCreatorName = tempName;
  //         }
  //       }
  //     }
  //   } else {}

  //   setState(() {});
  // }

  void showDialogue(String description) async {
    CustomDialog.show(
      context,
      description: description,
      title: 'notEnoughData'.tr(),
      btnOkText: 'OK',
      dialogType: DialogType.info,
      btnOkOnPress: () => NavigationUtils.pop(context),
    );
  }

  @override
  void initState() {
    // initData();
    super.initState();
  }

  // Future<void> initData() async {
  //   await getUserModel(); // Wait until userModel is set
  //   await getSaleCreatorName(); // Then get sale creator name
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: widget.isHead ? kPrimaryLightColor : white,
        child: InkWell(
          onTap: widget.onPressed,

          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: widget.isHaveOrder ? 0 : 20,
            ),

            //  margin: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                widget.isHaveOrder
                    ? Transform.scale(
                      scale: 1.5,
                      child: Checkbox(
                        side: BorderSide(color: kTextGray, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        value: widget.isSelectSale,
                        onChanged: widget.onChanged,
                        checkColor: white,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return kPrimaryColor;
                          }
                          return null;
                        }),
                        focusColor: kPrimaryLightColor,
                      ),
                    )
                    : const SizedBox(),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.isHead
                        ? 'runningNumber'.tr()
                        : widget.saleModel?.runningNumber.toString() ?? '',
                    style:
                        widget.isHead
                            ? AppTheme.normalTextStyle(
                              fontWeight: FontWeight.bold,
                            )
                            : AppTheme.normalTextStyle(),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 5),
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
                                      widget.saleModel!.name!,
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
                              widget.saleModel!.tableId != null
                                  ? TableNameRow(
                                    tableName:
                                        widget.saleModel!.tableName ?? '',
                                  )
                                  : Container(),
                              widget.saleModel!.remarks != null &&
                                      widget.saleModel!.remarks!.isNotEmpty
                                  ? Text(
                                    widget.saleModel!.remarks!,
                                    style: AppTheme.italicTextStyle(),
                                    textAlign: TextAlign.start,
                                  )
                                  : Container(),

                              widget.isHead
                                  ? const SizedBox.shrink()
                                  : Text(
                                    DateTimeUtils.getDateTimeFormat(
                                      widget.saleModel!.updatedAt,
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
                        : widget.saleModel!.staffName ?? 'null',
                    style:
                        widget.isHead
                            ? AppTheme.normalTextStyle(
                              fontWeight: FontWeight.bold,
                            )
                            : AppTheme.normalTextStyle(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.isHead
                        ? 'totalAmount'.tr()
                        : 'RM ${widget.saleModel!.totalPrice!.toStringAsFixed(2)}',
                    style:
                        widget.isHead
                            ? AppTheme.normalTextStyle(
                              fontWeight: FontWeight.bold,
                            )
                            : AppTheme.normalTextStyle(),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


