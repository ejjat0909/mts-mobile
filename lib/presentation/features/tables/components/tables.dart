import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/enum/table_type_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/core/services/secondary_display_service.dart';
import 'package:mts/main.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/layouts/colored_safe_area.dart';
import 'package:mts/presentation/features/assign_order_table/assign_order_table_dialogue.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/presentation/features/payment/payment_screen.dart';
import 'package:mts/presentation/features/tables/components/charge_detail.dart';
import 'package:mts/presentation/features/tables/components/circular_table.dart';
import 'package:mts/presentation/features/tables/components/line_horizontal.dart';
import 'package:mts/presentation/features/tables/components/line_vertical.dart';
import 'package:mts/presentation/features/tables/components/rectangle_horizontal.dart';
import 'package:mts/presentation/features/tables/components/rectangle_vertical.dart';
import 'package:mts/presentation/features/tables/components/square_table.dart';
import 'package:mts/presentation/features/tables/components/table_occupied_dialog.dart';
import 'package:mts/presentation/features/tables/components/table_unoccupied_dialog.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/payment/payment_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';

class Tables extends ConsumerStatefulWidget {
  final TableSectionModel sectionModel;

  const Tables({super.key, required this.sectionModel});

  @override
  ConsumerState<Tables> createState() => _TablesState();
}

