import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/open_and_move_order/components/move_order_item.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

class MoveOrderBody extends ConsumerStatefulWidget {
  final List<SaleModel> listSaleModel;
  final List<bool> isSelectedList;

  const MoveOrderBody({
    super.key,
    required this.listSaleModel,
    required this.isSelectedList,
  });

  @override
  ConsumerState<MoveOrderBody> createState() => _MoveOrderBodyState();
}

class _MoveOrderBodyState extends ConsumerState<MoveOrderBody> {
  late List<bool> isSelectedList;

  @override
  void initState() {
    super.initState();
    isSelectedList = widget.isSelectedList;
  }

  String getListMoveOrderByName() {
    final saleItemsState = ref.read(saleItemProvider);
    String listMoveOrder = saleItemsState.selectedOpenOrders
        .map((order) => order.name)
        .join(', ');

    return listMoveOrder;
  }

  handleIsSelected(int index) {
    setState(() {
      isSelectedList[index] = !isSelectedList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Space(10),
        AppBar(
          elevation: 0,
          backgroundColor: white,
          title: Row(
            children: [
              Expanded(
                child: Text('moveOrder'.tr(), style: AppTheme.h1TextStyle()),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(FontAwesomeIcons.arrowLeft, color: canvasColor),
            onPressed: () {
              ref
                  .read(dialogNavigatorProvider.notifier)
                  .setPageIndex(DialogNavigatorEnum.openOrder);
              saleItemsNotifier.clearSelections();
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Text.rich(
            TextSpan(
              text: "${'move'.tr()} ",
              style: AppTheme.normalTextStyle(),
              children: [
                TextSpan(
                  text: getListMoveOrderByName(),
                  style: AppTheme.normalTextStyle(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                TextSpan(
                  text: " ${'to'.tr()}",
                  style: AppTheme.normalTextStyle(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15.0,
              vertical: 8.0,
            ),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of items per row
                crossAxisSpacing: 12.5, // Horizontal spacing
                mainAxisSpacing: 12.5, // Vertical spacing
                childAspectRatio: 1.5,
              ),
              itemCount:
                  widget.listSaleModel.isNotEmpty
                      ? widget.listSaleModel.length
                      : 0,
              itemBuilder: (context, index) {
                return MoveOrderItem(
                  isSelected: isSelectedList[index],
                  saleModel: widget.listSaleModel[index],
                  onPress: () {
                    onPressMoveOrderItem(context, index);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void onPressMoveOrderItem(BuildContext context, int index) {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    // check permission
    if (!permissionNotifier.hasManageAllOpenOrdersPermission()) {
      DialogUtils.showNoPermissionDialogue(context);
      return;
    }
    CustomDialog.show(
      context,
      icon: FontAwesomeIcons.arrowsToDot,
      title: 'confirmMoveOrder'.tr(),
      description: 'confirmMoveOrderDesc'.tr(
        args: [getListMoveOrderByName(), widget.listSaleModel[index].name!],
      ),
      btnOkText: 'confirm'.tr(),
      btnCancelText: 'cancel'.tr(),
      btnCancelOnPress: () => NavigationUtils.pop(context),
      btnOkOnPress: () async {
        await handleOnMergeItems(context, index);
      },
    );
  }

  Future<void> handleOnMergeItems(BuildContext context, int index) async {
    final saleItemsState = ref.read(saleItemProvider);
    final predefinedOrderNotifier = ref.read(predefinedOrderProvider.notifier);

    // close dialogue
    NavigationUtils.pop(context);
    // handleIsSelected(index);
    List<SaleModel> selectedOpenOrders = saleItemsState.selectedOpenOrders;

    await predefinedOrderNotifier.handleMergeOrders(
      context,
      widget.listSaleModel[index],
      selectedOpenOrders,
    );
  }
}
