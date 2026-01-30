import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/form_bloc/custom_order_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/custom_my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

class SaveOrderCustomDialogue extends ConsumerStatefulWidget {
  final Function() onSuccess;
  final Function(String message) onError;
  final Function(List<PrintReceiptCacheModel> listPRC)
  onCallbackPrintReceiptCache;
  final int listPredefinedOrder;

  const SaveOrderCustomDialogue({
    super.key,
    required this.onSuccess,
    required this.onError,
    required this.listPredefinedOrder,
    required this.onCallbackPrintReceiptCache,
  });

  @override
  ConsumerState<SaveOrderCustomDialogue> createState() =>
      _SaveOrderCustomDialogueState();
}

class _SaveOrderCustomDialogueState
    extends ConsumerState<SaveOrderCustomDialogue> {
  late final BarcodeScannerNotifier _barcodeScannerNotifier;

  bool wantToDispose = true;

  @override
  void initState() {
    super.initState();
    _barcodeScannerNotifier = ServiceLocator.get<BarcodeScannerNotifier>();
    // _barcodeScannerNotifier.initialize();
    _barcodeScannerNotifier.initializeForSaveOrderCustom();
  }

  @override
  void dispose() {
    // Reinitialize to sales screen when dialog closes
    if (wantToDispose) {
      _barcodeScannerNotifier.reinitializeToSalesScreen();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scannerNotifier = _barcodeScannerNotifier;
    final outletModel = ServiceLocator.get<OutletModel>();
    final featureCompNotifier = ref.watch(featureCompanyProvider.notifier);
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    final hasPermissionManageOrders =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    final isFeatureActive = featureCompNotifier.isOpenOrdersActive();
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    final tableModel = ref.read(saleItemProvider).selectedTable;
    final isTableCustom =
        tableModel?.id != null && tableModel?.predefinedOrderId == null;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight / 2,
          maxWidth: availableWidth / 2,
        ),
        child: BlocProvider(
          create:
              (context) => CustomOrderFormBloc(
                tableModel: TableModel(),
                ref: ref,
                predefinedOrderNotifier: ref.read(
                  predefinedOrderProvider.notifier,
                ),
              ),
          child: Builder(
            builder: (context) {
              final customOrderFormBloc = BlocProvider.of<CustomOrderFormBloc>(
                context,
              );

              // Add a listener to handle initial focus only
              customOrderFormBloc.name.stream.listen((state) {
                // If the field is empty and hasn't been manually edited yet,
                // we want to show the initial value but select it all on focus
                if (state.value.isEmpty &&
                    !customOrderFormBloc.hasManuallyEdited) {
                  customOrderFormBloc.name.updateValue(
                    customOrderFormBloc.initialNameValue,
                  );
                }

                // We don't need to handle the built-in clear button anymore
                // since we're using our custom trailing icon
              });
              if (scannerNotifier.saveOrderCustomBarcode != null &&
                  scannerNotifier.saveOrderCustomBarcode!.isNotEmpty) {
                customOrderFormBloc.name.updateValue(
                  scannerNotifier.saveOrderCustomBarcode!,
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                scannerNotifier.clearScannedItem();
              });

              return FormBlocListener<
                CustomOrderFormBloc,
                Map<String, dynamic>,
                String
              >(
                onSubmitting: (context, state) {},
                onSuccess: (context, state) {
                  // ThemeSnackBar.showSnackBar(
                  //     context, state.successResponse!['message']);
                  PredefinedOrderModel newPO =
                      state.successResponse!['data'] as PredefinedOrderModel;
                  // Get sale item state
                  final saleItemsState = ref.read(saleItemProvider);
                  // save order into custom predefined order
                  ref
                      .read(predefinedOrderProvider.notifier)
                      .saveOrderIntoCustomPredefinedOrder(
                        context,
                        newPO,
                        saleItemsState,
                        onSuccess: widget.onSuccess,
                        onError: (message) {
                          prints(
                            "ON ERROR CUSTOM ORDER 😈😈😈😈😈😈😈😈😈😈 $message",
                          );
                          widget.onError(message);
                        },
                        onCallbackPrintReceiptCache:
                            widget.onCallbackPrintReceiptCache,
                      );
                },
                onFailure: (context, state) {
                  ThemeSnackBar.showSnackBar(context, state.failureResponse!);
                },
                onSubmissionFailed: (context, state) async {
                  prints('Submission failed create custom order');
                  await LogUtils.error('Submission failed create custom order');
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Space(10),
                    AppBar(
                      elevation: 0,
                      backgroundColor: white,
                      title: Row(
                        children: [
                          Text(
                            'customOrder'.tr(),
                            style: AppTheme.h1TextStyle(),
                          ),
                          const Expanded(flex: 2, child: SizedBox()),
                          Expanded(
                            flex: 1,
                            child: ButtonTertiary(
                              text: 'save'.tr(),
                              icon: FontAwesomeIcons.download,
                              onPressed: () {
                                onPressSave(
                                  customOrderFormBloc,
                                  isFeatureActive,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      leading: IconButton(
                        icon: getCloseIcon(
                          isTableCustom,
                          outletModel,
                          hasPermissionManageOrders,
                        ),
                        onPressed: () {
                          onPressLeading(
                            isTableCustom,
                            context,
                            outletModel,
                            hasPermissionManageOrders,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: StreamBuilder<TextFieldBlocState<dynamic>>(
                        stream: customOrderFormBloc.name.stream,
                        initialData: customOrderFormBloc.name.state,
                        builder: (context, snapshot) {
                          final value = snapshot.data?.value ?? '';
                          bool isInitialValue =
                              value == customOrderFormBloc.initialNameValue;
                          bool isManuallyEdited =
                              customOrderFormBloc.hasManuallyEdited;

                          // Create a StatefulWidget to properly manage the focus node lifecycle

                          // Create a focus node that persists across rebuilds
                          // This should be in initState of a StatefulWidget, but we're using StatefulBuilder
                          // so we need to ensure it's only created once
                          final nameFocusNode = FocusNode();

                          // Dispose the focus node when the widget is removed
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            // Add a callback to dispose the focus node when the widget is removed
                            // This is a workaround since we can't use dispose() with StatefulBuilder
                            ModalRoute.of(context)?.addScopedWillPopCallback(
                              () {
                                nameFocusNode.dispose();
                                return Future.value(true);
                              },
                            );
                          });

                          return Column(
                            children: [
                              // Use a custom trailing icon instead of the built-in clear button
                              CustomMyTextFieldBlocBuilder(
                                focusNode: nameFocusNode,
                                textFieldBloc: customOrderFormBloc.name,
                                labelText: 'name'.tr(),
                                hintText: '',
                                isHighlightValue: isInitialValue,
                                isManuallyEdited: isManuallyEdited,
                                onChanged: (value) {
                                  // If this is the first edit
                                  if (!customOrderFormBloc.hasManuallyEdited) {
                                    // Mark as manually edited
                                    customOrderFormBloc.hasManuallyEdited =
                                        true;

                                    // If the user is just starting to type (adding to the initial value)
                                    // and the value starts with the initial value, we want to replace it
                                    if (value.startsWith(
                                          customOrderFormBloc.initialNameValue,
                                        ) &&
                                        value.length >
                                            customOrderFormBloc
                                                .initialNameValue
                                                .length) {
                                      // Get just the new character(s) the user typed
                                      String newText = value.substring(
                                        customOrderFormBloc
                                            .initialNameValue
                                            .length,
                                      );
                                      // Replace the initial value with just what the user typed
                                      Future.microtask(() {
                                        customOrderFormBloc.name.updateValue(
                                          newText,
                                        );
                                      });
                                    }
                                  }
                                },
                                // Use a custom trailing icon that's always visible
                                trailingIcon: IconButton(
                                  icon: Icon(
                                    FontAwesomeIcons.xmark,
                                    color: canvasColor,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    // Clear the field and mark as manually edited
                                    customOrderFormBloc.name.updateValue("");
                                    customOrderFormBloc.hasManuallyEdited =
                                        true;

                                    // Request focus directly using the focus node
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(nameFocusNode);
                                  },
                                ),
                              ),

                              // comment Input Field
                              MyTextFieldBlocBuilder(
                                textFieldBloc: customOrderFormBloc.comment,
                                labelText: 'comment'.tr(),
                                hintText: '',
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void onPressSave(
    CustomOrderFormBloc customOrderFormBloc,
    bool isFeatureActive,
  ) {
    if (!isFeatureActive) {
      DialogUtils.showFeatureNotAvailable(context);
      return;
    }
    customOrderFormBloc.submit();
  }

  void onPressLeading(
    bool isTableCustom,
    BuildContext context,
    OutletModel outletModel,
    bool hasPermissionManageOrders,
  ) {
    if (outletModel.isEnabledOpenOrder != null &&
        !outletModel.isEnabledOpenOrder!) {
      wantToDispose = true;
      NavigationUtils.pop(context);
    } else if (isTableCustom) {
      wantToDispose = true;
      NavigationUtils.pop(context);
    } else if (!hasPermissionManageOrders) {
      wantToDispose = true;
      NavigationUtils.pop(context);
    } else if (widget.listPredefinedOrder != 0) {
      wantToDispose = false;
      ref
          .read(dialogNavigatorProvider.notifier)
          .setPageIndex(DialogNavigatorEnum.saveOrder);

      _barcodeScannerNotifier.initializeForSaveOrderDialogue();
    } else if (widget.listPredefinedOrder == 0) {
      wantToDispose = true;
      NavigationUtils.pop(context);
    } else {
      wantToDispose = false;
      ref
          .read(dialogNavigatorProvider.notifier)
          .setPageIndex(DialogNavigatorEnum.saveOrder);
      _barcodeScannerNotifier.initializeForSaveOrderDialogue();
    }
  }

  Icon getCloseIcon(
    bool isTableCustom,
    OutletModel outletModel,
    bool hasPermissionManageOrders,
  ) {
    if (outletModel.isEnabledOpenOrder != null &&
        !outletModel.isEnabledOpenOrder!) {
      return Icon(Icons.close, color: canvasColor);
    } else if (isTableCustom) {
      return Icon(Icons.close, color: canvasColor);
    } else if (!hasPermissionManageOrders) {
      return Icon(Icons.close, color: canvasColor);
    } else if (widget.listPredefinedOrder != 0) {
      return Icon(Icons.arrow_back, color: canvasColor);
    } else if (widget.listPredefinedOrder == 0) {
      return Icon(Icons.close, color: canvasColor);
    } else {
      return Icon(Icons.arrow_back, color: canvasColor);
    }
  }
}
