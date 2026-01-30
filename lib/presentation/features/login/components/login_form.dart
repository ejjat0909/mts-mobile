import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/services/general_service.dart';
import 'package:mts/form_bloc/login_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/confirm_dialogue.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/activate_license/activate_license_screen.dart';
import 'package:mts/presentation/features/after_login/after_login_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  bool isChecked = false;
  bool _isLoading = false;
  late Future<String> companyName;
  static final SecureStorageApi _secureStorageApi =
      ServiceLocator.get<SecureStorageApi>();
  final GeneralService _generalFacade = ServiceLocator.get<GeneralService>();
  @override
  void initState() {
    companyName = getCompanyName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return BlocProvider(
      create: (context) => LoginFormBloc(ref.read(userProvider.notifier)),
      child: Builder(
        builder: (context) {
          final loginFormBloc = context.read<LoginFormBloc>();
          return FormBlocListener<LoginFormBloc, String, String>(
            onSubmitting: ((context, state) {
              setState(() {
                _isLoading = true;
              });
              FocusScope.of(context).unfocus();
              // LoadingDialog.show(context);
            }),
            onSuccess: (context, state) async {
              setState(() {
                _isLoading = false;
              });

              String licenseKey = await _secureStorageApi.read(
                key: 'license_key',
              );
              prints('🟡🟡🟡🟡🟡🟡🟡🟡license key: $licenseKey');
              // context.read<MyNavigator>().setPageIndex(0, 'chooseStore'.tr());
              // Navigator.pushAndRemoveUntil(
              //   context,
              //   MaterialPageRoute(
              //     builder: ((context) => const AfterLoginScreen()),
              //   ),
              //   (Route<dynamic> route) => false,
              // );
              // return;
              // LoadingDialog.hide(context);
              await _generalFacade.deleteDatabaseProcess();

              /// [seeding process]
              if (mounted) {
                await ref
                    .read(syncRealTimeProvider.notifier)
                    .seedingProcess(
                      'Login Form On Success',
                      (loading) {
                        setState(() {
                          _isLoading = loading;
                        });
                        if (!_isLoading) {
                          if (mounted) {
                            ref
                                .read(myNavigatorProvider.notifier)
                                .setPageIndex(0, 'chooseStore'.tr());

                            prints('INIT PUSHER AFTER SIGN IN');
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder:
                                    ((context) => const AfterLoginScreen()),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          }
                        }
                      },

                      isInitData: true,
                      needToDownloadImage: false,
                    );
              }

              // // Check if the device type is null or not
              // String deviceType = await SecureStorageApi.read(key: "device_type");

              // if (deviceType == "") {
              // Means not choose device type yet

              // Navigator.pushAndRemoveUntil(
              //     context,
              //     MaterialPageRoute(
              //       builder: ((context) => const ChooseDeviceTypeScreen()),
              //     ),
              //     (Route<dynamic> route) => false);

              // } else {
              //   Navigator.pushAndRemoveUntil(
              //       context,
              //       MaterialPageRoute(
              //         builder: ((context) => MyHomePage()),
              //       ),
              //       (Route<dynamic> route) => false);
              // }
            },
            onFailure: (context, state) {
              setState(() {
                _isLoading = false;
              });
              // LoadingDialog.hide(context);
              if (state.failureResponse != null) {
                ThemeSnackBar.showSnackBar(context, state.failureResponse!);
              }
            },
            onSubmissionFailed: (context, state) {
              setState(() {
                _isLoading = false;
              });
              // LoadingDialog.hide(context);
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
                        width: 178,
                        height: 178,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(15),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      FutureBuilder<String>(
                        future: companyName,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            if (snapshot.data != '') {
                              return Text(
                                snapshot.data!,
                                style: AppTheme.h1TextStyle(),
                              );
                            } else {
                              return Container();
                            }
                          }
                          // if no connection
                          return Container();
                        },
                      ),
                      // Sign In H1
                      // GestureDetector(
                      //   onTap: () {
                      //     // Show Dialog to Activate Key
                      //     CustomDialog.show(
                      //       context,
                      //       headerLeftIcon: SizedBox(),
                      //       // isDissmissable: false,
                      //       horizontalDialogPadding: 400,
                      //       header: Padding(
                      //         padding: const EdgeInsets.all(8.0),
                      //         child: Row(
                      //           mainAxisAlignment:
                      //               MainAxisAlignment.center,
                      //           children: [
                      //             Icon(Icons.key),
                      //             SizedBox(
                      //               width: 10,
                      //               height: 20,
                      //             ),
                      //             Text(
                      //               AppLocalizations.of(context)!
                      //                   .activateLicenseKey,
                      //               textAlign: TextAlign.center,
                      //               style: TextStyle(
                      //                   fontSize: 20,
                      //                   fontWeight:
                      //                       FontWeight.bold),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //       content:
                      //           LicenseActivationDialogContent(),
                      //     );
                      //   },
                      //   child: Padding(
                      //     padding: const EdgeInsets.all(8.0),
                      //     child: Text(
                      //       "Mahiran Digital Sdn Bhd",
                      //       style: AppTheme.h1TextStyle(),
                      //     ),
                      //   ),
                      // ),
                      // Sign In H1
                      Text('sign'.tr(), style: AppTheme.mediumTextStyle()),
                      SizedBox(height: 25.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Column(
                          children: [
                            //  Email Input Field
                            MyTextFieldBlocBuilder(
                              textFieldBloc: loginFormBloc.email,
                              labelText: 'email'.tr(),
                              hintText: 'emailHint'.tr(),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            // Password Input Field
                            MyTextFieldBlocBuilder(
                              isObscureText: true,
                              textFieldBloc: loginFormBloc.password,
                              labelText: 'password'.tr(),
                              hintText: 'passwordHint'.tr(),
                            ),

                            // mohsin suruh buang
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.end,
                            //   children: [
                            //     Padding(
                            //       padding: EdgeInsets.only(
                            //           right: 12.w, top: 10.h, bottom: 10.h),
                            //       child: Center(
                            //         child: Row(
                            //           children: [
                            //             RichText(
                            //               text: TextSpan(
                            //                 text: 'forgotPassword'.tr(),
                            //                 style: const TextStyle(
                            //                   color: kPrimaryColor,
                            //                 ),
                            //                 recognizer: TapGestureRecognizer()
                            //                   ..onTap = () {
                            //                     Navigator.of(context).push(
                            //                       MaterialPageRoute(
                            //                         builder: (BuildContext
                            //                                 context) =>
                            //                             const ForgotPassword(),
                            //                       ),
                            //                     );
                            //                   },
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            const SizedBox(height: 10),

                            const SizedBox(height: 10),
                            ButtonBottom(
                              'sign'.tr(),
                              loadingText: 'synchronizing'.tr(),
                              isDisabled: _isLoading,
                              press: () {
                                loginFormBloc.submit();
                              },
                              haveSpinner: false,
                            ),
                            10.heightBox,
                            ScaleTap(
                              onPressed: () {
                                ConfirmDialog.show(
                                  context,
                                  description: 'changeLicenseDescription'.tr(),
                                  onPressed: () async {
                                    // Close confirmation dialog
                                    NavigationUtils.pop(context);
                                    // Show loading
                                    LoadingDialog.show(context);

                                    // Hide dialog
                                    if (mounted) {
                                      LoadingDialog.hide(context);

                                      // Navigate to license screen
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              ((context) =>
                                                  const LicenseScreen()),
                                        ),
                                        (Route<dynamic> route) => false,
                                      );
                                    }

                                    // Call the changeLicense function from the UserBloc
                                    await ref
                                        .read(userProvider.notifier)
                                        .changeLicense(context);
                                  },
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Text(
                                  'changeLicenseKey'.tr(),
                                  style: textStyleNormal(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),

                            if (kDebugMode) 20.heightBox,
                            if (kDebugMode)
                              ButtonBottom(
                                "Check access token",
                                loadingText: 'synchronizing'.tr(),
                                isDisabled: _isLoading,
                                press: () async {
                                  String? userToken = await _secureStorageApi
                                      .read(key: 'access_token');

                                  String? staffAccessToken =
                                      await _secureStorageApi.read(
                                        key: 'staff_access_token',
                                      );

                                  try {
                                    ThemeSnackBar.showSnackBar(
                                      context,
                                      'user token : $userToken\n'
                                      'staff access token : '
                                      '$staffAccessToken',
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
                      ),
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

  Future<String> getCompanyName() async {
    // Get the company Name
    final companyName = await _secureStorageApi.read(key: 'company_name');
    return companyName.isEmpty ? '' : companyName;
  }
}
