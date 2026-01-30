import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/temp/temp_model.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_providers.dart';

class ClockInSuccess extends ConsumerStatefulWidget {
  final BuildContext afterLoginContext;
  final int currentIndex;
  final bool? isFromHome;
  final TempModel? tempModel;

  const ClockInSuccess({
    super.key,
    required this.currentIndex,
    this.isFromHome = false,
    this.tempModel,
    required this.afterLoginContext,
  });

  @override
  ConsumerState<ClockInSuccess> createState() => _ClockInSuccessState();
}

class _ClockInSuccessState extends ConsumerState<ClockInSuccess> {
  DateTime now = DateTime.now();
  String formattedTime = '';

  @override
  void initState() {
    formattedTime = DateFormat('h:mm a | dd MMM yyyy', 'en_US').format(now);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300.h,
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth / 3.5,
                vertical: 0.h,
              ),
              padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 25.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(8, 20),
                    blurRadius: 25,
                    color: Colors.black.withValues(alpha: 0.02),
                  ),
                  BoxShadow(
                    offset: const Offset(0, 10),
                    blurRadius: 10,
                    color: Colors.black.withValues(alpha: 0.02),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.clock,
                          color: kPrimaryColor,
                        ),
                        SizedBox(height: 10.h),
                        Text('clockIn'.tr(), style: AppTheme.h1TextStyle()),
                        Text(
                          'clockInTime'.tr(args: [formattedTime]),
                          style: AppTheme.grayTextStyle(),
                        ),
                      ],
                    ),
                  ),
                  ButtonBottom(
                    'confirm'.tr(),
                    press: () async {
                      await onPressConfirm(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onPressConfirm(BuildContext context) async {
    final dialogueNav = ref.read(myNavigatorProvider.notifier);
    final syncRealTimeNotifier = ref.read(syncRealTimeProvider.notifier);
    // fix when lock staff and clock in new staff

    // get last page index because app is paused
    final lastPageIndex = dialogueNav.lastPageIndex;
    if (lastPageIndex == null) {
      NavigationUtils.pushRemoveUntil(context, screen: const Home());
    } else {
      // close pin and show last page

      NavigationUtils.pop(widget.afterLoginContext);

      await Future.delayed(const Duration(milliseconds: 50));

      await dialogueNav.setUINavigatorAndIndex();
      await syncRealTimeNotifier.onSyncOrder(
        context,
        false,
        manuallyClick: false,
        isAfterActivateLicense: false,
        needToDownloadImage: true,
        onlyCheckPendingChanges: false,
        isSuccess: (isSuccess, errorMessage) {},
      );
    }
  }
}
