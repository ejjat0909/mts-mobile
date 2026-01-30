import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/payment_navigator_enum.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/payment/payment_providers.dart';

class PaymentSaleSummary extends ConsumerStatefulWidget {
  const PaymentSaleSummary({super.key});

  @override
  ConsumerState<PaymentSaleSummary> createState() => _PaymentSaleSummaryState();
}

class _PaymentSaleSummaryState extends ConsumerState<PaymentSaleSummary> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: -4,
                    blurRadius: 35,
                    offset: const Offset(0, 9), // changes position of shadow
                  ),
                ],
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: kLightGray,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        child: Text(
                          'totalPaid'.tr(),
                          style: const TextStyle(color: kPrimaryColor),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: kLightGray,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        child: Text(
                          'change'.tr(),
                          style: const TextStyle(color: kPrimaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM52.90',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                      Text(
                        'RM7.10',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'example@ex.com',

                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            // prefixIcon: leading,
                            prefixIconColor: kTextGray,
                            // suffixIcon: Icon(trailingIcon),
                            suffixIconColor: kTextGray,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(color: kTextGray),
                              gapPadding: 10,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: kPrimaryColor,
                              ),
                              gapPadding: 10,
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(
                              15,
                              5,
                              15,
                              5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(color: kTextGray),
                              gapPadding: 10,
                            ),
                            fillColor: white,
                            filled: true,

                            // labelText: labelText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          side: const BorderSide(color: kPrimaryColor),
                        ),
                        onPressed: () => {},
                        icon: const Icon(Icons.send, color: white),
                        label: Text(
                          'sendReceipt'.tr(),
                          style: AppTheme.normalTextStyle(color: white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ButtonPrimary(
                          onPressed: () => {},
                          text: 'printReceipt'.tr(),
                        ),
                      ),
                      const SizedBox(width: 15),
                    ],
                  ),
                ],
              ),
            ),
            // to push the button to the bottom
            const Spacer(flex: 4),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ButtonPrimary(
                        onPressed: () {
                          NavigationUtils.pop(context);
                          ref
                              .read(paymentProvider.notifier)
                              .setNewPaymentNavigator(
                                PaymentNavigatorEnum.paymentScreen,
                              );
                        },
                        text: 'newSale'.tr(),
                      ),
                    ),
                    const Space(10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
