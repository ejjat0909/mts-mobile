import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/services/general_service.dart';
import 'package:mts/form_bloc/activate_license_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog2.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/features/login/login_screen.dart';
import 'package:mts/providers/user/user_providers.dart';

class LicenseForm extends ConsumerStatefulWidget {
  const LicenseForm({super.key});

  @override
  ConsumerState<LicenseForm> createState() => _LicenseFormState();
}

class _LicenseFormState extends ConsumerState<LicenseForm> {
  bool isLoading = false;
  final GeneralService _generalFacade = ServiceLocator.get<GeneralService>();
  var maskFormatter = MaskTextInputFormatter(
    mask: 'XXXXX-XXXXX-XXXXX-XXXXX',
    filter: {'X': RegExp(r'^[A-Za-z0-9]+$')},
    type: MaskAutoCompletionType.lazy,
  );

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog2(
          title: "Scan QR Code",
          //description: "Scan this QR code to get license key support",
          center: Image.asset(
            'assets/images/activate-licence-key-support.png',
            width: 300,
            height: 300,
          ),
          btnOkText: "Close",
          btnOkOnPress: () {
            Navigator.of(context).pop();
          },
          dialogType: DialogType.info,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final userNotifier = ref.read(userProvider.notifier);
    return BlocProvider(
      create: (context) => ActivateLicenseFormBloc(userNotifier),
      child: Builder(
        builder: (context) {
          final activateLicenseFormBloc =
              context.read<ActivateLicenseFormBloc>();
          return FormBlocListener<ActivateLicenseFormBloc, String, String>(
            onSubmitting: ((context, state) {
              FocusScope.of(context).unfocus();
              LoadingDialog.show(context);
            }),
            onSuccess: (context, state) async {
              LoadingDialog.hide(context);
              prints('ssss');

              /// [delete database]
              await _generalFacade.deleteDatabaseProcess();
              navigateToNextPage(context);

              // Navigator.pushNamedAndRemoveUntil(context, LoginScreen.routeName,
              //     (Route<dynamic> route) => false);

              // Navigator.pushAndRemoveUntil(
              //     context,
              //     MaterialPageRoute(
              //       builder: ((context) => LoginScreen()),
              //     ),
              //     (Route<dynamic> route) => false);
            },
            onFailure: (context, state) {
              LoadingDialog.hide(context);

              ThemeSnackBar.showSnackBar(context, state.failureResponse!);
            },
            onSubmissionFailed: (context, state) {
              LoadingDialog.hide(context);
            },
            child: SingleChildScrollView(
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
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(0),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Description
                      Text(
                        'licenseKeyDescription'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTheme.mediumTextStyle(),
                      ),
                      const SizedBox(height: 20),
                      // Text Input
                      Row(
                        children: [
                          Expanded(
                            child: MyTextFieldBlocBuilder(
                              isEnabled: isLoading ? false : true,
                              textFieldBloc: activateLicenseFormBloc.license,
                              labelText: 'licenseKey'.tr(),
                              hintText: 'XXXXX-XXXXX-XXXXX-XXXXX',
                              inputFormatters: [
                                maskFormatter,
                                FormatUtils.upperCaseFormatter(),
                              ],
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                        ],
                      ),
                      ButtonBottom(
                        'activate'.tr(),
                        press: () {
                          // EncryptedSharedPreferences encryptedSharedPreferences =
                          //     EncryptedSharedPreferences();
                          // encryptedSharedPreferences.clear();
                          activateLicenseFormBloc.submit();
                        },
                        isDisabled: isLoading,
                      ),
                      const SizedBox(height: 10),
                      ScaleTap(
                        onPressed: () {
                          _showQRCodeDialog();
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "Don't have a license key? Click here",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      // ButtonBottom(
                      //   "activate".tr(),
                      //   press: () async {
                      //     // get all data from database
                      //     await GeneralBloc.getAllDataFromLocalDb(
                      //       context,
                      //       mounted,
                      //       (loading) {
                      //         setState(() {
                      //           isLoading = loading;
                      //         });
                      //       },
                      //       isDownloadData: (isDownloadData) {
                      //         setState(() {
                      //           _isDownloadData = isDownloadData;
                      //         });
                      //       },
                      //     );

                      //     if (!_isDownloadData) {
                      //       navigateToNextPage(context);
                      //     }
                      //   },
                      //   isDisabled: isLoading,
                      // ),
                      // const Space(10),
                      // ButtonBottom(
                      //   "Delete and Seed Database",
                      //   press: () async {
                      //     // delete database
                      //     await GeneralBloc.deleteDatabaseProcess();

                      //     // seeding process
                      //     if (mounted) {
                      //       await GeneralBloc.seedingProcess(context,
                      //           (loading) {
                      //         setState(() {
                      //           isLoading = loading;
                      //         });
                      //       });
                      //     }
                      //   },
                      //   isDisabled: isLoading,
                      // ),
                      // const Space(10),

                      // ButtonTertiary(
                      //     onPressed: () {
                      //       Navigator.push(
                      //           context,
                      //           MaterialPageRoute(
                      //               builder: (_) => const DatabaseList()));
                      //     },
                      //     text: "Local DB")
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void navigateToNextPage(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: ((context) => const LoginScreen())),
      (Route<dynamic> route) => false,
    );
  }
}
