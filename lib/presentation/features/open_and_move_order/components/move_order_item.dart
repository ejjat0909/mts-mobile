import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/user/user_providers.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class MoveOrderItem extends ConsumerStatefulWidget {
  final SaleModel saleModel;
  final bool isSelected;
  final Function() onPress;

  const MoveOrderItem({
    super.key,
    required this.saleModel,
    required this.isSelected,
    required this.onPress,
  });

  @override
  ConsumerState<MoveOrderItem> createState() => _MoveOrderItemState();
}

class _MoveOrderItemState extends ConsumerState<MoveOrderItem> {
  UserModel globalUserModel = ServiceLocator.get<UserModel>();

  Future<Map<String, dynamic>> getData() async {
    StaffModel staffModel = StaffModel();
    if (widget.saleModel.staffId != null) {
      staffModel =
          await ref
              .read(staffProvider.notifier)
              .getStaffModelById(widget.saleModel.staffId!) ??
          StaffModel();
    }
    UserModel userModel = UserModel();

    if (staffModel.id != null) {
      userModel =
          await ref
              .read(userProvider.notifier)
              .getUserModelByIdUser(staffModel.userId!) ??
          globalUserModel;
    }

    return {'staffModel': staffModel, 'userModel': userModel};
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed: widget.onPress,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(7.5),
          border: Border.all(
            width: widget.isSelected ? 2 : 0.5,
            color: widget.isSelected ? kPrimaryColor : kBlackColor,
          ),
        ),
        child: FutureBuilder(
          future: getData(),
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: ThemeSpinner.spinner());
            }
            StaffModel staffModel = snapshot.data!['staffModel'] as StaffModel;
            UserModel userModel = snapshot.data!['userModel'] as UserModel;

            return body(
              widget.isSelected ? kPrimaryColor : kBlackColor,
              staffModel,
              userModel,
            );
          },
        ),
      ),
    );
  }

  // Widget selectedContainer() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(7.5),
  //       border: Border.all(
  //         width: 0.5,
  //         color: Colors.transparent,
  //       ),
  //     ),
  //     child: Stack(
  //       children: [
  //         // call this double to initiate the container height
  //         Container(
  //             width: double.infinity,
  //             decoration: const BoxDecoration(
  //               color: selectedColor,
  //               borderRadius: BorderRadius.all(Radius.circular(7.5)),
  //             ),
  //             child: body(Colors.transparent)),

  //         const Positioned(
  //           top: -25,
  //           right: -25,
  //           child: BorderedIcon(
  //             strokeColor: white,
  //             strokeWidth: 10,
  //             icon: Icon(
  //               FontAwesomeIcons.circleCheck,
  //               size: 100,
  //               color: selectedColor,
  //             ),
  //           ),
  //         ),
  //         SizedBox(
  //           width: double.infinity,
  //           child: body(kBlackColor),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget body(Color color, StaffModel staffModel, UserModel userModel) {
    if (widget.saleModel.staffId != null) {
      if (staffModel.id != null) {
        if (userModel.id != null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.receipt, color: color),
              const Space(10),
              Text(
                widget.saleModel.name ?? 'noName'.tr(),
                style: AppTheme.normalTextStyle(
                  color: color,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              Space(widget.saleModel.tableName != null ? 5 : 0),
              if (widget.saleModel.tableName != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(TableModel.getIcon(), color: kTextGray, size: 20),
                    5.widthBox,
                    Flexible(
                      child: Text(
                        widget.saleModel.tableName!,
                        style: AppTheme.normalTextStyle(
                          color: color,
                          fontWeight:
                              widget.isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              const Space(5),
              Text(
                userModel.name!,
                maxLines: 2,
                style: AppTheme.normalTextStyle(
                  color: color,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              // Text(
              //   'RM'.tr(
              //     args: [
              //       discountModel.value?.toStringAsFixed(2) ?? 0.toStringAsFixed(2)
              //     ],
              //   ),
              //   style: AppTheme.normalTextStyle(color: color),
              // )
            ],
          );
        }
      }
    }

    return Container();
  }
}
