import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/form_bloc/choose_device_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/layouts/gradient_icon.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/styled_dropdown.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/pending_changes/pending_changes_providers.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';

class ChoosePosDeviceBody extends ConsumerStatefulWidget {
  final int currentBodyIndex;

  const ChoosePosDeviceBody({super.key, required this.currentBodyIndex});

  @override
  ConsumerState<ChoosePosDeviceBody> createState() =>
      _ChoosePosDeviceBodyState();
}

class _ChoosePosDeviceBodyState extends ConsumerState<ChoosePosDeviceBody> {
  int _currentBodyIndex = 0;
  String errorMessage = '';
  bool _isLoading = false;
  PosDeviceModel selectedDevice = PosDeviceModel(
    id: '-1',
    name: 'allDevice'.tr(),
  );
  OutletModel outletModel = ServiceLocator.get<OutletModel>();
  List<PosDeviceModel> listDevices = [];

  static final SecureStorageApi _secureStorageApi =
      ServiceLocator.get<SecureStorageApi>();

  //   DeviceModel(id: "-1", name: "All Device"),
  //   DeviceModel(id: "1", name: 'Device 1'),
  //   DeviceModel(id: "2", name: 'Device 2'),
  //   DeviceModel(id: "3", name: 'Device 3'),
  //   // Add more devices as needed
  // ];

  @override
  void initState() {
    super.initState();
    _currentBodyIndex = widget.currentBodyIndex;
    getListDevice();
  }

  getListDevice() {
    listDevices = ref.read(deviceProvider).items;
    listDevices =
        listDevices
            .where(
              (element) =>
                  element.outletId == outletModel.id &&
                  element.isActive == false,
            )
            .toList();
    if (listDevices.isNotEmpty) {
      listDevices.insert(
        0,
        PosDeviceModel(id: '-1', name: 'allDevice'.tr(), isActive: false),
      );

      selectedDevice = listDevices[0];
      setState(() {});
    }

    // selectedDevice = listDevices.firstWhere((device) => true);
    // if (listDevices.isNotEmpty) selectedDevice = listDevices[0];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: 448.w,
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth / 3.5,
            vertical: 0.h,
          ),
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                offset: const Offset(8, 20),
                blurRadius: 25,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              BoxShadow(
                offset: const Offset(0, 10),
                blurRadius: 10,
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    child: Transform.rotate(
                      angle: 90 * math.pi / 180,
                      child: const GradientIcon(
                        FontAwesomeIcons.tabletScreenButton,
                        100,
                        kPrimaryGradientColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Description
                Text(
                  'chooseDeviceDescription'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.h1TextStyle(),
                ),
                const SizedBox(height: 20),
                BlocProvider(
                  create: (context) => ChooseDeviceFormBloc(),
                  child: Builder(
                    builder: (context) {
                      final chooseDeviceFormBloc =
                          context.read<ChooseDeviceFormBloc>();
                      return FormBlocListener<
                        ChooseDeviceFormBloc,
                        String,
                        String
                      >(
                        onSubmitting: (context, state) {},
                        onSuccess: (context, state) async {
                          final deviceNotifier = ref.read(
                            deviceProvider.notifier,
                          );
                          PosDeviceModel? deviceModel = await deviceNotifier
                              .getDeviceModelById(state.successResponse!);
                          if (deviceModel?.id != null) {
                            // save to secure storage
                            await _secureStorageApi.saveObject(
                              'device',
                              deviceModel!,
                            );

                            // save to GetIt
                            deviceNotifier.setGetIt(deviceModel);

                            // update the chosen device to make it active
                            PosDeviceModel updatedDeviceModel = deviceModel
                                .copyWith(isActive: true);

                            await deviceNotifier.update(updatedDeviceModel);

                            /// [seeding process]
                            if (mounted) {
                              LoadingDialog.show(context);
                              // sync dulu untuk hantar device model ke api, so boleh check
                              // if shift is open or not

                              final pendingChangesNotifier = ref.read(
                                pendingChangesProvider.notifier,
                              );
                              await pendingChangesNotifier
                                  .syncPendingChangesList();
                              // panggil api latest shift
                              // if  (shiftModel.id == null) {
                              //   - proceed to login pin
                              //   - staff need to insert pin
                              //   - then panggil api login pin
                              //   - kalau api login pin sukses, panggil seeding process
                              //   - kalau tak sukses, cre
                              // }
                              // this include sync real time and seeding process
                              // refresh data base
                              // dah tak perlu delete database sebab dah tak guna konsep refresh
                              //  await GeneralBloc.deleteDatabaseProcess();

                              LoadingDialog.hide(context);
                              // seeding process have function to download image
                              // future me, dont worry about downloading image here
                              // because we already download all images in seeding process

                              /// this part no need for loading dialog because it will auto trigger another loading dialogue
                              await ref
                                  .read(syncRealTimeProvider.notifier)
                                  .seedingProcess(
                                    'After choose POS Device onSuccess',
                                    (loading) {
                                      setState(() {
                                        _isLoading = loading;
                                      });

                                      if (!_isLoading) {
                                        ref
                                            .read(myNavigatorProvider.notifier)
                                            .setPageIndex(
                                              _currentBodyIndex + 1,
                                              'pinLock'.tr(),
                                            );
                                      }
                                    },
                                    isInitData: true,
                                    needToDownloadImage: true,
                                  );
                            }
                          } else {
                            prints('device model id is null');
                          }
                        },
                        onFailure: (context, state) {
                          errorMessage = state.failureResponse!;
                          setState(() {});
                        },
                        onSubmissionFailed: (context, state) {},
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StyledDropdown<PosDeviceModel>(
                              items:
                                  listDevices.map<
                                    DropdownMenuItem<PosDeviceModel>
                                  >((PosDeviceModel model) {
                                    return DropdownMenuItem<PosDeviceModel>(
                                      value: model, // Set the value to the ID
                                      child: Text(
                                        model.name.toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              selected: selectedDevice,
                              list: listDevices,
                              setDropdownValue: (value) {
                                setState(() {
                                  selectedDevice = listDevices.firstWhere(
                                    (model) => model.id == value.id,
                                  ); // Find the model based on the ID
                                  // prints(selectedDivision.id);
                                  chooseDeviceFormBloc.deviceModel.updateValue(
                                    selectedDevice.id!.toString(),
                                  );
                                });
                              },
                            ),
                            SizedBox(height: errorMessage != '' ? 5 : 0),
                            errorMessage != ''
                                ? Text(
                                  ' $errorMessage',
                                  style: const TextStyle(color: kTextRed),
                                  textAlign: TextAlign.start,
                                )
                                : Container(),
                            const SizedBox(height: 20),
                            ButtonBottom(
                              press: () {
                                chooseDeviceFormBloc.submit();
                              },
                              'next'.tr(),
                            ),
                            SizedBox(height: 10.h),
                            ButtonTertiary(
                              onPressed: () {
                                ref
                                    .read(myNavigatorProvider.notifier)
                                    .setPageIndex(
                                      _currentBodyIndex - 1,
                                      'chooseStore'.tr(),
                                    );
                              },
                              text: 'back'.tr(),
                            ),
                          ],
                        ),
                      );
                    },
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
