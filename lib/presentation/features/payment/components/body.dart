import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/payment_navigator_enum.dart';
import 'package:mts/presentation/features/payment/components/order_list_payment.dart';
import 'package:mts/presentation/features/payment/components/payment_details.dart';
import 'package:mts/presentation/features/payment_sale_summary/payment_sale_summary.dart';
import 'package:mts/presentation/features/split_payment/split_payment_details.dart';
import 'package:mts/providers/payment/payment_providers.dart';

class Body extends ConsumerWidget {
  final BuildContext orderListContext;
  const Body({super.key, required this.orderListContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentProvider);
    final paymentNavigator = paymentState.paymentNavigator;

    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [const OrderListPayment(), getPaymentBody(paymentNavigator)],
      ),
    );
  }

  Widget getPaymentBody(int navigator) {
    if (navigator == PaymentNavigatorEnum.paymentScreen) {
      return PaymentDetails(orderListContext: orderListContext);
    } else if (navigator == PaymentNavigatorEnum.splitPayment) {
      return const SplitPaymentDetails();
    } else {
      return const PaymentSaleSummary();
    }
  }
}
