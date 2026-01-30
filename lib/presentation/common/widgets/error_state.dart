import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class ErrorState extends StatelessWidget {
  final Object error;
  final Function() onRetry;
  const ErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.triangleExclamation,
            color: kTextGray,
            size: 48,
          ),
          const Space(10),
          Text(
            'error'.tr(),
            style: textStyleGray(),
            textAlign: TextAlign.center,
          ),
          Text('$error', style: textStyleGray(), textAlign: TextAlign.center),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(FontAwesomeIcons.arrowsRotate),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: kPrimaryColor,
              foregroundColor: white,
            ),
          ),
        ],
      ),
    );
  }
}
