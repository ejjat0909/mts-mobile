import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/remote/pusher_datasource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/repositories/local/local_shift_repository_impl.dart';
import 'package:mts/domain/services/realtime/websocket_service.dart';
import 'package:mts/form_bloc/open_shift_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/row_reset_order_number.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';
import 'package:mts/providers/pending_changes/pending_changes_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/presentation/features/home/home_screen.dart';

class OpenShiftDialogue extends ConsumerStatefulWidget {
  final BuildContext homeContext;
  final String? printerNotFoundMessage;
  const OpenShiftDialogue({
    super.key,
    required this.homeContext,
    required this.printerNotFoundMessage,
  });

  @override
  ConsumerState<OpenShiftDialogue> createState() => _OpenShiftDialogueState();
}

class _OpenShiftDialogueState extends ConsumerState<OpenShiftDialogue> {
  OutletModel outletModel = ServiceLocator.get<OutletModel>();

  final SecureStorageApi secureStorageApi =
      ServiceLocator.get<SecureStorageApi>();

  bool _isLoading = false;

  OutletModel _outletModel = OutletModel();

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> getData() async {
    _outletModel =
        await ref.read(outletProvider.notifier).getLatestOutletModel() ??
        OutletModel();
    ref.read(outletProvider.notifier).addOrUpdateList([_outletModel]);
    setState(() {});
  }

