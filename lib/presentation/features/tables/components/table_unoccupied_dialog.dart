import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/form_bloc/custom_order_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/custom_my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/table/table_providers.dart';

/// Main dialog class using Riverpod best practices
class TableUnoccupiedDialog extends StatelessWidget {
  final TableModel tableModel;
  final String? openOrderName;
  final bool isDismissable;
  final Function()? onPressOrder;
  final Function() onAssignOrder;
  final bool hasPermissionManageOrders;

  const TableUnoccupiedDialog({
    super.key,
    required this.tableModel,
    this.openOrderName,
    this.isDismissable = true,
    this.onPressOrder,
    required this.onAssignOrder,
    required this.hasPermissionManageOrders,
  });

  /// Static method to show the dialog - recommended approach for dialogs
  static Future<void> show(
    BuildContext context, {
    required TableModel tableModel,
    String? openOrderName,
    bool isDismissable = true,
    Function()? onPressOrder,
    required Function() onAssignOrder,
    required bool hasPermissionManageOrders,
  }) async {
    return await showDialog(
      barrierDismissible: isDismissable,
      context: context,
      builder: (BuildContext context) {
        return TableUnoccupiedDialog(
          tableModel: tableModel,
          openOrderName: openOrderName,
          isDismissable: isDismissable,
          onPressOrder: onPressOrder,
          onAssignOrder: onAssignOrder,
          hasPermissionManageOrders: hasPermissionManageOrders,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (openOrderName != null && openOrderName!.isNotEmpty) {
      return _HasOpenOrderWidget(
        tableModel: tableModel,
        openOrderName: openOrderName!,
        isDismissable: isDismissable,
        onPressOrder: onPressOrder,
        onAssignOrder: onAssignOrder,
        hasPermissionManageOrders: hasPermissionManageOrders,
      );
    } else {
      return _NoOpenOrderWidget(
        tableModel: tableModel,
        isDismissable: isDismissable,
        onPressOrder: onPressOrder,
        onAssignOrder: onAssignOrder,
        hasPermissionManageOrders: hasPermissionManageOrders,
      );
    }
  }
}

/// Widget displayed when table has an open order
class _HasOpenOrderWidget extends StatelessWidget {
  final TableModel tableModel;
  final String openOrderName;
  final bool isDismissable;
  final Function()? onPressOrder;
  final Function() onAssignOrder;
  final bool hasPermissionManageOrders;

  const _HasOpenOrderWidget({
    required this.tableModel,
    required this.openOrderName,
    required this.isDismissable,
    required this.onPressOrder,
    required this.onAssignOrder,
    required this.hasPermissionManageOrders,
  });

  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: isDismissable,
      child: Dialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: availableWidth / 3,
            minWidth: availableWidth / 3,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header part
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(TableModel.getIcon(), color: kTextGray, size: 30),
                    5.widthBox,
                    Flexible(
                      child: Text(
                        tableModel.name ?? 'Table',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Open Order : ', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 5),
                    Text(
                      openOrderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: ButtonPrimary(
                        onPressed: onPressOrder ?? () {},
                        text: 'Order',
                      ),
                    ),
                    if (hasPermissionManageOrders) ...[
                      10.widthBox,
                      Flexible(
                        child: ButtonTertiary(
                          onPressed: onAssignOrder,
                          text: "${'assignOrderTo'.tr()} ${tableModel.name}",
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget displayed when table has no open order - uses Riverpod for state management
class _NoOpenOrderWidget extends ConsumerStatefulWidget {
  final TableModel tableModel;
  final bool isDismissable;
  final Function()? onPressOrder;
  final Function() onAssignOrder;
  final bool hasPermissionManageOrders;

  const _NoOpenOrderWidget({
    required this.tableModel,
    required this.isDismissable,
    required this.onPressOrder,
    required this.onAssignOrder,
    required this.hasPermissionManageOrders,
  });

  @override
  ConsumerState<_NoOpenOrderWidget> createState() => _NoOpenOrderWidgetState();
}

class _NoOpenOrderWidgetState extends ConsumerState<_NoOpenOrderWidget> {
  late FocusNode _nameFocusNode;
  late CustomOrderFormBloc _customOrderFormBloc;

  @override
  void initState() {
    super.initState();
    _nameFocusNode = FocusNode();
    _customOrderFormBloc = CustomOrderFormBloc(
      tableModel: widget.tableModel,
      ref: ref,
      predefinedOrderNotifier: ref.read(predefinedOrderProvider.notifier),
    );
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _customOrderFormBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use selector to listen only to saleItems list (avoid rebuilds on other state changes)
    final saleItemsList = ref.watch(saleItemsListProvider);

    return PopScope(
      canPop: widget.isDismissable,
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 500),
          child: BlocProvider(
            create: (context) => _customOrderFormBloc,
            child: Builder(
              builder: (context) {
                final customOrderFormBloc =
                    BlocProvider.of<CustomOrderFormBloc>(context);

                customOrderFormBloc.name.stream.listen((state) {
                  if (state.value.isEmpty &&
                      !customOrderFormBloc.hasManuallyEdited) {
                    customOrderFormBloc.name.updateValue(
                      customOrderFormBloc.initialNameValue,
                    );
                  }
                });

                return FormBlocListener<
                  CustomOrderFormBloc,
                  Map<String, dynamic>,
                  String
                >(
                  onSubmitting: (context, state) {},
                  onSuccess: (context, state) async {
                    if (state.successResponse != null) {
                      PredefinedOrderModel statePO =
                          state.successResponse!['data']
                              as PredefinedOrderModel;

                      widget.tableModel.status = TableStatusEnum.OCCUPIED;
                      widget.tableModel.predefinedOrderId = statePO.id;
                      int updatedTable = await ref
                          .read(tableProvider.notifier)
                          .update(widget.tableModel);

                      if (updatedTable >= 1) {
                        widget.onPressOrder != null
                            ? widget.onPressOrder!()
                            : () {};
                      } else {
                        if (mounted) {
                          ThemeSnackBar.showSnackBar(
                            context,
                            'Submission failed create custom order',
                          );
                        }
                      }
                    }
                  },
                  onFailure: (context, state) {
                    ThemeSnackBar.showSnackBar(
                      context,
                      state.failureResponse ?? 'An error occurred',
                    );
                  },
                  onSubmissionFailed: (context, state) async {
                    await LogUtils.error(
                      'Submission failed create custom order',
                    );
                  },
                  child: Builder(
                    builder: (context) {
                      final tablesBarcode = ref.watch(tablesBarcodeProvider);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (tablesBarcode != null &&
                            tablesBarcode.isNotEmpty &&
                            !customOrderFormBloc.hasManuallyEdited) {
                          customOrderFormBloc.name.updateValue(tablesBarcode);
                          ref
                              .read(barcodeScannerProvider.notifier)
                              .clearScannedItem();
                        }
                      });
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Space(10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              child: StreamBuilder<TextFieldBlocState<dynamic>>(
                                stream: customOrderFormBloc.name.stream,
                                initialData: customOrderFormBloc.name.state,
                                builder: (context, snapshot) {
                                  final value = snapshot.data?.value ?? '';
                                  bool isInitialValue =
                                      value ==
                                      customOrderFormBloc.initialNameValue;
                                  bool isManuallyEdited =
                                      customOrderFormBloc.hasManuallyEdited;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          NavigationUtils.pop(context);
                                        },
                                        child: Icon(
                                          FontAwesomeIcons.xmark,
                                          color: canvasColor,
                                        ),
                                      ),
                                      Space(10.h),
                                      Text(
                                        'tableCustomHeader'.tr(),
                                        style: textStyleGray(),
                                      ),
                                      Space(10.h),
                                      CustomMyTextFieldBlocBuilder(
                                        focusNode: _nameFocusNode,
                                        textFieldBloc: customOrderFormBloc.name,
                                        labelText: 'name'.tr(),
                                        hintText: '',
                                        isHighlightValue: isInitialValue,
                                        isManuallyEdited: isManuallyEdited,
                                        onChanged: (value) {
                                          if (!customOrderFormBloc
                                              .hasManuallyEdited) {
                                            customOrderFormBloc
                                                .hasManuallyEdited = true;

                                            if (value.startsWith(
                                                  customOrderFormBloc
                                                      .initialNameValue,
                                                ) &&
                                                value.length >
                                                    customOrderFormBloc
                                                        .initialNameValue
                                                        .length) {
                                              String newText = value.substring(
                                                customOrderFormBloc
                                                    .initialNameValue
                                                    .length,
                                              );
                                              Future.microtask(() {
                                                customOrderFormBloc.name
                                                    .updateValue(newText);
                                              });
                                            }
                                          }
                                        },
                                        trailingIcon: IconButton(
                                          icon: Icon(
                                            FontAwesomeIcons.xmark,
                                            color: canvasColor,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            customOrderFormBloc.name
                                                .updateValue("");
                                            customOrderFormBloc
                                                .hasManuallyEdited = true;

                                            FocusScope.of(
                                              context,
                                            ).requestFocus(_nameFocusNode);

                                            ref
                                                .read(
                                                  barcodeScannerProvider
                                                      .notifier,
                                                )
                                                .clearScannedItem();
                                          },
                                        ),
                                      ),
                                      MyTextFieldBlocBuilder(
                                        textFieldBloc:
                                            customOrderFormBloc.comment,
                                        labelText: 'comment'.tr(),
                                        hintText: '',
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: ButtonPrimary(
                                              onPressed: () {
                                                if (saleItemsList.isEmpty) {
                                                  customOrderFormBloc.submit();
                                                } else {
                                                  DialogUtils.showUnSavedOrderDialogue(
                                                    context,
                                                  );
                                                }
                                              },
                                              text: 'Save Order',
                                            ),
                                          ),
                                          if (widget
                                              .hasPermissionManageOrders) ...[
                                            10.widthBox,
                                            Flexible(
                                              child: ButtonTertiary(
                                                onPressed: widget.onAssignOrder,
                                                text:
                                                    "${'assignOrderTo'.tr()} ${widget.tableModel.name}",
                                              ),
                                            ),
                                          ],
                                        ],
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
