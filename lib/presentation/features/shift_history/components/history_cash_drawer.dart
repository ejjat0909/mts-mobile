import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/shift/shift_model.dart';

class HistoryCashDrawer extends StatefulWidget {
  final ShiftModel shiftModel;

  const HistoryCashDrawer({super.key, required this.shiftModel});

  @override
  State<HistoryCashDrawer> createState() => _HistoryCashDrawerState();
}

class _HistoryCashDrawerState extends State<HistoryCashDrawer> {
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
  }

  void getData() {
    if (widget.shiftModel.saleSummaryJson != null &&
        widget.shiftModel.saleSummaryJson!.isNotEmpty) {
      try {
        dynamic decodedData = jsonDecode(widget.shiftModel.saleSummaryJson!);
        if (decodedData is String) {
          decodedData = jsonDecode(decodedData);
        }
        if (decodedData is Map<String, dynamic>) {
          data = decodedData;
        } else {
          prints('ERROR decodedData bukan Map<String, dynamic>');
        }
      } catch (e) {
        prints('ERROR Failed to decode JSON: $e');
      }
    } else {
      prints('ERROR saleSummaryJson is null or empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    getData();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
          child: Text(
            'RM'.tr(
              args: [data['expected_cash']?.toStringAsFixed(2) ?? '0.00'],
            ),
            style: AppTheme.normalTextStyle(),
            textAlign: TextAlign.end,
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
          child: Text(
            'RM'.tr(args: [data['pay_out']?.toStringAsFixed(2) ?? '0.00']),
            style: AppTheme.normalTextStyle(),
            textAlign: TextAlign.end,
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
          child: Text(
            'RM'.tr(args: [data['pay_in']?.toStringAsFixed(2) ?? '0.00']),
            style: AppTheme.normalTextStyle(),
            textAlign: TextAlign.end,
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
          child: Text(
            'RM'.tr(args: [data['cash_refunds']?.toStringAsFixed(2) ?? '0.00']),
            style: AppTheme.normalTextStyle(),
            textAlign: TextAlign.end,
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
          child: Text(
            'RM'.tr(
              args: [data['cash_payments']?.toStringAsFixed(2) ?? '0.00'],
            ),
            style: AppTheme.normalTextStyle(),
            textAlign: TextAlign.end,
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
              args: [
                widget.shiftModel.startingCash?.toStringAsFixed(2) ?? '0.00',
              ],
            ),
            style: AppTheme.mediumTextStyle(color: canvasColor),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
