import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/form_bloc/choose_store_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/layouts/gradient_icon.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/common/widgets/styled_dropdown.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/user/user_providers.dart';
import 'package:sqlite_viewer2/sqlite_viewer.dart';

class ChooseStoreBody extends ConsumerStatefulWidget {
  final int currentBodyIndex;

  const ChooseStoreBody({super.key, required this.currentBodyIndex});

  @override
  ConsumerState<ChooseStoreBody> createState() => _ChooseStoreBodyState();
}

class _ChooseStoreBodyState extends ConsumerState<ChooseStoreBody> {
  int _currentBodyIndex = 0;
  String errorMessage = '';
  OutletModel selectedOutlet = OutletModel(id: '-1', name: 'allStores'.tr());
  List<OutletModel> listOutlets = [];
  static final SecureStorageApi _secureStorageApi =
      ServiceLocator.get<SecureStorageApi>();

  //   OutletModel(id: "-1", name: "All Store"),
  //   OutletModel(id: "1", name: 'Store 1'),
  //   OutletModel(id: "2", name: 'Store 2'),
  //   OutletModel(id: "3", name: 'Store 3'),
  //   // Add more devices as needed
  // ];

  @override
  void initState() {
    super.initState();
    _currentBodyIndex = widget.currentBodyIndex;
    getListOutlet();
  }

  void getListOutlet() {
    listOutlets = ref.read(outletProvider).items;

    if (listOutlets.isNotEmpty) {
      // Check if id '-1' doesn't already exist before inserting
      if (!listOutlets.any((outlet) => outlet.id == '-1')) {
        listOutlets.insert(0, OutletModel(id: '-1', name: 'allStores'.tr()));
      }

      selectedOutlet = listOutlets[0];
      setState(() {});
    }

    // selectedOutlet = listOutlets.firstWhere((device) => true);
    // if (listOutlets.isNotEmpty) selectedOutlet = listOutlets[0];
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
                  child: const GradientIcon(
                    FontAwesomeIcons.shop,
                    100,
                    kPrimaryGradientColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Description
                Text(
                  'chooseStoreDescription'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.h1TextStyle(),
                ),
                const SizedBox(height: 20),
                BlocProvider(
                  create:
                      (context) => ChooseStoreFormBloc(
                        ref.read(deviceProvider.notifier),
                      ),
                  child: Builder(
                    builder: (context) {
                      final chooseStoreFormBloc =
                          context.read<ChooseStoreFormBloc>();
                      return FormBlocListener<
                        ChooseStoreFormBloc,
                        String,
                        String
                      >(
                        onSubmitting: (context, state) {},
                        onSuccess: (context, state) async {
                          final outletNotifier = ref.read(
                            outletProvider.notifier,
                          );
                          OutletModel? outletModel = await outletNotifier
                              .getOutletModelById(state.successResponse!);
                          // save to secure storage
                          if (outletModel?.id != null) {
                            await _secureStorageApi.saveObject(
                              'outlet',
                              outletModel!,
                            );

                            // save to get it
                            outletNotifier.setGetIt(outletModel);
                            ref
                                .read(myNavigatorProvider.notifier)
                                .setPageIndex(
                                  _currentBodyIndex + 1,
                                  'choosePosDevice'.tr(),
                                );

                            listOutlets.removeWhere(
                              (element) => element.id == '-1',
                            );
                          } else {
                            prints('outlet model id is null');
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
                            StyledDropdown<OutletModel>(
                              items:
                                  listOutlets.map<
                                    DropdownMenuItem<OutletModel>
                                  >((OutletModel model) {
                                    return DropdownMenuItem<OutletModel>(
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
                              selected: selectedOutlet,
                              list: listOutlets,
                              setDropdownValue: (value) {
                                setState(() {
                                  selectedOutlet = listOutlets.firstWhere(
                                    (model) => model.id == value.id,
                                  ); // Find the model based on the ID
                                  // prints(selectedDivision.id);
                                  chooseStoreFormBloc.storeModel.updateValue(
                                    selectedOutlet.id!.toString(),
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
                                chooseStoreFormBloc.submit();
                              },
                              'next'.tr(),
                            ),
                            SizedBox(height: 10.h),
                            ButtonTertiary(
                              onPressed: () async {
                                await ref
                                    .read(userProvider.notifier)
                                    .logoutConfirmation(context);
                              },
                              text: 'back'.tr(),
                            ),
                            kDebugMode
                                ? ButtonPrimary(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const DatabaseList(),
                                      ),
                                    );
                                  },
                                  text: 'go to local db',
                                )
                                : Container(),

                            if (kDebugMode) 20.heightBox,
                            if (kDebugMode)
                              ButtonBottom(
                                "Check access token",
                                loadingText: 'synchronizing'.tr(),
                                isDisabled: false,
                                press: () async {
                                  final PosDeviceModel posDeviceModel =
                                      ServiceLocator.get<PosDeviceModel>();
                                  String? userToken = await _secureStorageApi
                                      .read(key: 'access_token');

                                  String? staffAccessToken =
                                      await _secureStorageApi.read(
                                        key: 'staff_access_token',
                                      );

                                  String? licenseKey = await _secureStorageApi
                                      .read(key: 'license_key');

                                  try {
                                    ThemeSnackBar.showSnackBar(
                                      context,
                                      'user token : $userToken\n'
                                      'staff access token : '
                                      '$staffAccessToken'
                                      '\n'
                                      'license key : $licenseKey\nposDeviceModel : ${posDeviceModel.name}',
                                    );
                                  } catch (e) {
                                    ThemeSnackBar.showSnackBar(
                                      context,
                                      "user token and staff access token are empty",
                                    );
                                  }
                                },
                                haveSpinner: false,
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
