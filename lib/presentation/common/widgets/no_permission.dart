import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class NoPermission extends StatelessWidget {
  final String? btnText;
  final Function()? onPressed;
  const NoPermission({super.key, this.btnText, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(FontAwesomeIcons.lock, color: kDisabledText, size: 60),
        Space(15.h),
        Text(
          'youDontHavePermissionForThisAction'.tr(),
          style: textStyleMedium(color: kDisabledText),
        ),
        15.heightBox,
        onPressed != null
            ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ButtonPrimary(
                  onPressed: () async {
                    await Future.delayed(Duration(milliseconds: 200));
                    onPressed!();
                  },
                  text: btnText ?? '',
                ),
              ],
            )
            : const SizedBox(),
      ],
    );
  }
}
