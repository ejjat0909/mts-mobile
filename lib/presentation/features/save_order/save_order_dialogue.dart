import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/department_type_enum.dart';
import 'package:mts/core/enums/inventory_transaction_type_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/skeleton_card.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/save_order/components/predefined_order_item.dart';
import 'package:mts/presentation/features/save_order/components/save_order_custom.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';

import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/table/table_providers.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/error_log/error_log_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';

class SaveOrderDialogue extends ConsumerStatefulWidget {
  final Function(String message) onPrintError;
  final Function(List<PrintReceiptCacheModel> listPRC)
  onCallbackPrintReceiptCache;

  const SaveOrderDialogue({
    super.key,
    required this.onPrintError,
    required this.onCallbackPrintReceiptCache,
  });

  @override
  ConsumerState<SaveOrderDialogue> createState() => _SaveOrderDialogueState();
}

class _SaveOrderDialogueState extends ConsumerState<SaveOrderDialogue> {
  List<PredefinedOrderModel> filteredPredefinedOrder = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  OutletModel outletModel = GetIt.instance<OutletModel>();
  StaffModel staffModel = ServiceLocator.get<StaffModel>();
  UserModel userModel = ServiceLocator.get<UserModel>();
  ModifierNotifier get _modifierNotifier => ref.read(modifierProvider.notifier);
  PredefinedOrderNotifier get _predefinedOrderNotifier =>
      ref.read(predefinedOrderProvider.notifier);
  PrinterSettingNotifier get _printerSettingNotifier =>
      ref.read(printerSettingProvider.notifier);
  SaleNotifier get _saleNotifier => ref.read(saleProvider.notifier);
  SaleItemNotifier get _saleItemNotifier => ref.read(saleItemProvider.notifier);
  SaleModifierNotifier get _saleModifierNotifier =>
      ref.read(saleModifierProvider.notifier);
  SaleModifierOptionNotifier get _saleModifierOptionNotifier =>
      ref.read(saleModifierOptionProvider.notifier);
  InventoryNotifier get _inventoryNotifier =>
      ref.read(inventoryProvider.notifier);
  TableNotifier get _tableNotifier => ref.read(tableProvider.notifier);
  PrintReceiptCacheNotifier get _printReceiptCacheNotifier =>
      ref.read(printReceiptCacheProvider.notifier);
  OutletNotifier get _outletNotifier => ref.read(outletProvider.notifier);
  ErrorLogNotifier get _errorLogNotifier => ref.read(errorLogProvider.notifier);
  SecondDisplayNotifier get _secondaryDisplayNotifier =>
      ref.read(secondDisplayProvider.notifier);

  List<PredefinedOrderModel> listPredefinedOrder = [];

  bool isLoadingList = false;

  void _filterOrderOptions(String query) {
    setState(() {
      searchQuery = query;
      filteredPredefinedOrder =
          listPredefinedOrder.where((orderOption) {
            final nameMatch =
                orderOption.name?.toLowerCase().contains(query.toLowerCase()) ??
                false;
            final tableNameMatch =
                orderOption.tableName?.toLowerCase() == query.toLowerCase();
            return nameMatch || tableNameMatch;
          }).toList();
    });
  }

  void _onSearchChanged() {
    _filterOrderOptions(searchController.text);
  }

  Future<void> getPredefinedOrder() async {
    final dialogueNav = ref.read(dialogNavigatorProvider.notifier);

    listPredefinedOrder =
        await _predefinedOrderNotifier.getListPredefinedOrderWhereOccupied0();

    filteredPredefinedOrder = listPredefinedOrder;
    if (filteredPredefinedOrder.isEmpty) {
      dialogueNav.setPageIndex(DialogNavigatorEnum.customOrder);
    }

    // dah setState(() {}) dalam init
  }

