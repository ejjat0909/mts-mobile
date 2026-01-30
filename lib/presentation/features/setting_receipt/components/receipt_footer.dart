import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/custom_switch.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class ReceiptFooter extends StatefulWidget {
  const ReceiptFooter({super.key});

  @override
  State<ReceiptFooter> createState() => _ReceiptFooterState();
}

class _ReceiptFooterState extends State<ReceiptFooter> {
  bool isShowComment = false;
  TextEditingController receiptFooterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [printedReceiptSwitch(), Space(20.h), receiptFooterField()],
      ),
    );
  }

  Column receiptFooterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'receiptFooter'.tr(),
          style: const TextStyle(fontWeight: FontWeight.normal),
        ),
        Space(5.h),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: MyTextFormField(
                controller: receiptFooterController,
                labelText: 'receiptFooter',
                hintText: 'See you again',
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIconColor: kTextGray,
                  suffixIconColor: kTextGray,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: kTextGray),
                    gapPadding: 10,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPrimaryColor),
                    gapPadding: 10,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: kTextGray),
                    gapPadding: 10,
                  ),
                  fillColor: white,
                  filled: true,
                  labelStyle: AppTheme.normalTextStyle(fontSize: 16),
                  // labelText: labelText,
                  hintText: 'See you again',
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: ButtonTertiary(
                onPressed: () {},
                text: 'save'.tr(),
                icon: Icons.save_alt_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Row printedReceiptSwitch() {
    return Row(
      children: [
        ScaleTap(
          onPressed: () {},
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: scaffoldBackgroundColor,
            ),
            child: const Icon(
              FontAwesomeIcons.quoteRight,
              color: kPrimaryColor,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'showComments'.tr(),
                style: AppTheme.normalTextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              Text('commentsDesc'.tr(), style: AppTheme.grayTextStyle()),
            ],
          ),
        ),
        Expanded(
          child: CustomSwitch(
            value: isShowComment,
            onChanged: (value) {
              setState(() {
                isShowComment = value;
              });
            },
          ),
        ),
      ],
    );
  }
}
