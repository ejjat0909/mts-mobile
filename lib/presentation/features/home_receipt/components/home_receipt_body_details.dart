import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/home_receipt_navigator_enum.dart';
import 'package:mts/presentation/features/home_receipt/components/home_receipt_details.dart';
import 'package:mts/presentation/features/home_receipt/components/refund_details.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class HomeReceiptBodyDetails extends ConsumerStatefulWidget {
  const HomeReceiptBodyDetails({super.key});

  @override
  ConsumerState<HomeReceiptBodyDetails> createState() =>
      _HomeReceiptBodyDetailsState();
}

class _HomeReceiptBodyDetailsState
    extends ConsumerState<HomeReceiptBodyDetails> {
  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptProvider);
    final receiptNavigator = receiptState.pageIndex;

    if (receiptNavigator == HomeReceiptNavigatorEnum.receiptDetails) {
      final receiptNotifier = ref.read(receiptProvider.notifier);
      return HomeReceiptDetails(receiptNotifier: receiptNotifier);
    } else if (receiptNavigator == HomeReceiptNavigatorEnum.receiptRefund) {
      return RefundDetails(homeReceiptBodyContext: context);
    } else {
      return Container();
    }
  }
}
