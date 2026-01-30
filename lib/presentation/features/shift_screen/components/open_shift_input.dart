import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/shift_screen/components/open_shift_dialogue.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';

class OpenShift extends ConsumerStatefulWidget {
  final BuildContext homeContext;
  const OpenShift({super.key, required this.homeContext});

  @override
  ConsumerState<OpenShift> createState() => _OpenShiftState();
}

class _OpenShiftState extends ConsumerState<OpenShift> {
  @override
  void initState() {
    super.initState();
    // retrieve  or checking context  from close  shift
    prints('dapatkan context');
  }

  @override
  Widget build(BuildContext context) {
    return requestOpenShift();
  }

  Widget requestOpenShift() {
    // use expanded and scrollview to handle scrolling when open keyboard in the dialogue
    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(
            top: 50,
            left: 100,
            right: 100,
            bottom: 20,
          ),
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          height: MediaQuery.of(context).size.height / 1.5,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(10.sp),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 100.h, color: canvasColor),
              const Space(10),
              Text('shiftIsClosed'.tr(), style: AppTheme.h1TextStyle()),
              const Space(10),
              Text(
                'openAShiftToPerformSales'.tr(),
                style: AppTheme.h1TextStyle(),
              ),
              const Space(20),
              ButtonPrimary(
                onPressed: () async {
                  await handleOnPressOpenShift();
                },
                textStyle: textStyleNormal(
                  color: kWhiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
                text: 'openShift'.tr(),
                size: Size(500.w, 70.h),
              ),
              if (kDebugMode) ...[
                const Space(20),
                ButtonPrimary(
                  onPressed: () async {
                    await NavigationUtils.navigateToLocalDB(context);
                  },
                  textStyle: textStyleNormal(
                    color: kWhiteColor,
                    fontSize: 16.sp,
                  ),
                  text: 'Local DB'.tr(),
                ),
                const Space(20),
                ButtonBottom(
                  "Check access token",
                  isDisabled: false,
                  press: () async {
                    final SecureStorageApi secureStorageApi =
                        ServiceLocator.get<SecureStorageApi>();
                    String? userToken = await secureStorageApi.read(
                      key: 'access_token',
                    );

                    String? staffAccessToken = await secureStorageApi.read(
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleOnPressOpenShift() async {
    String? printNotFoundMessage;
    await ref.read(printerSettingProvider.notifier).openCashDrawerManually((
      errorMessage,
    ) {
      // ThemeSnackBar.showSnackBar(context, errorMessage);
      printNotFoundMessage = errorMessage;
      setState(() {});
    }, activityFrom: 'Open shift');
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return OpenShiftDialogue(
            homeContext: context,
            printerNotFoundMessage: printNotFoundMessage,
          );
        },
      );
    }
  }
}
