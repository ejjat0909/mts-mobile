import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class InvalidImageContainer extends StatelessWidget {
  final bool haveText;
  final bool forMenuItem;
  final String? text;

  const InvalidImageContainer({
    super.key,
    this.haveText = true,
    this.forMenuItem = true,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(7.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          forMenuItem ? const Space(30) : const SizedBox.shrink(),
          haveText
              ? Text(
                text ?? (kDebugMode ? 'invalidImageUrl'.tr() : ''),
                style: AppTheme.normalTextStyle(),
              )
              : const SizedBox(),
        ],
      ),
    );
  }
}
