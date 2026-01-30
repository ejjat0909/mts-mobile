import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';

class ClockOutSuccess extends ConsumerStatefulWidget {
  final int currentIndex;

  const ClockOutSuccess({super.key, required this.currentIndex});

  @override
  ConsumerState<ClockOutSuccess> createState() => _ClockOutSuccessState();
}

class _ClockOutSuccessState extends ConsumerState<ClockOutSuccess> {
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
                        Text('clockOut'.tr(), style: AppTheme.h1TextStyle()),
                        Text(
                          'clockOutTime'.tr(args: [formattedTime]),
                          style: AppTheme.grayTextStyle(),
                        ),
                      ],
                    ),
                  ),
                  ButtonTertiary(
                    text: 'back'.tr(),
                    onPressed: () {
                      ref
                          .read(myNavigatorProvider.notifier)
                          .setPageIndex(widget.currentIndex - 2, 'pin'.tr());
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
}
