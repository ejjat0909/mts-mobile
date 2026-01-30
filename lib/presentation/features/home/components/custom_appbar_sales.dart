import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/department_type_enum.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/enum/page_enum.dart';
import 'package:mts/core/enum/popup_menu_enum.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/domain/repositories/local/print_receipt_cache_repository.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/table_label.dart';
import 'package:mts/presentation/features/assign_order/assign_order_dialogue.dart';
import 'package:mts/presentation/features/customer/customer_dialogue.dart/customer_dialogue.dart';
import 'package:mts/presentation/features/edit_order/edit_order_dialogue.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_providers.dart';
import 'package:mts/providers/app/app_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';
import 'package:mts/providers/table/table_providers.dart';
import 'package:mts/providers/pending_changes/pending_changes_providers.dart';
import 'package:mts/providers/error_log/error_log_providers.dart';

class CustomAppBarSales extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final String titleRightSide;
  final String titleLeftSide;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final IconData rightSideIcon;

  final IconData? action;
  final Function()? actionPress;

  const CustomAppBarSales({
    super.key,
    required this.titleRightSide,
    required this.titleLeftSide,
    required this.scaffoldKey,
    required this.rightSideIcon,
    this.action,
    this.actionPress,
  });

  @override
  ConsumerState<CustomAppBarSales> createState() => _CustomAppBarSalesState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarSalesState extends ConsumerState<CustomAppBarSales> {
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(onHandleSearch);
  }

  @override
  void dispose() {
    searchController.dispose();
    searchController.removeListener(onHandleSearch);
    super.dispose();
  }

  void onHandleSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemProvider.notifier).setItemName(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageItemNotifier = ref.watch(pageItemProvider.notifier);
    final customerNotifier = ref.watch(customerProvider.notifier);
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    final hasPermissionManageOrders =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    final hasPermissionOpenCashDrawer =
        permissionNotifier.hasOpenCashDrawerWithoutMakingSalePermission();
    bool hasPermissionVoidOrder =
        permissionNotifier.hasVoidSavedItemsInOpenOrderPermission();
    final featureCompNotifier = ref.watch(featureCompanyProvider.notifier);
    final isFeatureOpenOrderActive = featureCompNotifier.isOpenOrdersActive();
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    final isEditMode = saleItemsState.isEditMode;
    final canVoid = saleItemsState.currSaleModel?.id != null;
    final canClear = saleItemsState.saleItems.isNotEmpty;
    final canReprint =
        saleItemsState.currSaleModel?.id != null &&
        saleItemsState.pom?.id != null;
    final canAssignOrder = saleItemsState.currSaleModel?.id != null;
    ref.watch(itemProvider);
    final itemNotifier = ref.read(itemProvider.notifier);
    final appContextNotifier = ref.watch(appProvider.notifier);
    String? poName = saleItemsState.pom?.name;
    String? poId = saleItemsState.pom?.id;
    final printReceiptCacheNotifier = ref.watch(
      printReceiptCacheProvider.notifier,
    );
    final listPrcProcessing = printReceiptCacheNotifier.listPrcProcessing();
    return defaultAppBar(
      appContextNotifier,
      itemNotifier,
      saleItemsNotifier,
      pageItemNotifier,
      isEditMode,
      context,
      canVoid,
      canClear,
      canReprint,
      canAssignOrder,
      customerNotifier,
      saleItemsState.selectedTable?.name,
      poName,
      poId,
      isFeatureOpenOrderActive,
      hasPermissionManageOrders,
      hasPermissionOpenCashDrawer,
      hasPermissionVoidOrder,
      listPrcProcessing,
    );
  }

  AppBar defaultAppBar(
    AppNotifier appContextNotifier,
    ItemNotifier itemNotifier,
    SaleItemNotifier saleItemsNotifier,
    PageItemNotifier pageItemNotifier,
    bool isEditMode,
    BuildContext context,
    bool canVoid,
    bool canClear,
    bool canReprint,
    bool canAssignOrder,
    CustomerNotifier customerNotifier,
    String? tableName,
    String? poName,
    String? poId,
    bool isFeatureOpenOrderActive,
    bool hasPermissionManageOrders,
    bool hasPermissionOpenCashDrawer,
    bool hasPermissionVoidOrder,
    List<PrintReceiptCacheModel> listPrcProcessing,
  ) {
    final pageId = pageItemNotifier.getCurrentPageId;
    final saleItemsState = ref.read(saleItemProvider);
    final pom = saleItemsState.pom;
    bool isEnableEditOrder = pom?.isCustom ?? false;
    return AppBar(
      automaticallyImplyLeading: false,

      // Disable the default leading icon
      backgroundColor: canvasColor,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // left side of the app bar
          pageId != PageEnum.pageSearchItem
              ? leftSideDefault(pageItemNotifier)
              : leftSideSearch(pageItemNotifier, itemNotifier),
          // Right side of the app bar
          Expanded(
            flex: 2,
            child: Container(
              height: kToolbarHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25)),
              ),
              child:
                  isEditMode
                      ? Container()
                      : Row(
                        children: [
                          const SizedBox(width: 15),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    // "${poName ?? widget.titleRightSide} - ${outletModel.nextOrderNumber}",
                                    poName ?? widget.titleRightSide,
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      color: canvasColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                tableName != null
                                    ? TableLabel(tableName: tableName)
                                    : Container(),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (customerNotifier.getOrderCustomerModel !=
                                  null) {
                                ref
                                    .read(dialogNavigatorProvider.notifier)
                                    .setPageIndex(
                                      DialogNavigatorEnum.viewCustomer,
                                    );
                              } else {
                                ref
                                    .read(dialogNavigatorProvider.notifier)
                                    .setPageIndex(
                                      DialogNavigatorEnum.listCustomer,
                                    );
                              }

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return const CustomerDialogue();
                                },
                              );
                            },
                            splashColor: kPrimaryLightColor,
                            highlightColor: kPrimaryLightColor,
                            icon: Icon(
                              customerNotifier.getOrderCustomerModel?.id == null
                                  ? FontAwesomeIcons.userPlus
                                  : FontAwesomeIcons.userCheck,
                              size: 20,
                              color:
                                  customerNotifier.getOrderCustomerModel?.id ==
                                          null
                                      ? canvasColor
                                      : kBadgeTextGreen,
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'showMenu'.tr(),
                            icon: Badge(
                              backgroundColor:
                                  listPrcProcessing.isNotEmpty
                                      ? kTextRed
                                      : Colors.transparent,

                              child: Icon(
                                widget.rightSideIcon,
                                color: kBlackColor,
                              ),
                            ),
                            elevation: 1,
                            color: white,
                            onSelected: (String result) async {
                              // Handle menu selection
                              if (result == PopupMenuEnum.clearOrder) {
                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );
                                CustomDialog.show(
                                  context,
                                  icon: FontAwesomeIcons.eraser,
                                  dialogType: DialogType.warning,
                                  title: 'Clear Items'.tr(),
                                  description: 'removeAllItemAsk'.tr(),
                                  btnOkText: 'Clear'.tr(),
                                  btnCancelText: 'cancel'.tr(),
                                  btnOkOnPress: () async {
                                    NavigationUtils.pop(context);
                                    await handleOnClearOrder();
                                  },
                                  btnCancelOnPress: () {
                                    NavigationUtils.pop(context);
                                  },
                                );
                              }

                              if (result == PopupMenuEnum.voidOrder) {
                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );
                                CustomDialog.show(
                                  context,
                                  icon: FontAwesomeIcons.trashCan,
                                  dialogType: DialogType.warning,
                                  title: 'Void Order'.tr(),
                                  description: 'voidOrderAsk'.tr(),
                                  btnOkText: 'Void'.tr(),
                                  btnCancelText: 'cancel'.tr(),
                                  btnOkOnPress: () async {
                                    NavigationUtils.pop(context);
                                    await handleOnVoidOrder();
                                  },
                                  btnCancelOnPress: () {
                                    NavigationUtils.pop(context);
                                  },
                                );
                              }
                              if (result == PopupMenuEnum.editOrder) {
                                if (isEnableEditOrder) {
                                  await onHandleEditOrder(pom!);
                                }
                              }
                              if (result == PopupMenuEnum.unlinkTable) {
                                await handleUnlinkTable(saleItemsNotifier);
                              }

                              if (result == PopupMenuEnum.reprintOrder) {
                                await onReprintOrder(context);
                              }

                              if (result == PopupMenuEnum.syncOrder) {
                                //  await handleDeletePendingChanges();
                                await onSyncOrder(context);
                              }

                              // open cash drawer
                              if (result == PopupMenuEnum.openCashDrawer) {
                                await onOpenCashDrawer(context);
                              }

                              if (result ==
                                  PopupMenuEnum.deletePendingChanges) {
                                await handleDeletePendingChanges();
                              }

                              if (result == PopupMenuEnum.assignOrder) {
                                await onAssignOrder(context);
                              }

                              if (result == PopupMenuEnum.forceSync) {
                                await onForceSync(context);
                              }

                              if (result == PopupMenuEnum.printPending) {
                                await onReprintPending(context);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return <PopupMenuEntry<String>>[
                                if (hasPermissionManageOrders)
                                  PopupMenuItem<String>(
                                    value: PopupMenuEnum.unlinkTable,
                                    enabled: tableName != null,
                                    child: ListTile(
                                      leading: Icon(
                                        TableModel.getIcon(),
                                        color: kBlackColor,
                                      ),
                                      title: Text('unlink_element'.tr()),
                                    ),
                                  ),
                                if (hasPermissionManageOrders)
                                  PopupMenuItem<String>(
                                    value: PopupMenuEnum.clearOrder,
                                    enabled: canClear,
                                    child: ListTile(
                                      leading: const Icon(
                                        FontAwesomeIcons.eraser,
                                        color: kBlackColor,
                                      ),
                                      title: Text('clearOrder'.tr()),
                                    ),
                                  ),
                                if (hasPermissionManageOrders)
                                  PopupMenuItem<String>(
                                    value: PopupMenuEnum.voidOrder,
                                    enabled: canVoid,
                                    child: const ListTile(
                                      leading: Icon(
                                        Icons.delete,
                                        color: kBlackColor,
                                      ),
                                      title: Text('Void Order'),
                                    ),
                                  ),
                                if (isFeatureOpenOrderActive)
                                  if (hasPermissionManageOrders)
                                    PopupMenuItem<String>(
                                      value: PopupMenuEnum.editOrder,
                                      enabled: isEnableEditOrder,
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.edit,
                                          color: kBlackColor,
                                        ),
                                        title: Text('editOrder'.tr()),
                                      ),
                                    ),
                                if (hasPermissionManageOrders)
                                  PopupMenuItem<String>(
                                    value: PopupMenuEnum.assignOrder,
                                    enabled: canAssignOrder,
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.person_rounded,
                                        color: kBlackColor,
                                      ),
                                      title: Text('assignOrder'.tr()),
                                    ),
                                  ),
                                // PopupMenuItem<String>(
                                //   value: PopupMenuEnum.MOVE_ORDER,
                                //   child: ListTile(
                                //     leading: const Icon(Icons.move_to_inbox,
                                //         color: kBlackColor),
                                //     title: Text('moveOrder'.tr()),
                                //   ),
                                // ),
                                if (poId != null)
                                  PopupMenuItem<String>(
                                    enabled: canReprint,
                                    value: PopupMenuEnum.reprintOrder,
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.print,
                                        color: kBlackColor,
                                      ),
                                      title: Text('rePrint'.tr()),
                                    ),
                                  ),
                                if (listPrcProcessing.isNotEmpty)
                                  PopupMenuItem<String>(
                                    enabled: true,
                                    value: PopupMenuEnum.printPending,
                                    child: ListTile(
                                      leading: Badge(
                                        label: Text(
                                          listPrcProcessing.length.toString(),
                                        ),
                                        child: const Icon(
                                          Icons.print_rounded,
                                          color: kBlackColor,
                                        ),
                                      ),
                                      title: Text('rePrintPendingOrders'.tr()),
                                    ),
                                  ),
                                PopupMenuItem<String>(
                                  enabled: true,
                                  value: PopupMenuEnum.openCashDrawer,
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.lock_open_outlined,
                                      color: kBlackColor,
                                    ),
                                    title: Text('openCashDrawer'.tr()),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: PopupMenuEnum.syncOrder,
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.sync,
                                      color: kBlackColor,
                                    ),
                                    title: Text('sync'.tr()),
                                  ),
                                ),
                                if (isStaging)
                                  PopupMenuItem<String>(
                                    value: PopupMenuEnum.deletePendingChanges,
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.delete_forever,
                                        color: kBlackColor,
                                      ),
                                      title: Text('Delete Pending'.tr()),
                                    ),
                                  ),
                                if (isStaging) const PopupMenuDivider(),
                                if (isStaging)
                                  PopupMenuItem<String>(
                                    value: PopupMenuEnum.forceSync,
                                    child: const ListTile(
                                      leading: Icon(
                                        Icons.sync_lock,
                                        color: kBlackColor,
                                      ),
                                      title: Text('Force Sync'),
                                    ),
                                  ),
                              ];
                            },
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onReprintOrder(BuildContext context) async {
    final saleItemsState = ref.read(saleItemProvider);
    SaleModel? sm = saleItemsState.currSaleModel;
    final PredefinedOrderModel pom = saleItemsState.pom!;

    if (sm!.id != null) {
      Map<String, dynamic> data = await ref
          .read(saleProvider.notifier)
          .getPrintDataForIsPrintAgain(sm);
      if (data.isNotEmpty) {
        SaleModel saleModel = data['saleModel'];
        List<SaleItemModel> listSI = data['listSI'];
        List<SaleModifierModel> listSM = data['listSM'];
        List<SaleModifierOptionModel> listSMO = data['listSMO'];
        OrderOptionModel? orderOptionModel = data['orderOptionModel'];

        // nak bagi laju untuk print local, tapi lembap sikit untuk cross device
        await ref
            .read(printReceiptCacheProvider.notifier)
            .insertDetailsPrintCache(
              saleModel: saleModel,
              listSaleItemModel: listSI,
              listSM: listSM,
              listSMO: listSMO,
              orderOptionModel: orderOptionModel ?? OrderOptionModel(),
              pom: pom.id != null ? pom : PredefinedOrderModel(),
              printType: DepartmentTypeEnum.printKitchen,
              isForThisDevice: true,
            );
        await ref
            .read(saleProvider.notifier)
            .attemptPrintKitchen(
              onSuccessPrintReceiptCache: (listPrintReceiptCache) {},
            );
        await ref
            .read(printReceiptCacheProvider.notifier)
            .insertDetailsPrintCache(
              saleModel: saleModel,
              listSaleItemModel: listSI,
              listSM: listSM,
              listSMO: listSMO,
              orderOptionModel: orderOptionModel ?? OrderOptionModel(),
              pom: pom.id != null ? pom : PredefinedOrderModel(),
              printType: DepartmentTypeEnum.printKitchen,
              isForThisDevice: false,
            );
      } else {
        ThemeSnackBar.showSnackBar(context, 'Failed to get data');
      }
    } else {
      await ref
          .read(errorLogProvider.notifier)
          .createAndInsertErrorLog("No Sale ID, fail to re print order");
      ThemeSnackBar.showSnackBar(
        context,
        'Failed to reprint because there are no sale items.',
      );
    }
  }

  Future<void> onSyncOrder(BuildContext context) async {
    await ref
        .read(syncRealTimeProvider.notifier)
        .onSyncOrder(
          context,
          mounted,
          needToDownloadImage: true,
          manuallyClick: true,
          onlyCheckPendingChanges: false,
          isAfterActivateLicense: false,
          isSuccess: (isSuccess, errorMessage) {
            if (!isSuccess) {
              ThemeSnackBar.showSnackBar(
                context,
                errorMessage ?? 'Something went wrong and failed to sync',
              );
            }
          },
        );
  }

  Future<void> onOpenCashDrawer(BuildContext context) async {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    bool hasPermissionOpenDrawer =
        permissionNotifier.hasOpenCashDrawerWithoutMakingSalePermission();
    if (!hasPermissionOpenDrawer) {
      // show pin dialogue
      await DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.OPEN_CASH_DRAWER_WITHOUT_MAKING_SALE,
        onSuccess: () async {
          await ref
              .read(printerSettingProvider.notifier)
              .openCashDrawerManually((errorMessage) {
                ThemeSnackBar.showSnackBar(context, errorMessage);
              }, activityFrom: 'Open manually from sales page');
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
    }
    if (hasPermissionOpenDrawer) {
      await ref.read(printerSettingProvider.notifier).openCashDrawerManually((
        errorMessage,
      ) {
        ThemeSnackBar.showSnackBar(context, errorMessage);
      }, activityFrom: 'Open manually from sales page');
    }
  }

  Future<void> handleUnlinkTable(SaleItemNotifier saleItemsNotifier) async {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final saleItemsState = ref.read(saleItemProvider);
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);

    //  check manage all open orders permission
    if (!permissionNotifier.hasManageAllOpenOrdersPermission()) {
      DialogUtils.showNoPermissionDialogue(context);
      return;
    }
    TableModel? tableModel;

    final currSelectedTable = saleItemsState.selectedTable;

    if (currSelectedTable?.id != null) {
      tableModel = await ref
          .read(tableProvider.notifier)
          .getTableById(currSelectedTable!.id!);
      if (tableModel?.id != null) {
        saleItemsNotifier.setSelectedTable(TableModel());
      }
    }

    // reset table
    await ref
        .read(tableProvider.notifier)
        .resetTable(tableModel ?? TableModel());
  }

  Future<void> handleDeletePendingChanges() async {
    final pendingChangesNotifier = ref.read(pendingChangesProvider.notifier);
    // final localTable = ServiceLocator.get<LocalTableRepository>();
    // final saleFacade = ServiceLocator.get<SaleFacade>();
    // final saleItemFacade = ServiceLocator.get<SaleItemFacade>();
    // final saleModifierFacade = ServiceLocator.get<SaleModifierFacade>();
    // final localPageItem = ServiceLocator.get<LocalPageItemRepository>();
    // final pageItemNotifier = ServiceLocator.get<PageItemNotifier>();
    // final staffFacade = ServiceLocator.get<StaffFacade>();
    // final localSale = ServiceLocator.get<LocalSaleRepository>();
    // final localSaleItem = ServiceLocator.get<LocalSaleItemRepository>();
    // final pageItemFacade = ServiceLocator.get<PageItemFacade>();

    // final errorLogFacade = ServiceLocator.get<ErrorLogFacade>();

    // final saleModifierOptionFacade =
    //     ServiceLocator.get<SaleModifierOptionFacade>();

    // final localPredefinedOrder =
    //     ServiceLocator.get<LocalPredefinedOrderRepository>();

    final LocalPrintReceiptCacheRepository localPrintReceiptCacheRepository =
        ServiceLocator.get<LocalPrintReceiptCacheRepository>();

    // final dlsFacade = ServiceLocator.get<DeletedSaleItemFacade>();

    // await errorLogFacade.createAndInsertDummyErrorLog();

    // DeletedSaleItemModel dsi = DeletedSaleItemModel(
    //   // the one who delete the order
    //   id: IdUtils.generateUUID(),
    //   staffName: "userModel.name",
    //   orderNumber: "orderNumber",
    //   itemQuantity: "saleItem.quantity.toString()",
    //   itemTotalPrice: "20",
    //   itemPrice: "10",
    //   itemName: "getItemDetails(saleItem.itemId, ItemTypeDetails.name)",
    //   itemSku: "getItemDetails(saleItem.itemId, ItemTypeDetails.sku)",
    //   itemVariant: "saleItem.variantOptionJson ?? '{}'",
    //   itemModifiers: "await getItemModifiers(saleModel)",
    //   posDeviceName: "posDeviceModel.name",
    //   posDeviceCode: "posDeviceModel.code",
    //   outletName: outletModel?.name,
    //   outletId: outletModel?.id,
    //   companyId: staffModel.companyId,
    // );
    // await staffFacade.deleteStaffWhereIdNull();
    // await dlsFacade.insert(dsi);
    //await localPageItem.deleteAll();
    // final list =
    //     pageItemNotifier.getListPageItem
    //         .where((element) => element.sort == 5)
    //         .toList();
    // prints(list);
    await pendingChangesNotifier.deleteAll();
    await localPrintReceiptCacheRepository.deleteAll();

    // prints(await localPrintReceiptCacheRepository.tableExists());
    return;
    // await pageItemFacade.deleteCorruptPageItems();
    // await localSale.deleteSaleWhereStaffIdNull();
    // await localSaleItem.deleteSaleItemWhereStaffIdNull();
    // await saleFacade.deleteAll();
    // await saleItemFacade.deleteAll();
    // await saleModifierFacade.deleteAll();
    // await saleModifierOptionFacade.deleteAll();
    // await localPredefinedOrder.deleteAllCustomPO();
    // await localPredefinedOrder.unOccupiedAllNotCustom();
    // await localPredefinedOrder.deleteWhereIdIsNull();
    // await localTable.deleteAll();
  }

  Future<void> handleOnVoidOrder() async {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final saleItemNotifier = ref.watch(saleItemProvider.notifier);
    final customerNotifier = ref.read(customerProvider.notifier);
    bool hasPermissionManageOrder =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    bool hasPermissionVoidOrder =
        permissionNotifier.hasVoidSavedItemsInOpenOrderPermission();
    if (!hasPermissionManageOrder) {
      DialogUtils.showNoPermissionDialogue(context);
      return;
    }

    if (!hasPermissionVoidOrder) {
      await DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.VOID_SAVED_ITEMS_IN_OPEN_ORDER,
        onSuccess: () {
          hasPermissionVoidOrder = true;
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
      // DialogUtils.showNoPermissionDialogue(context);
    }
    // to avoid lag while transition
    if (hasPermissionManageOrder && hasPermissionVoidOrder) {
      await Future.delayed(Duration(milliseconds: 500));

      saleItemNotifier.clearOrderItems();
      saleItemNotifier.calcTotalAfterDiscountAndTax();
      saleItemNotifier.calcTaxAfterDiscount();
      saleItemNotifier.calcTotalDiscount();
      saleItemNotifier.calcTaxIncludedAfterDiscount();

      saleItemNotifier.setPredefinedOrderModel(PredefinedOrderModel());
      customerNotifier.setOrderCustomerModel(null);
      // reset selected table
      saleItemNotifier.setSelectedTable(TableModel());
      // await Future.delayed(Duration(milliseconds: 5000));
      await ref
          .read(saleProvider.notifier)
          .printVoidForSelectedDeletedOrders(
            onSuccess: (saleModel) async {
              prints('SUCCESS PRINT VOID ORDER TO DEPARTMENT PRINTER');
              await ref
                  .read(saleProvider.notifier)
                  .deleteSelectedOrders(saleModel, onSuccess: () async {});
            },
            onError: (message, ipAddress, saleModel) async {
              await ref
                  .read(saleProvider.notifier)
                  .deleteSelectedOrders(saleModel, onSuccess: () async {});
            },
          );
    }
  }

  Future<void> handleOnClearOrder() async {
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    final saleItemsState = ref.watch(saleItemProvider);
    final permissionNotifier = ref.read(permissionProvider.notifier);

    final currentSaleModel = saleItemsState.currSaleModel;
    final List<SaleItemModel> listSaleItems = saleItemsState.saleItems;

    final secondDisplay = ref.read(secondDisplayProvider.notifier);

    bool hasPermissionManageOrder =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    bool hasPermissionVoidOrder =
        permissionNotifier.hasVoidSavedItemsInOpenOrderPermission();

    // for first time order, just clear
    if (currentSaleModel?.id == null) {
      // means first time order,
      saleItemsNotifier.removeAllSaleItems();

      /// [SHOW SECOND DISPLAY] - Now fully optimized and non-blocking
      // Don't await this call to prevent blocking the UI thread
      // The facade handles all optimization internally and runs asynchronously
      await Future.delayed(const Duration(milliseconds: 200));
      secondDisplay.showMainCustomerDisplay();
      return;
    }
    // if open from open order list, just clear the items, make it voided, then will print void if press save
    // but still need to check permission
    if (currentSaleModel?.id != null) {
      // means the user is open the order from the open order list
      if (!hasPermissionManageOrder) {
        DialogUtils.showNoPermissionDialogue(context);
        return;
      }

      if (!hasPermissionVoidOrder) {
        await DialogUtils.showPinDialog(
          context,
          permission: PermissionEnum.VOID_SAVED_ITEMS_IN_OPEN_ORDER,
          onSuccess: () {
            hasPermissionVoidOrder = true;
          },
          onError: (error) {
            ThemeSnackBar.showSnackBar(context, error);
            return;
          },
        );
      }

      if (hasPermissionManageOrder && hasPermissionVoidOrder) {
        saleItemsNotifier.removeAllSaleItems();

        final itemsWithSaleId =
            listSaleItems
                .where((item) => item.saleId == currentSaleModel!.id)
                .toList();
        final itemsWithoutSaleId =
            listSaleItems.where((item) => item.saleId == null).toList();

        if (itemsWithSaleId.isNotEmpty) {
          await saleItemsNotifier.updateSaleItemsToClear(
            itemsWithSaleId,
            currentSaleModel!,
          );
        }

        if (itemsWithoutSaleId.isNotEmpty) {
          // Handle these items as needed
          prints('These items have no saleId: ${itemsWithoutSaleId.length}');
        }
        saleItemsNotifier.getMapDataToTransfer();

        /// [SHOW SECOND DISPLAY] - Now fully optimized and non-blocking
        // Don't await this call to prevent blocking the UI thread
        // The facade handles all optimization internally and runs asynchronously
        await Future.delayed(const Duration(milliseconds: 200));
        secondDisplay.showMainCustomerDisplay();
        return;
      }
    }

    // kalau dah clear item, then masukkan item baru

    prints('✅ Main customer display triggered - UI remains responsive!');
  }

  Expanded leftSideDefault(PageItemNotifier pageItemNotifier) {
    final saleItemsState = ref.watch(saleItemProvider);
    bool isEditMode = saleItemsState.isEditMode;
    return Expanded(
      flex: 5,
      child: Container(
        alignment: Alignment.center,
        child: Row(
          children: [
            SizedBox(width: 10.w),
            Visibility(
              visible: widget.action != null && widget.actionPress != null,
              child: Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: widget.actionPress,
                  icon: Icon(widget.action, color: kWhiteColor),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                widget.titleLeftSide,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kWhiteColor,
                ),
              ),
            ),
            isEditMode
                ? Container()
                : Expanded(
                  child: IconButton(
                    onPressed: () {
                      pageItemNotifier.setCurrentPageId(
                        PageEnum.pageSearchItem,
                      );
                    },
                    icon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: kWhiteColor,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Expanded leftSideSearch(
    PageItemNotifier pageItemNotifier,
    ItemNotifier itemNotifier,
  ) {
    return Expanded(
      flex: 5,
      child: Container(
        alignment: Alignment.center,
        child: Row(
          children: [
            SizedBox(width: 10.w),
            Expanded(
              flex: 1,
              child: IconButton(
                onPressed: () {
                  pageItemNotifier.setCurrentPageId(
                    pageItemNotifier.getLastPageId,
                  );

                  searchController.clear();
                  itemNotifier.setItemName('');
                },
                icon: const Icon(
                  FontAwesomeIcons.arrowLeft,
                  color: kWhiteColor,
                ),
              ),
            ),
            Consumer(
              builder: (context, ref, child) {
                final itemState = ref.watch(itemProvider);
                final itemNotifier = ref.read(itemProvider.notifier);
                if (itemState.searchItemName.isNotEmpty &&
                    searchController.text != itemState.searchItemName) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    searchController.text = itemState.searchItemName;
                    // Only clear the searchItemName from notifier, keep searchController text
                    itemNotifier.setSearchItemName('');
                  });
                  prints('BARCODE: ${itemState.itemName}');
                }
                return Expanded(
                  flex: 10,
                  child: MyTextFormField(
                    controller: searchController,
                    // onChanged: (value) {
                    //   itemNotifier.setItemName(value);
                    // },
                    style: AppTheme.normalTextStyle(
                      fontSize: 16.sp,
                      color: white,
                    ),
                    decoration: InputDecoration(
                      hintStyle: AppTheme.normalTextStyle(
                        fontSize: 16.sp,
                        color: kTextGray,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(
                          top: 20.h,
                          left: 10.w,
                          right: 10.w,
                          bottom: 20.h,
                        ),
                        child: const Icon(
                          FontAwesomeIcons.magnifyingGlass,
                          color: kBg,
                        ),
                      ),
                      prefixIconColor: kTextGray,
                      suffixIcon: ScaleTap(
                        onPressed: () {
                          searchController.clear();
                          itemNotifier.setItemName('');
                          itemNotifier.setSearchItemName('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Icon(
                            FontAwesomeIcons.xmark,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      suffixIconColor: kTextGray,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: canvasColor),
                        gapPadding: 10,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: canvasColor),
                        gapPadding: 10,
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: canvasColor),
                        gapPadding: 10,
                      ),
                      fillColor: canvasColor,
                      filled: true,
                      labelStyle: AppTheme.normalTextStyle(fontSize: 16),
                      // labelText: labelText,
                      hintText: 'search'.tr(),
                    ),

                    labelText: 'search'.tr(),
                    hintText: 'search'.tr(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onHandleEditOrder(PredefinedOrderModel currentPOM) async {
    final featureCompNotifier = ref.read(featureCompanyProvider.notifier);
    final permissionNotifier = ref.read(permissionProvider.notifier);

    if (!featureCompNotifier.isOpenOrdersActive()) {
      DialogUtils.showFeatureNotAvailable(context);
      return;
    }

    if (!permissionNotifier.hasManageAllOpenOrdersPermission()) {
      DialogUtils.showNoPermissionDialogue(context);
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return EditOrderDialogue(
          currentPOM: currentPOM,
          onErrorForm: (errorMessage) {
            // close the dialogue
            NavigationUtils.pop(context);
            ThemeSnackBar.showSnackBar(context, errorMessage);
          },
          onSuccessForm: (pom) async {
            // close the dialogue
            NavigationUtils.pop(context);
            await ref
                .read(saleProvider.notifier)
                .handleEditOrder(
                  updatedPOM: pom,
                  onError: (errorMessage) {
                    ThemeSnackBar.showSnackBar(context, errorMessage);
                  },
                  onSuccess: () {},
                );
          },
        );
      },
    );
  }

  Future<void> onAssignOrder(BuildContext context) async {
    final saleItemsState = ref.read(saleItemProvider);
    final currSaleModel = saleItemsState.currSaleModel;

    if (currSaleModel?.id == null) {
      return;
    }
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext contextDialogue) {
        return AssignOrderDialogue(currSaleModel: currSaleModel!);
      },
    );
  }

  Future<void> onForceSync(BuildContext context) async {
    await ref
        .read(syncRealTimeProvider.notifier)
        .onSyncOrder(
          context,
          mounted,
          isForce: true,
          needToDownloadImage: true,
          manuallyClick: true,
          onlyCheckPendingChanges: false,
          isAfterActivateLicense: false,
          isSuccess: (isSuccess, errorMessage) {},
        );
  }

  Future<void> onReprintPending(BuildContext context) async {
    await ref
        .read(printerSettingProvider.notifier)
        .onHandlePrintVoidAndKitchen(
          onSuccess: () {
            setState(() {});
          },
          onError: (message, ip) {},
          departmentType: null,
          onSuccessPrintReceiptCache: (listPRC) {},
          isRePrintPending: true,
        );
  }
}
