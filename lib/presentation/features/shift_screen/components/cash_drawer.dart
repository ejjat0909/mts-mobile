import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/providers/cash_management/cash_management_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';

class CashDrawer extends ConsumerStatefulWidget {
  const CashDrawer({super.key});

  @override
  ConsumerState<CashDrawer> createState() => _CashDrawerState();
}

class _CashDrawerState extends ConsumerState<CashDrawer> {
  ShiftModel shiftModel = ShiftModel();

  @override
  void initState() {
    super.initState();
    getShiftModel();
  }

  Future<void> getShiftModel() async {
    shiftModel = await ref.read(shiftProvider.notifier).getLatestShift();
    //prints(shiftModel.toJson());
    setState(() {});
    // Trigger expected amount calculation is handled by provider
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            startingCash(),
            SizedBox(height: 40.h),
            cashPayment(),
            SizedBox(height: 20.h),
            cashRefund(),
            SizedBox(height: 20.h),
            payIn(),
            SizedBox(height: 20.h),
            payOut(),
            SizedBox(height: 20.h),
            const Divider(thickness: 1),
            SizedBox(height: 20.h),
            expectedCashAmount(),
          ],
        ),
      ),
    );
  }

  Row expectedCashAmount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'expectedCashAmount'.tr(),
            style: AppTheme.normalTextStyle(),
          ),
        ),
        Expanded(
          child: StreamBuilder<double>(
            stream:
                ref
                    .read(shiftProvider.notifier)
                    .getLatestExpectedAmountStream(),
            builder: (context, snapshot) {
              return Text(
                'RM'.tr(args: [(snapshot.data ?? 0.0).toStringAsFixed(2)]),
                style: AppTheme.normalTextStyle(),
                textAlign: TextAlign.end,
              );
            },
          ),
        ),
      ],
    );
  }

  Row payOut() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text('payOut'.tr(), style: AppTheme.normalTextStyle())),
        Expanded(
          child: StreamBuilder<double>(
            stream:
                ref.read(cashManagementProvider.notifier).getSumPayOutStream,
            builder: (context, snapshot) {
              return Text(
                'RM'.tr(args: [(snapshot.data ?? 0.0).toStringAsFixed(2)]),
                style: AppTheme.normalTextStyle(),
                textAlign: TextAlign.end,
              );
            },
          ),
        ),
      ],
    );
  }

  Row payIn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text('payIn'.tr(), style: AppTheme.normalTextStyle())),
        Expanded(
          child: StreamBuilder<double>(
            stream: ref.read(cashManagementProvider.notifier).getSumPayInStream,
            builder: (context, snapshot) {
              return Text(
                'RM'.tr(args: [(snapshot.data ?? 0.0).toStringAsFixed(2)]),
                style: AppTheme.normalTextStyle(),
                textAlign: TextAlign.end,
              );
            },
          ),
        ),
      ],
    );
  }

  Row cashRefund() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text('cashRefund'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child: FutureBuilder<double>(
            future:
                ref.read(receiptProvider.notifier).calcPayableAmountRefunded(),
            builder: (context, snapshot) {
              return Text(
                'RM'.tr(args: [(snapshot.data ?? 0.0).toStringAsFixed(2)]),
                style: AppTheme.normalTextStyle(),
                textAlign: TextAlign.end,
              );
            },
          ),
        ),
      ],
    );
  }

  Row cashPayment() {
    return Row(
      children: [
        Expanded(
          child: Text('cashPayment'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child: FutureBuilder<double>(
            future:
                ref
                    .read(receiptProvider.notifier)
                    .calcPayableAmountNotRefunded(),
            builder: (context, snapshot) {
              return Text(
                'RM'.tr(args: [(snapshot.data ?? 0.0).toStringAsFixed(2)]),
                style: AppTheme.normalTextStyle(),
                textAlign: TextAlign.end,
              );
            },
          ),
        ),
      ],
    );
  }

  Row startingCash() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'startingCash'.tr(),
            style: AppTheme.mediumTextStyle(color: canvasColor),
          ),
        ),
        Expanded(
          child: Text(
            'RM'.tr(
              args: [shiftModel.startingCash?.toStringAsFixed(2) ?? '0.00'],
            ),
            style: AppTheme.mediumTextStyle(color: canvasColor),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
