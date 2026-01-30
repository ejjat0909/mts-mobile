import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/data/datasources/remote/pusher_datasource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/form_bloc/close_shift_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/presentation/common/dialogs/confirm_dialogue.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/custom_switch.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/rolling_text.dart';
import 'package:mts/presentation/common/widgets/row_reset_order_number.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/shift_history/shift_history_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/pending_changes/pending_changes_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';

class CloseShift extends ConsumerStatefulWidget {
  const CloseShift({super.key});

  @override
  ConsumerState<CloseShift> createState() => _CloseShiftState();
}

class _CloseShiftState extends ConsumerState<CloseShift> {
  bool isDisabledButton = false;
  String? loadingText;
  int pcLength = 0;
  OutletModel _outletModel = OutletModel();
  final _globalContext = navigatorKey.currentContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final listPC =
          await ref
              .read(pendingChangesProvider.notifier)
              .getListPendingChanges();
      pcLength = listPC.length;
      _outletModel =
          await ref.read(outletProvider.notifier).getLatestOutletModel() ??
          OutletModel();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final hasPermissionShift =
        permissionNotifier.hasViewShiftReportsPermission();
    final hasPermission = permissionNotifier.hasViewShiftReportsPermission();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 50, left: 200, right: 200, bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'closeShift'.tr(),
                  style: AppTheme.mediumTextStyle(color: kBlackColor),
                ),
              ),

              hasPermissionShift
                  ? Expanded(
                    flex: 1,
                    child: ButtonTertiary(
                      text: 'shiftHistory'.tr(),
                      onPressed: () {
                        onPressShiftHistory(context);
                      },
                    ),
                  )
                  : SizedBox.shrink(),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(thickness: 1),
          SizedBox(height: 10.h),
          FutureBuilder<Map<String, dynamic>>(
            future:
                ref.read(shiftProvider.notifier).getLatestShiftAndListPrinter(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.hasError) {
                return Center(child: ThemeSpinner.spinner());
              }

              ShiftModel shiftModel = snapshot.data!['latestShift'];
              List<PrinterSettingModel> listPrinter =
                  snapshot.data!['listPrinterSetting'];
              return BlocProvider(
                create: (context) {
                  // if (kDebugMode) {
                  //   prints('shiftModel.toJson()');
                  //   prints(shiftModel.toJson());
                  // }
                  return CloseShiftFormBloc(shiftModel);
                },
                child: Builder(
                  builder: (context) {
                    final closeShiftFormBloc =
                        context.read<CloseShiftFormBloc>();
                    return FormBlocListener<CloseShiftFormBloc, String, String>(
                      onSubmitting: (context, state) {},
                      onSuccess: (context, state) async {
                        await handleOnSuccessCloseShift(
                          state,
                          shiftModel,
                          closeShiftFormBloc,
                        );
                      },
                      onFailure: (context, state) {
                        prints('failed');
                      },
                      onSubmissionFailed: (context, state) {
                        prints('submission failed');
                      },
                      child: Column(
                        children: [
                          if (_outletModel.id != null)
                            RowResetOrderNumber(outletModel: _outletModel),
                          MyTextFieldBlocBuilder(
                            textFieldBloc: closeShiftFormBloc.expectedAmount,
                            isEnabled: false,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            labelText: 'expectedCashAmount'.tr(),
                            leading: Padding(
                              padding: EdgeInsets.only(
                                top: 20.h,
                                left: 10.w,
                                right: 10.w,
                                bottom: 20.h,
                              ),
                              child: Text(
                                'RM'.tr(args: ['']),
                                style: AppTheme.mediumTextStyle(
                                  color: canvasColor,
                                ),
                              ),
                            ),
                            hintText: '0.00',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              if (closeShiftFormBloc
                                          .actualAmount
                                          .valueToDouble !=
                                      null &&
                                  closeShiftFormBloc
                                          .expectedAmount
                                          .valueToDouble !=
                                      null) {
                                double difference = 0;

                                // actual - expected
                                difference =
                                    closeShiftFormBloc
                                        .actualAmount
                                        .valueToDouble! -
                                    closeShiftFormBloc
                                        .expectedAmount
                                        .valueToDouble!;

                                // context
                                //     .read<ShiftNotifier>()
                                //     .setDifferenceAmount(difference);

                                // assign to formBloc

                                closeShiftFormBloc.differenceAmount.updateValue(
                                  difference.toString(),
                                );
                              }
                            },
                          ),
                          MyTextFieldBlocBuilder(
                            textFieldBloc: closeShiftFormBloc.actualAmount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            labelText: 'actualCashAmount'.tr(),
                            leading: Padding(
                              padding: EdgeInsets.only(
                                top: 20.h,
                                left: 10.w,
                                right: 10.w,
                                bottom: 20.h,
                              ),
                              child: Text(
                                'RM'.tr(args: ['']),
                                style: AppTheme.mediumTextStyle(
                                  color: canvasColor,
                                ),
                              ),
                            ),
                            hintText: '0.00',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              prints("value: ${value == ""}");
                              if (value == '') {
                                double diff =
                                    0.00 -
                                    closeShiftFormBloc
                                        .expectedAmount
                                        .valueToDouble!;
                                closeShiftFormBloc.differenceAmount.updateValue(
                                  diff.toStringAsFixed(2),
                                );
                              }
                              if (closeShiftFormBloc
                                          .expectedAmount
                                          .valueToDouble !=
                                      null &&
                                  closeShiftFormBloc
                                          .actualAmount
                                          .valueToDouble !=
                                      null) {
                                double difference =
                                    0.00 -
                                    closeShiftFormBloc
                                        .expectedAmount
                                        .valueToDouble!;

                                //actual - expected
                                difference =
                                    closeShiftFormBloc
                                        .actualAmount
                                        .valueToDouble! -
                                    closeShiftFormBloc
                                        .expectedAmount
                                        .valueToDouble!;

                                // context
                                //     .read<ShiftNotifier>()
                                //     .setDifferenceAmount(difference);

                                // assign to formBloc

                                closeShiftFormBloc.differenceAmount.updateValue(
                                  difference.toStringAsFixed(2),
                                );
                              }
                              setState(() {});
                            },
                          ),
                          SizedBox(height: 10.h),
                          _buildDifferenceAmountRow(closeShiftFormBloc),
                          SizedBox(height: 10.h),
                          // prints report switch
                          buildRowPrintReport(
                            listPrinter,
                            // hasPermission,
                            context,
                          ),

                          // prints item
                          buildRowPrintItem(
                            listPrinter,
                            hasPermission,
                            context,
                          ),
                          10.heightBox,
                          ButtonBottom(
                            'closeShift'.tr(),
                            isDisabled: isDisabledButton,
                            loadingText: loadingText,
                            press: () async {
                              if (await NetworkUtils.hasInternetConnection()) {
                                closeShiftFormBloc.submit();
                              } else {
                                CustomDialog.show(
                                  context,
                                  icon:
                                      Icons
                                          .signal_wifi_connected_no_internet_4_outlined,
                                  title: 'noInternet'.tr(),
                                  description: 'pleaseConnectInternet'.tr(),
                                  btnOkText: 'ok'.tr(),
                                  btnOkOnPress:
                                      () => NavigationUtils.pop(context),
                                );
                              }
                            },
                          ),
                          SizedBox(height: 10.h),
                          isDisabledButton
                              ? const SizedBox.shrink()
                              : (isStaging
                                  ? ButtonTertiary(
                                    text: 'back'.tr(),
                                    onPressed: () {
                                      ref
                                          .read(myNavigatorProvider.notifier)
                                          .setSelectedTab(
                                            3100,
                                            'openShift'.tr(),
                                          );
                                      ref
                                          .read(myNavigatorProvider.notifier)
                                          .setIsCloseShiftScreen(false);
                                    },
                                  )
                                  : const SizedBox.shrink()),
                          if (isStaging) 30.heightBox,
                          if (isStaging)
                            GestureDetector(
                              onTap: () {
                                if (pcLength > 0) {
                                  prints("navigate to local db");
                                  NavigationUtils.navigateToLocalDB(context);
                                }
                              },
                              child: Text(
                                'Pending changes : $pcLength',
                                style: textStyleNormal(fontSize: 12),
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
        ],
      ),
    );
  }

  Widget _buildDifferenceAmountRow(CloseShiftFormBloc closeShiftFormBloc) {
    double differenceValue =
        double.tryParse(closeShiftFormBloc.differenceAmount.value) ?? 0.0;
    bool isNegative = differenceValue < 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            'difference'.tr(),
            style: AppTheme.mediumTextStyle(color: canvasColor),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: RollingNumber(
              value: differenceValue.abs(), // Use absolute value
              prefix: isNegative ? '-rm'.tr() : 'rm'.tr(),
              decimalPlaces: 2,
              useThousandsSeparator: true,
              style: AppTheme.mediumTextStyle(
                color: isNegative ? kTextRed : canvasColor,
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ),
      ],
    );
  }

  // Row _buildDifferenceAmountRow(CloseShiftFormBloc closeShiftFormBloc) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: Text(
  //           'difference'.tr(),
  //           style: AppTheme.mediumTextStyle(color: canvasColor),
  //         ),
  //       ),
  //       Expanded(
  //         child: Text(
  //           double.parse(closeShiftFormBloc.differenceAmount.value) < 0
  //               ? "-${'RM'.tr(args: [(double.parse(closeShiftFormBloc.differenceAmount.value).abs().toStringAsFixed(2))])}"
  //               : 'RM'.tr(args: [(closeShiftFormBloc.differenceAmount.value)]),
  //           style: AppTheme.mediumTextStyle(
  //             color:
  //                 double.parse(closeShiftFormBloc.differenceAmount.value) < 0
  //                     ? kTextRed
  //                     : canvasColor,
  //           ),
  //           textAlign: TextAlign.end,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Row buildRowPrintReport(
    List<PrinterSettingModel> listPrinter,
    // bool hasPermission,
    BuildContext context,
  ) {
    final shiftState = ref.watch(shiftProvider);
    return Row(
      children: [
        listPrinter.isEmpty
            ? Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'printReport'.tr(),
                    style: AppTheme.mediumTextStyle(color: canvasColor),
                  ),
                  Text(
                    'noPrinterAvailable'.tr(),
                    style: AppTheme.normalTextStyle(color: kTextRed),
                  ),
                  // if (!hasPermission)
                  //   Text(
                  //     'youDontHavePermissionForThisAction'.tr(),
                  //     style: AppTheme.normalTextStyle(color: kTextRed),
                  //   ),
                ],
              ),
            )
            : Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'printReport'.tr(),
                    style: AppTheme.mediumTextStyle(color: canvasColor),
                  ),
                  // if (!hasPermission)
                  //   Text(
                  //     'youDontHavePermissionForThisAction'.tr(),
                  //     style: AppTheme.normalTextStyle(color: kTextRed),
                  //   ),
                ],
              ),
            ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: CustomSwitch(
              // isDisabled: hasPermission ? listPrinter.isEmpty : true,
              isDisabled: listPrinter.isEmpty,
              value: shiftState.isPrintReport,
              onChanged: (value) {
                ref.read(shiftProvider.notifier).setPrintReport(value);
              },
              // onChanged:
              //     hasPermission
              //         ? (value) {
              //           context.read<ShiftNotifier>().setPrintReport(value);
              //         }
              //         : null,
            ),
          ),
        ),
      ],
    );
  }

  Row buildRowPrintItem(
    List<PrinterSettingModel> listPrinter,
    bool hasPermission,
    BuildContext context,
  ) {
    final shiftState = ref.watch(shiftProvider);
    return Row(
      children: [
        listPrinter.isEmpty
            ? Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'printSoldItems'.tr(),
                    style: AppTheme.mediumTextStyle(color: canvasColor),
                  ),
                  if (!hasPermission)
                    Text(
                      'youDontHavePermissionForThisAction'.tr(),
                      style: AppTheme.normalTextStyle(color: kTextRed),
                    ),
                ],
              ),
            )
            : Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'printSoldItems'.tr(),
                    style: AppTheme.mediumTextStyle(color: canvasColor),
                  ),
                  if (!hasPermission)
                    Text(
                      'youDontHavePermissionForThisAction'.tr(),
                      style: AppTheme.normalTextStyle(color: kTextRed),
                    ),
                ],
              ),
            ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: CustomSwitch(
              isDisabled: hasPermission ? listPrinter.isEmpty : true,
              value: shiftState.isPrintItem,
              onChanged:
                  hasPermission
                      ? (value) {
                        context.read<ShiftNotifier>().setPrintItem(value);
                      }
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  void onPressShiftHistory(BuildContext context) {
    final permissionNotifier = ServiceLocator.get<PermissionNotifier>();
    // check permission
    if (!permissionNotifier.hasViewShiftReportsPermission()) {
      DialogUtils.showNoPermissionDialogue(context);
      return;
    }
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) {
          return const ShiftHistoryScreen();
        },
      ),
    );
  }

  Future<void> handleOnSuccessCloseShift(
    FormBlocSuccess<String, String> state,
    ShiftModel shiftModel,
    CloseShiftFormBloc closeShiftFormBloc,
  ) async {
    if (_globalContext == null) {
      prints("GLOBAL CONTEXT NULL");
      return;
    }

    isDisabledButton = true;
    final shiftState = ref.read(shiftProvider);
    if (shiftState.isPrintReport) {
      loadingText = 'printing'.tr();
    }
    setState(() {});
    PosDeviceModel deviceModel = ServiceLocator.get<PosDeviceModel>();
    StaffModel staffModel = ServiceLocator.get<StaffModel>();
    bool isPrintReport = shiftState.isPrintReport;

    LoadingDialog.show(_globalContext);

    // if have any error during first time close shift, then shiftModel will be null
    // because the shiftModel will be query where closedAt is null
    // so we need to get back the shiftModel where closedBy using staffModel.id
    if (shiftModel.id == null) {
      shiftModel = await ref
          .read(shiftProvider.notifier)
          .getShiftWhereClosedBy(staffModel.id!, deviceModel.id!);
    }

    // update latest shift
    double totalPaRefunded =
        await ref.read(receiptProvider.notifier).calcPayableAmountRefunded();
    double totalPaNotRefunded =
        await ref.read(receiptProvider.notifier).calcPayableAmountNotRefunded();
    Map<String, dynamic> saleSummary = await ref
        .read(receiptProvider.notifier)
        .dataCloseShift(true, shiftModel: shiftModel);
    ShiftModel newUpdateShift =
        shiftModel.id == null
            ? ShiftModel()
            : shiftModel.copyWith(
              closedAt: DateTime.now(),
              actualCash: closeShiftFormBloc.actualAmount.valueToDouble,
              shortCash: double.parse(state.successResponse!),
              // when null, it will take the last value
              cashPayments:
                  totalPaNotRefunded == 0.0 ? null : totalPaNotRefunded,
              cashRefunds: totalPaRefunded == 0.0 ? null : totalPaRefunded,
              saleSummaryJson:
                  saleSummary == {} ? null : jsonEncode(saleSummary),
              posDeviceId: deviceModel.id,
              posDeviceName: deviceModel.name,
              closedBy: staffModel.id,
              isPrint: isPrintReport,
              updatedAt: DateTime.now(),
            );

    // set curr shift
    ref.read(shiftProvider.notifier).setCurrShiftModel(newUpdateShift);

    // update shift
    loadingText = 'pleaseWait'.tr();
    setState(() {});
    // if (kDebugMode) {
    //   prints(newUpdateShift.toJson());
    // }

    if (newUpdateShift.id != null) {
      prints('IS PRINT $isPrintReport');
      if (isPrintReport) {
        await printCloseShift(
          newUpdateShift,
          onError: (message) {
            prints("PRINT CLOSE SHIFT ON ERROR: $message");
            // close loading dialogue first
            LoadingDialog.hide(_globalContext);
            loadingText = null;
            isDisabledButton = false;
            setState(() {});
            CustomDialog.show(
              _globalContext,
              isDissmissable: false,
              dialogType: DialogType.danger,
              icon: FontAwesomeIcons.print,
              title: 'errorPrinterNotFound'.tr(),
              description: 'doYouWantToContinue'.tr(),
              btnCancelText: 'cancel'.tr(),
              btnCancelOnPress: () => NavigationUtils.pop(_globalContext),
              btnOkText: 'continue'.tr(),
              btnOkOnPress: () async {
                loadingText = 'pleaseWait'.tr();
                isDisabledButton = true;
                setState(() {});
                // close custom dialogue
                NavigationUtils.pop(_globalContext);
                // show loading dialogue for sync
                LoadingDialog.show(_globalContext);
                await updateShiftStaffAndSyncRealTime(newUpdateShift);

                isDisabledButton = false;
                setState(() {});
              },
            );
          },
          onSuccess: () async {
            // future me, dont worry this function will not get all data from api
            // because it want to close shift
            await updateShiftStaffAndSyncRealTime(newUpdateShift);
            isDisabledButton = false;
          },
        );
      } else {
        // no prints report
        await updateShiftStaffAndSyncRealTime(newUpdateShift);
      }
    } else {
      prints('CLOSE SHIFT MASUK ELSE');
      LoadingDialog.hide(_globalContext);
    }

    //  if (updateShift != 0) {
    // success update shift
  }

  Future<void> updateShiftStaffAndSyncRealTime(
    ShiftModel newUpdateShift,
  ) async {
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);

    if (_globalContext == null) return;
    saleItemsNotifier.removeAllSaleItems();
    ref.read(shiftProvider.notifier).setPrintItem(false);
    ref.read(shiftProvider.notifier).setPrintReport(false);
    try {
      final syncPending =
          await ref
              .read(pendingChangesProvider.notifier)
              .syncPendingChangesList();
      if (!syncPending) {
        LoadingDialog.hide(_globalContext);
        loadingText = null;
        isDisabledButton = false;
        setState(() {});
        ThemeSnackBar.showSnackBar(
          _globalContext,
          'Failed to sync pending changes',
        );
        forceCloseShiftDialogue(newUpdateShift);
        return;
      }
      await operationAfterSyncPendingChanges(
        newUpdateShift,
        isForceCloseShift: false,
      );
    } catch (e) {
      LoadingDialog.hide(_globalContext);
      loadingText = null;
      isDisabledButton = false;
      setState(() {});
      ThemeSnackBar.showSnackBar(
        _globalContext,
        'Failed to sync pending changes $e',
      );
      forceCloseShiftDialogue(newUpdateShift);
    }
  }

  Future<void> operationAfterSyncPendingChanges(
    ShiftModel newUpdateShift, {
    required bool isForceCloseShift,
  }) async {
    if (isForceCloseShift) {
      // delete pending changes
      await ref.read(pendingChangesProvider.notifier).deleteAll();
    }
    await updateShiftAndStaff(newUpdateShift);
    await syncRealTime();
    await ref.read(secondDisplayProvider.notifier).stopSecondaryDisplay();
  }

  Future<void> syncRealTime() async {
    await ref
        .read(syncRealTimeProvider.notifier)
        .onSyncOrder(
          null, // context pass null because we handle in callback
          false,
          needToDownloadImage: false,
          onlyCheckPendingChanges: true,
          isAfterActivateLicense: false,
          manuallyClick: false,
          isSuccess: (isSuccess, errorMessage) async {
            if (_globalContext == null) return;
            // close loading dialogue
            LoadingDialog.hide(_globalContext);
            loadingText = null;
            isDisabledButton = false;

            setState(() {});
            if (isSuccess) {
              ref
                  .read(myNavigatorProvider.notifier)
                  .setSelectedTab(3100, 'openShift'.tr());
              ref
                  .read(myNavigatorProvider.notifier)
                  .setIsCloseShiftScreen(false);

              ref.read(shiftProvider.notifier).setCloseShift();

              // unsubscribe pusher
              PusherDatasource pusherService =
                  ServiceLocator.get<PusherDatasource>();
              SecureStorageApi secureStorage =
                  ServiceLocator.get<SecureStorageApi>();
              String channelName = await secureStorage.read(key: 'channelName');
              pusherService.unsubscribe(channelName);

              // clear order in sale item
              final saleItemsNotifier = ref.read(saleItemProvider.notifier);
              saleItemsNotifier.clearOrderItems();

              // delete staff access token

              String? token = await secureStorage.read(
                key: 'staff_access_token',
              );
              if (token.isNotEmpty == true) {
                await secureStorage.delete(key: 'staff_access_token');
              }
            } else {
              ThemeSnackBar.showSnackBar(
                _globalContext,
                errorMessage ?? 'Error',
              );
            }
          },
        );
  }

  Future<void> updateShiftAndStaff(ShiftModel newUpdateShift) async {
    newUpdateShift.id != null
        ? await ref.read(shiftProvider.notifier).update(newUpdateShift)
        : 0;

    // get list staff
    List<StaffModel> listStaff = await ref
        .read(staffProvider.notifier)
        .getListStaffByCurrentShiftId(newUpdateShift.id ?? '-1');

    // update staff to assign null to current shift id

    for (StaffModel staffModel in listStaff) {
      if (staffModel.id != null && staffModel.id!.isNotEmpty) {
        StaffModel updatedStaff = staffModel.copyWith(
          currentShiftId: null,
          updatedAt: DateTime.now(),
        ); // Update the currentShiftId field

        await ref.read(staffProvider.notifier).update(updatedStaff);
      }
    }
  }

  Future<void> printCloseShift(
    ShiftModel newUpdateShift, {
    required Function(String message) onError,
    required Function() onSuccess,
  }) async {
    bool isPrintReport = ref.read(shiftProvider).isPrintReport;

    if (isPrintReport) {
      /// [PRINT CLOSE SHIFT]
      List<PrinterSettingModel> listPsm =
          await ref
              .read(printerSettingProvider.notifier)
              .getListPrinterSetting();

      // filter printer
      listPsm = listPsm.where((element) => element.printReceiptBills!).toList();
      if (listPsm.isNotEmpty) {
        List<String> errorIps = []; // Store all error IPs
        int completedRequests = 0; // Track number of completed requests

        for (PrinterSettingModel psm in listPsm) {
          if (psm.printReceiptBills!) {
            Future<void> printTask;

            if (psm.interface == PrinterSettingEnum.bluetooth) {
              printTask = ref
                  .read(printerSettingProvider.notifier)
                  .printCloseShiftDesign(
                    dataCloseShift: await ref
                        .read(receiptProvider.notifier)
                        .dataCloseShift(false, shiftModel: null),
                    isInterfaceBluetooth: true,
                    ipAddress: psm.identifierAddress ?? '',
                    paperWidth: ReceiptPrinterService.getPaperWidth(
                      psm.paperWidth,
                    ),
                    shiftModel: newUpdateShift,
                    onError: (message, ipAd) {
                      errorIps.add(ipAd);
                    },
                  );
            } else if (psm.interface == PrinterSettingEnum.ethernet &&
                psm.identifierAddress != null) {
              printTask = ref
                  .read(printerSettingProvider.notifier)
                  .printCloseShiftDesign(
                    dataCloseShift: await ref
                        .read(receiptProvider.notifier)
                        .dataCloseShift(false, shiftModel: null),
                    isInterfaceBluetooth: false,
                    ipAddress: psm.identifierAddress!,
                    paperWidth: ReceiptPrinterService.getPaperWidth(
                      psm.paperWidth,
                    ),
                    shiftModel: newUpdateShift,
                    onError: (message, ipAd) {
                      errorIps.add(ipAd);
                    },
                  );
            } else {
              continue;
            }

            await printTask; // Wait for each prints task before proceeding
            completedRequests++; // Increment after completion
          }
        }
        if (kDebugMode) {
          prints('completedRequests: $completedRequests');
          prints('Total Printers: ${listPsm.length}');
          prints('Error IPs: $errorIps');
        }
        if (completedRequests == listPsm.length && errorIps.isNotEmpty) {
          onError(errorIps.join(', '));
          return;
        }
      } else {
        onSuccess();
        return;
      }

      onSuccess();
      return;
    } else {
      // if toggle off
      onSuccess();
      return;
    }
  }

  // void onPressSwitch(bool hasPermission) {
  //   if (!hasPermission) {
  //     DialogUtils.showNoPermissionDialogue(context);
  //     return;
  //   }
  // }

  void forceCloseShiftDialogue(ShiftModel newUpdateShift) {
    if (_globalContext == null) return;
    ConfirmDialog.show(
      _globalContext,
      onPressed: () async {
        // close the dialog confirmation
        await ref.read(pendingChangesProvider.notifier).deleteAll();
        NavigationUtils.pop(_globalContext);
        await operationAfterSyncPendingChanges(
          newUpdateShift,
          isForceCloseShift: true,
        );
      },
      description: 'pleaseContactSupport'.tr(),
      icon: const Icon(
        FontAwesomeIcons.triangleExclamation,
        color: kWarningColor,
      ),
    );
  }
}