class _TablesState extends ConsumerState<Tables> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Reinitialize to sales screen when tables screen closes
    ref.read(barcodeScannerProvider.notifier).reinitializeToSalesScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    final hasPermissionManageOrders =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    final tableLayoutState = ref.watch(tableLayoutProvider);

    if (widget.sectionModel.id != null) {
      // Get tables for current section
      final listTablesModel =
          tableLayoutState.tableList.where((table) {
            return table.tableSectionId == widget.sectionModel.id;
          }).toList();
      final screenWidth = 1194.w;
      return ColoredSafeArea(
        width: screenWidth,
        color: kBg,
        child: Stack(
          children: List.generate(listTablesModel.length, (index) {
            TableModel tableModel = listTablesModel[index];
            return Positioned(
              left: tableModel.left,
              top: tableModel.top,
              child: GestureDetector(
                onTap: () async {
                  //   ref.read(barcodeScannerProvider.notifier).initialize();
                  ref
                      .read(barcodeScannerProvider.notifier)
                      .initializeForTables();
                  bool canShowDialog = ref
                      .read(tableLayoutProvider.notifier)
                      .tableShapeCanEdit(tableModel);

                  String? openOrderName;
                  if (tableModel.predefinedOrderId != null) {
                    openOrderName = await ref
                        .read(predefinedOrderProvider.notifier)
                        .getPredefinedOrderById(tableModel.predefinedOrderId)
                        .then((value) => value?.name);
                  }

                  prints("OpenORderName : $openOrderName");

                  if (mounted) {
                    // not occupied
                    tableModel.status == TableStatusEnum.UNOCCUPIED
                        ? ((canShowDialog)
                            ? TableUnoccupiedDialog.show(
                              context,
                              tableModel: tableModel,
                              openOrderName: openOrderName,
                              hasPermissionManageOrders:
                                  hasPermissionManageOrders,
                              onPressOrder: () {
                                final currentListSaleItems = ref.watch(
                                  saleItemsListProvider,
                                );

                                if (currentListSaleItems.isEmpty) {
                                  // close dialogue
                                  NavigationUtils.pop(context);
                                  // go back to sales screen
                                  NavigationUtils.pop(context, tableModel);
                                } else {
                                  DialogUtils.showUnSavedOrderDialogue(context);
                                }
                              },
                              onAssignOrder: () {
                                // NavigationUtils.pop(context);
                                showDialogueAssignOrder(tableModel, context);
                              },
                            )
                            : null)
                        //Click not ordered table will access order page
                        : tableModel.status == TableStatusEnum.OCCUPIED
                        ? ((canShowDialog)
                            ? TableOccupiedDialog.show(
                              context,

                              headerTitle: tableModel.name ?? 'Table',
                              //Ordered table will show charge details
                              content: ChargeDetail(
                                tableModel: tableModel,
                                staffId: tableModel.staffId ?? '',
                                customerId: tableModel.customerId ?? '',
                                saleId: tableModel.saleId ?? '',
                              ),
                              footerTitle: 'Charge',
                              saveAction:
                                  () => _onPressCharge(
                                    tableModel,
                                    saleItemsNotifier,
                                  ),
                              editOrderAction:
                                  () => _onPressEditOrder(tableModel),
                            )
                            : ThemeSnackBar.showSnackBar(
                              navigatorKey.currentContext!,
                              "Error -1",
                            ))
                        : null;
                  }
                },

                child: getTableShape(listTablesModel[index]),
              ),
            );
          }),
        ),
      );
    }
    return const Center(child: Text('Please choose section'));
  }

  Widget getTableShape(TableModel tableModel) {
    switch (tableModel.type) {
      case TableTypeEnum.SQUARE:
        return SquareTable(
          tableModel: tableModel,
          status: tableModel.status,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.CIRCLE:
        return CircularTable(
          tableModel: tableModel,
          status: tableModel.status,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.RECTANGLEVERTICAL:
        return RectangleVertical(
          tableModel: tableModel,
          status: tableModel.status,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.RECTANGLEHORIZONTAL:
        return RectangleHorizontal(
          tableModel: tableModel,
          status: tableModel.status,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.LINEHORIZONTAL:
        return LineHorizontal(
          tableModel: tableModel,
          status: tableModel.status,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.LINEVERTICAL:
        return LineVertical(
          tableModel: tableModel,
          status: tableModel.status,
          seats: tableModel.seats?.toString(),
        );
      default:
        return Container();
    }
  }

  void _onPressEditOrder(TableModel tableModel) async {
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);
    final customerNotifier = ref.read(customerProvider.notifier);

    // if (!permissionNotifier.hasManageAllOpenOrdersPermission()) {
    //   DialogUtils.showNoPermissionDialogue(context);
    //   return;
    // }
    // close dialogue
    NavigationUtils.pop(context);
    // go back to sales screen
    NavigationUtils.pop(context);
    // avoid lag while transition to go back
    await Future.delayed(const Duration(milliseconds: 300));
    // get predefined order

    // get customer from local db
    final CustomerModel customerModel = customerNotifier.getCustomerById(
      tableModel.customerId,
    );
    // get predefined order
    final PredefinedOrderModel? po = await ref
        .read(predefinedOrderProvider.notifier)
        .getPredefinedOrderById(tableModel.predefinedOrderId);
    // get sale model
    final SaleModel? currSaleModel = await ref
        .read(saleProvider.notifier)
        .getSaleModelBySaleId(tableModel.saleId ?? '');

    List<SaleItemModel> listSaleItem = await ref
        .read(saleItemProvider.notifier)
        .getListSaleItemByPredefinedOrderId(
          tableModel.predefinedOrderId ?? '',
          isVoided: false,
          isPrintedKitchen: null,
          categoryIds: [],
        );
    prints('list sale item $listSaleItem');
    List<SaleModifierModel> saleModifiers = await ref
        .read(saleModifierProvider.notifier)
        .getListSaleModifiersByPredefinedOrderId(
          tableModel.predefinedOrderId ?? '',
          categoryIds: [],
        );

    List<SaleModifierOptionModel> saleModifierOptions = await ref
        .read(saleModifierOptionProvider.notifier)
        .getListSaleModifierOptionsByPredefinedOrderId(
          tableModel.predefinedOrderId ?? '',
          categoryIds: [],
        );

    List<Map<String, dynamic>> listTotalDiscount = [];
    List<Map<String, dynamic>> listTaxAfterDiscount = [];
    List<Map<String, dynamic>> listTaxIncludedAfterDiscount = [];
    List<Map<String, dynamic>> listTotalAfterDiscountAndTax = [];

    for (SaleItemModel saleItem in listSaleItem) {
      Map<String, dynamic> mapTotalAfterDiscountAndTax = {
        'totalAfterDiscAndTax': saleItem.totalAfterDiscAndTax,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };

      listTotalAfterDiscountAndTax.add(mapTotalAfterDiscountAndTax);

      Map<String, dynamic> mapTaxIncludedAfterDiscount = {
        'taxIncludedAfterDiscount': saleItem.taxIncludedAfterDiscount,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTaxIncludedAfterDiscount.add(mapTaxIncludedAfterDiscount);

      Map<String, dynamic> mapTaxAfterDiscount = {
        'taxAfterDiscount': saleItem.taxAfterDiscount,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTaxAfterDiscount.add(mapTaxAfterDiscount);

      Map<String, dynamic> mapDiscountTotal = {
        'discountTotal': saleItem.discountTotal,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTotalDiscount.add(mapDiscountTotal);
    }
    saleItemsNotifier.setSaleItems(listSaleItem);
    saleItemsNotifier.setSaleModifiers(saleModifiers);
    saleItemsNotifier.setSaleModifierOptions(saleModifierOptions);
    saleItemsNotifier.setSelectedTable(tableModel);
    saleItemsNotifier.setPredefinedOrderModel(po ?? PredefinedOrderModel());

    saleItemsNotifier.setCurrSaleModel(currSaleModel ?? SaleModel());

    customerNotifier.setOrderCustomerModel(customerModel);

    saleItemsNotifier.setListTotalAfterDiscountAndTax(
      listTotalAfterDiscountAndTax,
    );

    saleItemsNotifier.setListTaxAfterDiscount(listTaxAfterDiscount);
    saleItemsNotifier.setListTaxIncludedAfterDiscount(
      listTaxIncludedAfterDiscount,
    );

    saleItemsNotifier.setListTotalDiscount(listTotalDiscount);

    // calculate all
    saleItemsNotifier.calcTotalAfterDiscountAndTax();
    saleItemsNotifier.calcTaxAfterDiscount();
    saleItemsNotifier.calcTaxIncludedAfterDiscount();
    saleItemsNotifier.calcTotalDiscount();
    // get all the data

    Map<String, dynamic> dataToTransfer =
        saleItemsNotifier.getMapDataToTransfer();

    /// [SHOW SECOND DISPLAY]
    await _showOptimizedSecondDisplay(dataToTransfer);
  }

  void _onPressCharge(
    TableModel tableModel,
    SaleItemNotifier saleItemsNotifier,
  ) async {
    final paymentNotifier = ref.read(paymentProvider.notifier);
    final customerNotifier = ref.read(customerProvider.notifier);
    final permissionNotifier = ref.read(permissionProvider.notifier);

    if (!permissionNotifier.hasAcceptPaymentPermission()) {
      DialogUtils.showNoPermissionDialogue(context);
      return;
    }
    // get customer from local db
    final CustomerModel customerModel = customerNotifier.getCustomerById(
      tableModel.customerId,
    );
    //go to charge page

    // get predefined order
    final PredefinedOrderModel? po = await ref
        .read(predefinedOrderProvider.notifier)
        .getPredefinedOrderById(tableModel.predefinedOrderId);

    List<SaleItemModel> listSaleItem = await ref
        .read(saleItemProvider.notifier)
        .getListSaleItemByPredefinedOrderId(
          tableModel.predefinedOrderId ?? '',
          isVoided: false,
          isPrintedKitchen: null,
          categoryIds: [],
        );
    List<SaleModifierModel> saleModifiers = await ref
        .read(saleModifierProvider.notifier)
        .getListSaleModifiersByPredefinedOrderId(
          tableModel.predefinedOrderId ?? '',
          categoryIds: [],
        );

    List<SaleModifierOptionModel> saleModifierOptions = await ref
        .read(saleModifierOptionProvider.notifier)
        .getListSaleModifierOptionsByPredefinedOrderId(
          tableModel.predefinedOrderId ?? '',
          categoryIds: [],
        );

    List<Map<String, dynamic>> listTotalDiscount = [];
    List<Map<String, dynamic>> listTaxAfterDiscount = [];
    List<Map<String, dynamic>> listTaxIncludedAfterDiscount = [];
    List<Map<String, dynamic>> listTotalAfterDiscountAndTax = [];

    for (SaleItemModel saleItem in listSaleItem) {
      Map<String, dynamic> mapTotalAfterDiscountAndTax = {
        'totalAfterDiscAndTax': saleItem.totalAfterDiscAndTax,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };

      listTotalAfterDiscountAndTax.add(mapTotalAfterDiscountAndTax);

      Map<String, dynamic> mapTaxIncludedAfterDiscount = {
        'taxIncludedAfterDiscount': saleItem.taxIncludedAfterDiscount,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTaxIncludedAfterDiscount.add(mapTaxIncludedAfterDiscount);

      Map<String, dynamic> mapTaxAfterDiscount = {
        'taxAfterDiscount': saleItem.taxAfterDiscount,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTaxAfterDiscount.add(mapTaxAfterDiscount);

      Map<String, dynamic> mapDiscountTotal = {
        'discountTotal': saleItem.discountTotal,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTotalDiscount.add(mapDiscountTotal);
    }

    saleItemsNotifier.setSaleItems(listSaleItem);
    saleItemsNotifier.setSaleModifiers(saleModifiers);

    saleItemsNotifier.setListTotalAfterDiscountAndTax(
      listTotalAfterDiscountAndTax,
    );

    saleItemsNotifier.setListTaxAfterDiscount(listTaxAfterDiscount);
    saleItemsNotifier.setListTaxIncludedAfterDiscount(
      listTaxIncludedAfterDiscount,
    );
    saleItemsNotifier.setListTotalDiscount(listTotalDiscount);
    saleItemsNotifier.setSaleModifierOptions(saleModifierOptions);

    // calculate all
    saleItemsNotifier.calcTotalAfterDiscountAndTax();
    saleItemsNotifier.calcTaxAfterDiscount();
    saleItemsNotifier.calcTaxIncludedAfterDiscount();
    saleItemsNotifier.calcTotalDiscount();

    // set can go back to sales page
    saleItemsNotifier.setCanBackToSalesPage(true);
    saleItemsNotifier.setIsSplitPayment(false);

    SaleModel? saleModel = await ref
        .read(saleProvider.notifier)
        .getSaleModelBySaleId(tableModel.saleId ?? '');

    //set  current sale model
    SaleModel updatedSaleModel = SaleModel();
    final totalAfterDiscountAndTax = ref.watch(
      saleItemProvider.select((state) => state.totalAfterDiscountAndTax),
    );
    updatedSaleModel =
        saleModel?.copyWith(totalPrice: totalAfterDiscountAndTax) ??
        SaleModel();

    // because in the app bar sales, the icons check whether the customer is null or not
    customerNotifier.setOrderCustomerModel(
      customerModel.id == null ? null : customerModel,
    );
    saleItemsNotifier.setCurrSaleModel(updatedSaleModel);
    saleItemsNotifier.setSelectedTable(tableModel);
    saleItemsNotifier.setPredefinedOrderModel(po ?? PredefinedOrderModel());
    if (listSaleItem.isNotEmpty) {
      // close the dialogue
      NavigationUtils.pop(context);
      Navigator.push(
        context,
        NavigationUtils.createRoute(
          newScreen: PaymentScreen(orderListContext: context),
        ),
      );
      paymentNotifier.setChangeToPaymentScreen(true);
      saleItemsNotifier.calcTotalWithAdjustedPrice();
    } else {
      ThemeSnackBar.showSnackBar(context, 'noItem'.tr());
    }
  }

  /// Helper method to optimize data transfer to second display
  Future<void> _showOptimizedSecondDisplay(
    Map<String, dynamic> dataToTransfer,
  ) async {
    if (!mounted) return;

    // Get slideshow model
    SlideshowModel? currSdModel = await ref
        .read(slideshowProvider.notifier)
        .getLatestModel()
        .then((value) => value[DbResponseEnum.data]);

    // Get user model from providers
    final userModel = GetIt.instance<UserModel>();

    // Get current route name from second display provider
    final String currRouteName = ref.watch(
      secondDisplayCurrentRouteNameProvider,
    );

    // Create a lightweight data package with essential information
    Map<String, dynamic> data = {
      // Add a unique update ID to track this update
      DataEnum.cartUpdateId: IdUtils.generateUUID(),
      // Add user model and slideshow data
      DataEnum.userModel: userModel.toJson(),
      DataEnum.slideshow: currSdModel?.toJson() ?? {},
      DataEnum.showThankYou: false,
      DataEnum.isCharged: false,
    };

    // Add data from the original dataToTransfer
    dataToTransfer.forEach((key, value) {
      if (!data.containsKey(key)) {
        data[key] = value;
      }
    });

    // Use the optimized update method for the second display
    await _updateSecondaryDisplay(data, currRouteName);
  }

  /// Optimized method to update the second display without full navigation
  Future<void> _updateSecondaryDisplay(
    Map<String, dynamic> data,
    String currRouteName,
  ) async {
    if (currRouteName != CustomerShowReceipt.routeName) {
      // If we're not already on the receipt screen, do a full navigation
      final secondaryDisplayService =
          ServiceLocator.get<SecondaryDisplayService>();
      await secondaryDisplayService.navigateSecondScreen(
        CustomerShowReceipt.routeName,
        displayManager,
        data: data,
        isShowLoading: true,
      );
    } else {
      // If we're already on the receipt screen, use the optimized update method
      // This is much faster than doing a full navigation
      try {
        final secondaryDisplayService =
            ServiceLocator.get<SecondaryDisplayService>();
        await secondaryDisplayService.updateSecondaryDisplay(
          displayManager,
          data,
        );
      } catch (e) {
        prints('Error updating second display: $e');
        // Fall back to full navigation if the update fails
        final secondaryDisplayService =
            ServiceLocator.get<SecondaryDisplayService>();
        await secondaryDisplayService.navigateSecondScreen(
          CustomerShowReceipt.routeName,
          displayManager,
          data: data,
          isShowLoading: true,
        );
      }
    }
  }

  void showDialogueAssignOrder(TableModel tableModel, BuildContext context) {
    NavigationUtils.pop(context);
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return AssignOrderTableDialogue(tableModel: tableModel);
      },
    );
  }
}