  /// Runs the seeding process in background to avoid blocking UI
  /// This prevents drawer lag during heavy sync operations
  Future<void> _runSeedingProcessInBackground() async {
    // Use microtask to ensure this runs after current frame
    scheduleMicrotask(() async {
      try {
        LogUtils.log('🔄 Starting background seeding process');

        // Run seeding with optimized memory usage
        await ref
            .read(syncRealTimeProvider.notifier)
            .seedingProcess(
              'Open Shift OnSuccess - Background',
              (loading) async {
                // Handle loading state without blocking UI
                if (!loading) {
                  // Use microtask for pusher initialization to avoid blocking
                  scheduleMicrotask(() async {
                    try {
                      final wsService = WebSocketService(
                        pusherDatasource:
                            ServiceLocator.get<PusherDatasource>(),
                        shiftRepository: LocalShiftRepositoryImpl(
                          dbHelper: ServiceLocator.get<IDatabaseHelpers>(),
                        ),
                      );
                      await wsService.subscribeToLatestShift();
                      LogUtils.log(
                        '✅ Background seeding completed successfully',
                      );

                      // Initialize slideshow cache for customer display
                      await Home.initializeSlideshowCache();

                      final listItemFromNotifier = ref.read(itemProvider).items;
                      final listMoFromNotifier =
                          ref.read(modifierOptionProvider).items;
                      MenuItem.initializeCache(
                        listItemFromNotifier,
                        listMoFromNotifier,
                      );
                      prints('✅ Cache initialized for CUSTOMER DISPLAY');
                    } catch (e) {
                      LogUtils.error('❌ Error in pusher initialization: $e');
                    }
                  });
                }
              },
              isInitData: false,
              needToDownloadImage: true,
            );
      } catch (e) {
        LogUtils.error('❌ Error in background seeding process: $e');
        // Optionally show user-friendly error message
        final globalContext = navigatorKey.currentContext;
        if (globalContext != null) {
          ThemeSnackBar.showSnackBar(
            context,
            'Sync process encountered an issue but will continue in background',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight / 2,
          minHeight: availableHeight / 2,
          maxWidth: availableWidth / 1.5,
          minWidth: availableWidth / 1.5,
        ),
        child: openShiftInputBody(_outletModel),
      ),
    );
  }

  Widget logoutBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Something went wrong, please logout and re-login',
          style: textStyleNormal(fontSize: 15),
        ),
      ],
    );
  }

  Widget openShiftInputBody(OutletModel outletModel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(10.sp),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'openShift'.tr(),
                      style: AppTheme.h1TextStyle(),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40, // Minimum width of the clickable area
                      minHeight: 40, // Minimum height of the clickable area
                    ),
                    splashRadius: 20,
                    onPressed: () {
                      // close this dialogue
                      NavigationUtils.pop(context);
                    },
                    icon: const Icon(FontAwesomeIcons.xmark),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              const Divider(thickness: 1),
              SizedBox(height: 10.h),
              _outletModel.id != null
                  ? openShiftForm(outletModel)
                  : logoutBody(),
            ],
          ),
        ),
      ),
    );
  }

  BlocProvider<OpenShiftFormBloc> openShiftForm(OutletModel outletModel) {
    return BlocProvider(
      create: (context) => OpenShiftFormBloc(),
      child: Builder(
        builder: (context) {
          final openShiftFormBloc = context.read<OpenShiftFormBloc>();
          return FormBlocListener<OpenShiftFormBloc, String, String>(
            onSubmitting: (context, state) {
              setState(() {
                _isLoading = true;
              });
            },
            onSuccess: (context, state) async {
              setState(() {
                _isLoading = false;
              });
              FocusScope.of(context).unfocus();
              await Future.delayed(const Duration(milliseconds: 300));
              StaffModel staffModel = ServiceLocator.get<StaffModel>();
              PosDeviceModel deviceModel = ServiceLocator.get<PosDeviceModel>();
              ShiftModel newShiftModel = ShiftModel(
                id: IdUtils.generateUUID(),
                outletId: outletModel.id,
                openedBy: staffModel.id,
                posDeviceId: deviceModel.id,
                posDeviceName: deviceModel.name,
                startingCash: double.parse(state.successResponse!),
                expectedCash: double.parse(state.successResponse!),
              );

              int response = await ref
                  .read(shiftProvider.notifier)
                  .insert(newShiftModel);
              if (staffModel.id == null) {
                response = -1;
              }
              // update staff to assign current shift id
              await ref
                  .read(staffProvider.notifier)
                  .assignCurrentShift(staffModel.id!, newShiftModel.id!);

              if (response != 0) {
                if (response == -1) {
                  ThemeSnackBar.showSnackBar(
                    mounted ? context : widget.homeContext,
                    'Staff id not exist',
                  );
                  return;
                }
                // close this input dialogue

                ref
                    .read(myNavigatorProvider.notifier)
                    .setSelectedTab(3200, 'shiftDetails'.tr());
                ref.read(shiftProvider.notifier).setOpenShift();

                NavigationUtils.pop(context);

                // show loading dialogue for seeding
                // LoadingDialog.show(context);
                // check if pending changes is empty or not
                final result =
                    await ref
                        .read(pendingChangesProvider.notifier)
                        .syncPendingChangesList();
                // if (kDebugMode) {
                //   await secureStorageApi.checkAccessToken();
                // }
                // if empty means sync shift is success
                if (result) {
                  // seeding process first,
                  /// [seeding process] - Optimized to run in background
                  LogUtils.log('seeding process - starting in background');

                  // Run seeding process asynchronously to avoid blocking UI
                  navigateToSalesScreen();
                  await _runSeedingProcessInBackground();
                  // if (kDebugMode) {
                  //   await secureStorageApi.checkAccessToken();
                  // }
                } else {
                  // LoadingDialog.hide(context);
                  prints('ERROR CANNOT GET DATA');
                  // ThemeSnackBar.showSnackBar(
                  //   mounted ? context : widget.homeContext,
                  //   'Cannot get data',
                  // );
                }
              } else {
                ThemeSnackBar.showSnackBar(
                  mounted ? context : widget.homeContext,
                  'cannotCreateShift'.tr(),
                );
              }
            },
            onFailure: (context, state) {
              setState(() {
                _isLoading = false;
              });
            },
            onSubmissionFailed: (context, state) {
              setState(() {
                _isLoading = false;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'openShiftDescription'.tr(),
                  style: AppTheme.normalTextStyle(),
                ),
                10.heightBox,
                RowResetOrderNumber(outletModel: outletModel),
                MyTextFieldBlocBuilder(
                  textFieldBloc: openShiftFormBloc.openShift,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    prints(value);
                  },
                  labelText: 'openShift'.tr(),
                  leading: Padding(
                    padding: EdgeInsets.only(
                      top: 20.h,
                      left: 10.w,
                      right: 10.w,
                      bottom: 20.h,
                    ),
                    child: Text(
                      'RM'.tr(args: ['']),
                      style: AppTheme.mediumTextStyle(color: canvasColor),
                    ),
                  ),
                  hintText: '0.00',
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 10),
                ButtonBottom(
                  press: () {
                    openShiftFormBloc.submit();
                  },
                  isDisabled: _isLoading,
                  'openShift'.tr(),
                ),
                if (widget.printerNotFoundMessage != null &&
                    widget.printerNotFoundMessage!.isNotEmpty) ...[
                  10.heightBox,
                  Text(
                    widget.printerNotFoundMessage!,
                    style: textStyleNormal(color: kTextRed),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void navigateToSalesScreen() {
    // // Store sidebar state for restoration when unlocking shift
    // ref.read(myNavigatorProvider.notifier).setTempSidebarState(1000, 'sales'.tr());

    ref.read(myNavigatorProvider.notifier).setPageIndex(1000, 'sales'.tr());

    // Set the selected tab to 0 for sales page (required for proper navigation)
    ref.read(myNavigatorProvider.notifier).setSelectedTab(0, '');
  }
}
