import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class EmptyReceipt extends StatefulWidget {
  const EmptyReceipt({super.key});

  @override
  State<EmptyReceipt> createState() => _EmptyReceiptState();
}

class _EmptyReceiptState extends State<EmptyReceipt> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.receipt,
            size: 100,
            color: kTextGray.withValues(alpha: 0.5),
          ),
          Space(40.h),
          Text('pleaseChooseReceipt'.tr(), style: AppTheme.mediumTextStyle()),
        ],
      ),
    );
  }
}
