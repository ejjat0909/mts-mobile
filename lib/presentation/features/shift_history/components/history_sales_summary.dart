import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/presentation/common/widgets/no_permission_text.dart';
import 'package:mts/providers/permission/permission_providers.dart';

class HistorySalesSummary extends ConsumerStatefulWidget {
  final ShiftModel shiftModel;

  const HistorySalesSummary({super.key, required this.shiftModel});

  @override
  ConsumerState<HistorySalesSummary> createState() =>
      _HistorySalesSummaryState();
}

class _HistorySalesSummaryState extends ConsumerState<HistorySalesSummary> {
  Map<String, dynamic> data = {};
  List<Map<String, double>> paymentTypeList = [];

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
          dynamic decodedPaymentTypeList = data['payment_type'];

          if (decodedPaymentTypeList is List) {
            paymentTypeList =
                decodedPaymentTypeList.map((item) {
                  if (item is Map<String, dynamic>) {
                    return item.map(
                      (key, value) => MapEntry(key, (value as num).toDouble()),
                    );
                  } else {
                    // Return an empty map if the structure is incorrect
                    return <String, double>{};
                  }
                }).toList();
          } else {
            prints('ERROR decodedPaymentTypeList is not a List');
          }
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
    final hasPermission =
        ref.read(permissionProvider.notifier).hasViewShiftReportsPermission();
    getData();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            grossSales(hasPermission),
            SizedBox(height: 20.h),
            refunds(hasPermission),
            SizedBox(height: 20.h),
            discounts(hasPermission),
            SizedBox(height: 20.h),
            const Divider(thickness: 1),
            SizedBox(height: 20.h),
            netSales(hasPermission),
            ...paymentTypeList.map((paymentType) {
              return buildPaymentType(paymentType, hasPermission);
            }),
            SizedBox(height: 20.h),
            // related to cash, no need to check permission
            cashRounding(),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentType(
    Map<String, double> paymentTypeData,
    bool hasPermission,
  ) {
    final paymentName = paymentTypeData.keys.first;
    final paymentAmount = paymentTypeData.values.first;
    final isCashPayment = paymentName.toLowerCase().contains('cash');

    // Determine if we should show the amount (always for cash, or if has permission)
    final shouldShowAmount = isCashPayment || hasPermission;

    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Payment type label
          Expanded(
            flex: shouldShowAmount ? 1 : 2,
            child: Text(paymentName, style: AppTheme.normalTextStyle()),
          ),

          // Payment amount or no permission text
          Expanded(
            child:
                shouldShowAmount
                    ? _buildAmountText(paymentAmount)
                    : NoPermissionText(),
          ),
        ],
      ),
    );
  }

  // Helper method to build the amount text widget
  Widget _buildAmountText(double amount) {
    return Text(
      'RM'.tr(args: [amount.toStringAsFixed(2)]),
      style: AppTheme.normalTextStyle(),
      textAlign: TextAlign.end,
    );
  }

  Row cashRounding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text('rounding'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child: Text(
            'RM'.tr(args: ['10.00']),
            style: AppTheme.normalTextStyle(),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Row cash() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text('cash'.tr(), style: AppTheme.normalTextStyle())),
        Expanded(
          child: Text(
            'RM'.tr(args: ['10.00']),
            style: AppTheme.normalTextStyle(),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Row netSales(bool hasPermission) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: hasPermission ? 1 : 2,
          child: Text(
            'netSales'.tr(),
            style: AppTheme.mediumTextStyle(color: canvasColor),
          ),
        ),
        Expanded(
          child:
              hasPermission
                  ? Text(
                    'RM'.tr(
                      args: [data['net_sales']?.toStringAsFixed(2) ?? '0.00'],
                    ),
                    style: AppTheme.mediumTextStyle(color: canvasColor),
                    textAlign: TextAlign.end,
                  )
                  : NoPermissionText(),
        ),
      ],
    );
  }

  Row discounts(bool hasPermission) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: hasPermission ? 1 : 2,
          child: Text('discounts'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child:
              hasPermission
                  ? Text(
                    'RM'.tr(
                      args: [data['discounts']?.toStringAsFixed(2) ?? '0.00'],
                    ),
                    style: AppTheme.normalTextStyle(),
                    textAlign: TextAlign.end,
                  )
                  : NoPermissionText(),
        ),
      ],
    );
  }

  Row refunds(bool hasPermission) {
    return Row(
      children: [
        Expanded(
          flex: hasPermission ? 1 : 2,
          child: Text('refunds'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child:
              hasPermission
                  ? Text(
                    'RM'.tr(
                      args: [data['refunds']?.toStringAsFixed(2) ?? '0.00'],
                    ),
                    style: AppTheme.normalTextStyle(),
                    textAlign: TextAlign.end,
                  )
                  : NoPermissionText(),
        ),
      ],
    );
  }

  Row grossSales(bool hasPermission) {
    return Row(
      children: [
        Expanded(
          flex: hasPermission ? 1 : 2,
          child: Text(
            'grossSales'.tr(),
            style: AppTheme.mediumTextStyle(color: canvasColor),
          ),
        ),
        Expanded(
          child:
              hasPermission
                  ? Text(
                    'RM'.tr(
                      args: [data['gross_sales']?.toStringAsFixed(2) ?? '0.00'],
                    ),
                    style: AppTheme.mediumTextStyle(color: canvasColor),
                    textAlign: TextAlign.end,
                  )
                  : NoPermissionText(),
        ),
      ],
    );
  }
}
