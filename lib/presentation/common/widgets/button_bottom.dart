import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';

class ButtonBottom extends StatefulWidget {
  final bool isDisabled;
  final Function() press;
  final String text;
  final IconData? iconData;
  final String? loadingText;
  final bool haveSpinner;

  const ButtonBottom(
    this.text, {
    super.key,
    this.isDisabled = false,
    required this.press,
    this.iconData,
    this.loadingText,
    this.haveSpinner = true,
  });

  @override
  State<ButtonBottom> createState() => _ButtonBottomState();
}

class _ButtonBottomState extends State<ButtonBottom> {
  final spinner = SizedBox(
    height: 24,
    width: 24,
    child: SpinKitDoubleBounce(color: kWhiteColor),
  );

  // Create the AnimatedTextKit widget once to prevent rebuilds
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return ScaleTap(
      onPressed: widget.isDisabled ? null : widget.press,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: widget.isDisabled ? kTextGray : kPrimaryColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight / 55),
          child: widget.isDisabled ? cannotPress() : canPress(),
        ),
      ),
    );
  }

  Widget canPress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        widget.iconData != null
            ? Icon(widget.iconData, color: kWhiteColor)
            : const SizedBox(),
        SizedBox(width: widget.iconData != null ? 15 : 0),
        Text(
          widget.text,
          style: textStyleNormal(
            color: kWhiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget cannotPress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.loadingText ?? 'pleaseWait'.tr(),
          style: textStyleNormal(
            color: kWhiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        //  _loadingAnimation,
        if (widget.haveSpinner)
          SizedBox(width: widget.iconData != null ? 15.w : 0),
        if (widget.haveSpinner) spinner,
      ],
    );
  }
}
