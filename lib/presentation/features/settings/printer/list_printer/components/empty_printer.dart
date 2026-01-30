import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class EmptyPrinter extends StatefulWidget {
  const EmptyPrinter({super.key});

  @override
  State<EmptyPrinter> createState() => _EmptyPrinterState();
}

class _EmptyPrinterState extends State<EmptyPrinter> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.print,
            size: 100,
            color: kTextGray.withValues(alpha: 0.5),
          ),
          Space(40.h),
          Text('noPrinter'.tr(), style: AppTheme.mediumTextStyle()),
        ],
      ),
    );
  }
}