  @override
  void initState() {
    super.initState();
    // _barcodeScannerNotifier.initialize();
    ref.read(barcodeScannerProvider.notifier).initializeForSaveOrderDialogue();

    // Add listener to search controller
    searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // put delay sikit untuk handle transistion masa open popup
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        isLoadingList = true;
      });
      await initData();
      setState(() {
        isLoadingList = false;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    // Remove listener and dispose controller
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();

    // Reinitialize to sales screen when dialog closes
    ref.read(barcodeScannerProvider.notifier).reinitializeToSalesScreen();

    super.dispose();
  }

  Future<void> initData() async {
    await getPredefinedOrder();
  }

  @override
  Widget build(BuildContext saveOrderContext) {
    final scannerNotifier = ref.read(barcodeScannerProvider.notifier);
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    final hasPermissionManageOrders =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    final featureCompNotifier = ref.watch(featureCompanyProvider.notifier);
    final outletModel = ServiceLocator.get<OutletModel>();
    final isFeatureActive = featureCompNotifier.isOpenOrdersActive();
    double availableHeight = MediaQuery.of(saveOrderContext).size.height;
    double availableWidth = MediaQuery.of(saveOrderContext).size.width;
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    final dialogNavigator = ref.read(dialogNavigatorProvider.notifier);

    int pageIndex = dialogNavigator.getPageIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scannerNotifier.saveOrderDialogueBarcode != null &&
          scannerNotifier.saveOrderDialogueBarcode!.isNotEmpty) {
        searchController.text = scannerNotifier.saveOrderDialogueBarcode!;
        scannerNotifier.clearScannedItem();
      }
    });
    if (!hasPermissionManageOrders) {
      return SaveOrderCustomDialogue(
        onSuccess: () {},
        onError: widget.onPrintError,
        onCallbackPrintReceiptCache: widget.onCallbackPrintReceiptCache,
        listPredefinedOrder: filteredPredefinedOrder.length,
      );
    } else if (outletModel.isEnabledOpenOrder != null &&
        !outletModel.isEnabledOpenOrder!) {
      return SaveOrderCustomDialogue(
        onSuccess: () {},
        onError: widget.onPrintError,
        onCallbackPrintReceiptCache: widget.onCallbackPrintReceiptCache,
        listPredefinedOrder: filteredPredefinedOrder.length,
      );
    } else if (pageIndex == DialogNavigatorEnum.saveOrder) {
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: availableHeight,
            minHeight: availableHeight,
            maxWidth: availableWidth / 2,
            minWidth: availableWidth / 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Space(10),
              AppBar(
                elevation: 0,
                backgroundColor: white,
                title: Row(
                  children: [
                    Text('saveOrder'.tr(), style: AppTheme.h1TextStyle()),
                    const Expanded(flex: 2, child: SizedBox()),
                    isFeatureActive
                        ? Expanded(
                          flex: 1,
                          child: ButtonTertiary(
                            text: 'customOrder'.tr(),
                            icon: FontAwesomeIcons.pencil,
                            onPressed: () {
                              setState(() {
                                dialogNavigator.setPageIndex(
                                  DialogNavigatorEnum.customOrder,
                                );
                              });
                            },
                          ),
                        )
                        : SizedBox.shrink(),
                  ],
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: canvasColor),
                  onPressed: () async {
                    Navigator.of(context).pop();

                    dialogNavigator.setPageIndex(DialogNavigatorEnum.reset);
                  },
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top section with padding
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          MyTextFormField(
                            controller: searchController,
                            labelText: 'search'.tr(),
                            hintText: 'search'.tr(),
                            leading: Padding(
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
                          ),
                          const Divider(),
                          Text(
                            'recentOrders'.tr(),
                            style: AppTheme.mediumTextStyle(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    // List section WITHOUT horizontal padding
                    Expanded(
                      child:
                          isLoadingList
                              ? const SkeletonCard()
                              : ListView.builder(
                                padding: EdgeInsets.zero, // <- important
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredPredefinedOrder.length,
                                itemBuilder: (context, index) {
                                  return PredefinedOrderItem(
                                    index: index,
                                    tableName:
                                        filteredPredefinedOrder[index]
                                            .tableName,
                                    predefinedOrderModel:
                                        filteredPredefinedOrder[index],
                                    press: () async {
                                      await saveOrderIntoPredefinedOrder(
                                        saveOrderContext,
                                        index,
                                        saleItemsState,
                                        saleItemsNotifier,
                                      );
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (pageIndex == DialogNavigatorEnum.customOrder) {
      return SaveOrderCustomDialogue(
        onSuccess: () {},
        onError: widget.onPrintError,
        onCallbackPrintReceiptCache: widget.onCallbackPrintReceiptCache,
        listPredefinedOrder: filteredPredefinedOrder.length,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<void> saveOrderIntoPredefinedOrder(
    BuildContext contextSaveOrder,
    int index,
    SaleItemState saleItemsState,
    SaleItemNotifier saleItemsNotifier,
  ) async {
    if (staffModel.id == null) {
      String message = "Staff id is null, cannot create staff";
      // rare case
      ThemeSnackBar.showSnackBar(context, message);

      _errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }

    if (staffModel.userId != userModel.id) {
      String message = "User id is conflict with staff";
      // rare case
      ThemeSnackBar.showSnackBar(context, message);
      _errorLogNotifier.createAndInsertErrorLog(message);
      return;
    }
    // get total price

    // CLOSE SAVE ORDER DIALOGUE THEN DO THE BACKEND THINGS
    NavigationUtils.pop(contextSaveOrder);

    double totalPrice = saleItemsState.totalAfterDiscountAndTax;

    List<SaleItemModel> listSaleItems = saleItemsState.saleItems;
    List<SaleItemModel> newListSaleItems = [];

    List<SaleModifierModel> listSaleModifierModels =
        saleItemsState.saleModifiers;
    List<SaleModifierModel> newListSM = [];

    List<SaleModifierOptionModel> listSaleModifierOptionModels =
        saleItemsState.saleModifierOptions;
    List<SaleModifierOptionModel> newListSMO = [];
    String newSaleId = IdUtils.generateUUID();

    // last step, clear the order sale item in the notifier
    saleItemsNotifier.clearOrderItems();
    saleItemsNotifier.calcTotalAfterDiscountAndTax();
    saleItemsNotifier.calcTaxAfterDiscount();
    saleItemsNotifier.calcTaxIncludedAfterDiscount();
    saleItemsNotifier.calcTotalDiscount();

    List<String> listJson = [];
    if (listSaleItems.isNotEmpty) {
      for (SaleItemModel saleItemModel in listSaleItems) {
        String newSaleItemId = IdUtils.generateUUID();

        // get the sale modifier list by sale item id to get the id
        List<SaleModifierModel> listSM =
            listSaleModifierModels
                .where((element) => element.saleItemId == saleItemModel.id)
                .toList();

        if (listSM.isNotEmpty) {
          for (var currSM in listSM) {
            List<SaleModifierOptionModel> listSMO =
                listSaleModifierOptionModels
                    .where((element) => element.saleModifierId == currSM.id)
                    .toList();
            SaleModifierModel newSM = currSM.copyWith(
              saleItemId: newSaleItemId,
              saleModifierOptionCount: listSMO.length,
            );
            newListSM.add(newSM);
            if (listSMO.isNotEmpty) {
              for (var currSMO in listSMO) {
                SaleModifierOptionModel newSMO = currSMO.copyWith(
                  saleModifierId: currSM.id,
                );
                newListSMO.add(newSMO);
              }
            }
          }
        }

        String modifierJson = await _modifierNotifier.convertListModifierToJson(
          saleItemModel,
          listSaleModifierModels,
          listSaleModifierOptionModels,
        );
        listJson.add(modifierJson);

        // generate new to avoid duplicate from list in notifier
        SaleItemModel newSaleItemModel = saleItemModel.copyWith(
          id: newSaleItemId,
          saleId: newSaleId,
          isVoided: false,
          saleModifierCount: listSM.length,
          // isPrintedKitchen: false,
          // isPrintedVoided: false,
        );

        newListSaleItems.add(newSaleItemModel);
      }
    }

    // update running number
    int latestRunningNumber = 1;
    await _outletNotifier.incrementNextOrderNumber(
      onRunningNumber: (runningNumber) {
        latestRunningNumber = runningNumber;
      },
    );

    // generate new sale model for every each sale item
    // generate new sale model
    SaleModel newSaleModel = SaleModel(
      id: newSaleId,
      staffId: staffModel.id,
      outletId: outletModel.id,
      tableId: filteredPredefinedOrder[index].tableId,
      tableName: filteredPredefinedOrder[index].tableName,
      predefinedOrderId: filteredPredefinedOrder[index].id,
      name: filteredPredefinedOrder[index].name,
      remarks: filteredPredefinedOrder[index].remarks,
      totalPrice: double.parse(totalPrice.toStringAsFixed(2)),
      runningNumber: latestRunningNumber,
      orderOptionId: saleItemsState.orderOptionModel?.id,
      saleItemCount: newListSaleItems.length,
    );
    final CustomerModel? customerModel =
        ref.read(customerProvider.notifier).getOrderCustomerModel;
    // reset current attached customer
    ref.read(customerProvider.notifier).setOrderCustomerModel(null);

    await _printReceiptCacheNotifier.insertDetailsPrintCache(
      saleModel: newSaleModel,
      listSaleItemModel: newListSaleItems,
      listSM: newListSM,
      listSMO: newListSMO,
      orderOptionModel: saleItemsState.orderOptionModel!,
      pom: filteredPredefinedOrder[index],
      printType: DepartmentTypeEnum.printKitchen,
      isForThisDevice: true,
    );
    await attemptPrintKitchen(
      newSaleModel,
      isPrintAgain: false,
      isFromLocal: true,
      onSuccessPrintReceiptCache: (listPRC) {},
    );

    /// [SHOW SECOND DISPLAY]
    // Don't await this call to prevent blocking the UI thread
    _secondaryDisplayNotifier.showMainCustomerDisplay();

    await _printReceiptCacheNotifier.insertDetailsPrintCache(
      saleModel: newSaleModel,
      listSaleItemModel: newListSaleItems,
      listSM: newListSM,
      listSMO: newListSMO,
      orderOptionModel: saleItemsState.orderOptionModel!,
      pom: filteredPredefinedOrder[index],
      printType: DepartmentTypeEnum.printKitchen,
      isForThisDevice: false,
    );
    // Run these independent DB writes in parallel to improve throughput
    await _saleNotifier.insert(newSaleModel);

    await Future.wait([
      ...newListSaleItems.map((e) => _saleItemNotifier.insert(e)),
      ...newListSM.map((e) => _saleModifierNotifier.insert(e)),
      ...newListSMO.map((e) => _saleModifierOptionNotifier.insert(e)),
      _predefinedOrderNotifier.makeIsOccupied(
        filteredPredefinedOrder[index].id!,
      ),
    ]);
    //link to table if exists
    if (filteredPredefinedOrder[index].tableId != null) {
      // get table from db
      TableModel? tableModel = await _tableNotifier.getTableModelById(
        filteredPredefinedOrder[index].tableId!,
      );

      await ref
          .read(tableLayoutProvider.notifier)
          .updateTableById(
            filteredPredefinedOrder[index].tableId!,
            predefinedOrderId: filteredPredefinedOrder[index].id,
            saleId: newSaleId,
            staffId: staffModel.id,
            status: TableStatusEnum.OCCUPIED,
            customerId: customerModel?.id,
          );
    }

    await _inventoryNotifier.updateInventoryInSaleItem(
      newListSaleItems,
      InventoryTransactionTypeEnum.stockOut,
    );
  }

  Future<void> attemptPrintKitchen(
    SaleModel saleModel, {
    required bool isPrintAgain,
    required bool isFromLocal,
    required Function(List<PrintReceiptCacheModel>) onSuccessPrintReceiptCache,
  }) async {
    PrintReceiptCacheModel prcModel = PrintReceiptCacheModel();
    // print kitchen
    await _printerSettingNotifier.onHandlePrintVoidAndKitchen(
      onSuccessPrintReceiptCache: (listPRC) {
        onSuccessPrintReceiptCache(listPRC);

        // to handle print error because we also pass the callback when onError
        // why first? because we only have one prc when print kitchen
        if (listPRC.isNotEmpty) {
          prcModel = listPRC.first;
        }
      },
      departmentType: DepartmentTypeEnum.printKitchen,
      onSuccess: () {
        prints(
          '🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳🥳SUCCESS PRINT PREDEFINED ORDER TO DEPARTMENT PRINTER',
        );
      },
      onError: (message, ipAddress) {
        prints('MESSAGE PRINT KITCHEN: $message');
        prints('IP ADDRESS PRINT KITCHEN: $ipAddress');
        if (message == '-1') {
          // printerNotAvailableDialogue(context, 'noPrinterAvailable'.tr(),
          //     'pleaseAddPrinterToPrint'.tr());
          return;
        }

        /// [CLIENT TANAK SHOW BILA ADA ERROR]
        /// [CLIENT KATA NAK ADA BALIK] 5 december 2025 guna mulut
        final globalContext = navigatorKey.currentContext;
        if (globalContext == null) {
          return;
        }

        CustomDialog.show(
          navigatorKey.currentContext!,
          dialogType: DialogType.danger,
          icon: FontAwesomeIcons.print,
          title: message,
          description:
              "${'pleaseCheckYourPrinterWithIP'.tr()} $ipAddress \n ${'doYouWantToPrintAgain'.tr()}",
          btnCancelText: 'cancel'.tr(),
          btnCancelOnPress: () {
            NavigationUtils.pop(navigatorKey.currentContext!);
          },
          btnOkText: 'printAgain'.tr(),
          btnOkOnPress: () async {
            // close error dialogue
            NavigationUtils.pop(navigatorKey.currentContext!);

            if (prcModel.id != null) {
              SaleModel modelSale =
                  prcModel.printData?.saleModel ?? SaleModel();
              List<SaleItemModel> listSI =
                  prcModel.printData?.listSaleItems ?? [];
              List<SaleModifierModel> listSM = prcModel.printData?.listSM ?? [];
              List<SaleModifierOptionModel> listSMO =
                  prcModel.printData?.listSMO ?? [];
              OrderOptionModel orderOptionModel =
                  prcModel.printData?.orderOptionModel ?? OrderOptionModel();

              PredefinedOrderModel predefinedOrderModel =
                  prcModel.printData?.predefinedOrderModel ??
                  PredefinedOrderModel();

              await _printReceiptCacheNotifier.insertDetailsPrintCache(
                saleModel: modelSale,
                listSaleItemModel: listSI,
                listSM: listSM,
                listSMO: listSMO,
                orderOptionModel: orderOptionModel,
                pom: predefinedOrderModel,
                printType: DepartmentTypeEnum.printKitchen,
                isForThisDevice: true,
              );

              // use back this function
              await attemptPrintKitchen(
                saleModel,
                isPrintAgain: true,
                isFromLocal: true,
                onSuccessPrintReceiptCache: onSuccessPrintReceiptCache,
              );
            } else {
              ThemeSnackBar.showSnackBar(
                navigatorKey.currentContext!,
                "Please open the order and reprint the order.",
              );
            }
          },
        );
      },
    );
  }
}
