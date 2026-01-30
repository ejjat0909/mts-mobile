import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/widgets/no_permission_text.dart';
import 'package:mts/providers/payment_type/payment_type_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';

class SalesSummary extends ConsumerStatefulWidget {
  const SalesSummary({super.key});

  @override
  ConsumerState<SalesSummary> createState() => _SalesSummaryState();
}

class _SalesSummaryState extends ConsumerState<SalesSummary> {
  String totalGrossSales = '0.00';
  String totalNetSales = '0.00';
  String totalReceiptItemsNotRefundedSoldByItem = '0';
  String totalReceiptItemsNotRefundedSoldByMeasurement = '0.000';
  String totalAdjustment = '0.00';
  String totalDiscount = '0.00';
  String totalTaxes = '0.00';
  String totalCashRounding = '0.00';

  @override
  void initState() {
    super.initState();
    calculateTotal();
  }

  Future<void> calculateTotal() async {
    totalGrossSales = await ref.read(receiptProvider.notifier).calcGrossSales();
    totalNetSales = await ref.read(receiptProvider.notifier).calcNetSales();
    totalAdjustment = await ref.read(receiptProvider.notifier).calcAdjustment();
    totalReceiptItemsNotRefundedSoldByItem =
        await ref
            .read(receiptItemProvider.notifier)
            .calcTotalQuantityNotRefundedSoldByItem();
    totalReceiptItemsNotRefundedSoldByMeasurement =
        await ref
            .read(receiptItemProvider.notifier)
            .calcTotalQuantityNotRefundedSoldByMeasurement();
    totalDiscount =
        await ref.read(receiptProvider.notifier).calcTotalDiscount();
    totalTaxes = await ref.read(receiptProvider.notifier).calcTotalTax();
    totalCashRounding =
        await ref.read(receiptProvider.notifier).calcTotalCashRounding();

    setState(() {});
  }

  Future<Map<String, dynamic>> getFutureData() async {
    // get list receipt item not refunded
    List<ReceiptItemModel> listReceiptItemModelNotRefunded =
        await ref
            .read(receiptItemProvider.notifier)
            .getListReceiptItemsNotRefunded();

    // get list receipt item is refunded
    List<ReceiptItemModel> listReceiptItemModelIsRefunded =
        await ref
            .read(receiptItemProvider.notifier)
            .getListReceiptItemsIsRefunded();

    // get list payment type
    List<PaymentTypeModel> listPaymentTypeModel =
        await ref.read(paymentTypeProvider.notifier).getListPaymentType();

    // get list receipt not synced
    // Using facade instead of bloc
    List<ReceiptModel> listReceiptModel =
        await ref.read(receiptProvider.notifier).getListReceiptModelByShiftId();
    return {
      'listReceiptItemModelIsRefunded': listReceiptItemModelIsRefunded,
      'listReceiptItemModelNotRefunded': listReceiptItemModelNotRefunded,
      'listPaymentTypeModel': listPaymentTypeModel,
      'listReceiptModel': listReceiptModel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasPermission =
        ref.watch(permissionProvider.notifier).hasViewShiftReportsPermission();
    return FutureBuilder(
      future: getFutureData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: ThemeSpinner.spinner());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        // extract data from snapshot
        List<ReceiptItemModel> listReceiptItemModelNotRefunded =
            snapshot.data!['listReceiptItemModelNotRefunded']
                as List<ReceiptItemModel>;

        List<PaymentTypeModel> listPaymentTypeModel =
            snapshot.data!['listPaymentTypeModel'] as List<PaymentTypeModel>;

        List<ReceiptModel> listReceiptModel =
            snapshot.data!['listReceiptModel'] as List<ReceiptModel>;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                grossSales(hasPermission),
                SizedBox(height: 20.h),
                refunds(hasPermission),
                SizedBox(height: 20.h),
                discounts(hasPermission),
                SizedBox(height: 20.h),
                totalTax(hasPermission),
                SizedBox(height: 20.h),
                adjustedPrice(hasPermission),
                SizedBox(height: 20.h),
                const Divider(thickness: 1),
                SizedBox(height: 20.h),
                netSales(hasPermission),
                SizedBox(height: 20.h),
                ...listPaymentType(
                  listPaymentTypeModel,
                  listReceiptModel,
                  hasPermission,
                ),
                cashRounding(),
                SizedBox(height: 20.h),
                const Divider(thickness: 1),
                SizedBox(height: 20.h),
                hasPermission
                    ? itemSold(
                      '${"itemSoldByItem".tr()} ($totalReceiptItemsNotRefundedSoldByItem)',
                    )
                    : NoPermissionText(width: 100.w),
                SizedBox(height: 10.h),
                if (hasPermission)
                  ...listItemSold(
                    listReceiptItemModelNotRefunded,
                    ItemSoldByEnum.item,
                  ),
                const Divider(thickness: 1),
                SizedBox(height: 20.h),
                hasPermission
                    ? itemSold(
                      '${"itemSoldByMeasurement".tr()} ($totalReceiptItemsNotRefundedSoldByMeasurement)',
                    )
                    : NoPermissionText(width: 100.w),
                SizedBox(height: 10.h),
                if (hasPermission)
                  ...listItemSold(
                    listReceiptItemModelNotRefunded,
                    ItemSoldByEnum.measurement,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Row card() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text('card'.tr(), style: AppTheme.normalTextStyle())),
        Expanded(
          child: Text(
            'RM'.tr(args: ['0.00']),
            style: AppTheme.normalTextStyle(),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Row adjustedPrice(bool hasPermission) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: hasPermission ? 1 : 3,
          child: Text('adjustment'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child:
              hasPermission
                  ? Text(
                    'RM'.tr(args: [totalAdjustment]),
                    style: AppTheme.normalTextStyle(),
                    textAlign: TextAlign.end,
                  )
                  : NoPermissionText(),
        ),
      ],
    );
  }

  Row totalTax(bool hasPermission) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: hasPermission ? 1 : 3,
          child: Text('tax'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child:
              hasPermission
                  ? Text(
                    'RM'.tr(args: [totalTaxes]),
                    style: AppTheme.normalTextStyle(),
                    textAlign: TextAlign.end,
                  )
                  : NoPermissionText(),
        ),
      ],
    );
  }

  Row cashRounding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'rounding'.tr(),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        Expanded(
          child: Text(
            'RM'.tr(args: [totalCashRounding]),
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
            'RM'.tr(args: ['0.00']),
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
          flex: hasPermission ? 1 : 3,
          child: Text(
            'netSales'.tr(),
            style: AppTheme.mediumTextStyle(color: canvasColor),
          ),
        ),
        Expanded(
          child:
              hasPermission
                  ? Text(
                    'RM'.tr(args: [totalNetSales]),
                    style: AppTheme.mediumTextStyle(color: canvasColor),
                    textAlign: TextAlign.end,
                  )
                  : NoPermissionText(),
        ),
      ],
    );
  }

  Row itemSold(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            style: AppTheme.mediumTextStyle(color: canvasColor),
          ),
        ),
      ],
    );
  }

  Row discounts(bool hasPermission) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: hasPermission ? 1 : 3,
          child: Text('discounts'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child:
              hasPermission
                  ? Text(
                    'RM'.tr(args: [totalDiscount]),
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
          flex: hasPermission ? 1 : 3,
          child: Text('refunds'.tr(), style: AppTheme.normalTextStyle()),
        ),
        Expanded(
          child:
              hasPermission
                  ? FutureBuilder<double>(
                    future:
                        ref
                            .read(receiptProvider.notifier)
                            .calcAllAmountRefunded(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        double totalRefund = snapshot.data!;
                        return Text(
                          'RM'.tr(args: [totalRefund.toStringAsFixed(2)]),
                          style: AppTheme.normalTextStyle(),
                          textAlign: TextAlign.end,
                        );
                      } else {
                        return Text(
                          'RM'.tr(args: ['0.00']),
                          style: AppTheme.normalTextStyle(),
                          textAlign: TextAlign.end,
                        );
                      }
                    },
                  )
                  : NoPermissionText(),
        ),
      ],
    );
  }

  Column grossSales(bool hasPermission) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: hasPermission ? 1 : 3,
              child: Text(
                'grossSales'.tr(),
                style: AppTheme.mediumTextStyle(color: canvasColor),
              ),
            ),
            Expanded(
              child:
                  hasPermission
                      ? Text(
                        'RM'.tr(args: [totalGrossSales]),
                        style: AppTheme.mediumTextStyle(color: canvasColor),
                        textAlign: TextAlign.end,
                      )
                      : NoPermissionText(),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'afterMinusAdjustment'.tr(),
                style: AppTheme.italicTextStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> listPaymentType(
    List<PaymentTypeModel> listPaymentTypes,
    List<ReceiptModel> listReceipts,
    bool hasPermission,
  ) {
    if (listPaymentTypes.isEmpty) {
      return [];
    }

    // hold total  netsales for each payment type
    // use double for  calculation
    Map<String, double> paymentTypeAmounts = {};

    for (PaymentTypeModel paymentType in listPaymentTypes) {
      paymentTypeAmounts[paymentType.name ?? ''] = 0.00;
    }

    // Sum the netsales amounts for each payment type from the receipts
    for (ReceiptModel receipt in listReceipts) {
      if (receipt.paymentType != null &&
          paymentTypeAmounts.containsKey(receipt.paymentType)) {
        paymentTypeAmounts[receipt.paymentType ?? ''] =
            (paymentTypeAmounts[receipt.paymentType] ?? 0.0) +
            (receipt.netSale ?? 0.0);
      }
    }

    List<Widget> listWidget = [];

    for (PaymentTypeModel paymentType in listPaymentTypes) {
      final paymentName = paymentType.name ?? '';
      final isCashPayment = paymentName.toLowerCase().contains('cash');
      // Determine if we should show the amount (always for cash, or if has permission)
      final shouldShowAmount = isCashPayment || hasPermission;
      double amount = paymentTypeAmounts[paymentName] ?? 0.00;

      listWidget.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: shouldShowAmount ? 1 : 3, child: Text(paymentName)),
            Expanded(
              child:
                  shouldShowAmount
                      ? Text(
                        'RM'.tr(args: [amount.toStringAsFixed(2)]),
                        textAlign: TextAlign.end,
                      )
                      : NoPermissionText(),
            ),
          ],
        ),
      );

      listWidget.add(const SizedBox(height: 20));
    }

    return listWidget;
  }

  List<Widget> listItemSold(
    List<ReceiptItemModel> listReceiptItem,
    String soldBy,
  ) {
    listReceiptItem =
        listReceiptItem.where((item) => item.soldBy == soldBy).toList();
    if (listReceiptItem.isEmpty) {
      return [];
    }

    List<Widget> listWidget = [];

    // Group items by name, variant, and modifier
    Map<String, ReceiptItemModel> groupedItems = {};

    for (ReceiptItemModel receiptItem in listReceiptItem) {
      // Parse modifiers and variant option
      List<ModifierModel> modifiers = [];
      VariantOptionModel variantOption = VariantOptionModel();

      if (receiptItem.modifiers != null && receiptItem.modifiers!.isNotEmpty) {
        List<dynamic> modifierJson = jsonDecode(receiptItem.modifiers!);
        modifiers = List.generate(
          modifierJson.length,
          (index) => ModifierModel.fromJsonReceiptItem(modifierJson[index]),
        );
      }

      if (receiptItem.variants != null) {
        dynamic variantOptionJson = jsonDecode(receiptItem.variants!);
        variantOption = VariantOptionModel.fromJson(variantOptionJson);
      }

      // Generate a unique key for grouping based on name, variant, and modifiers
      String key =
          '${receiptItem.name}_${variantOption.id}_${modifiers.map((mod) => mod.id).join("_")}';

      // Check if the key already exists in groupedItems
      if (groupedItems.containsKey(key)) {
        // If it exists, increment the quantity
        groupedItems[key]!.quantity =
            (groupedItems[key]!.quantity ?? 0) + (receiptItem.quantity ?? 0);
      } else {
        // Otherwise, store a new receipt item with modifiers and variant
        groupedItems[key] = receiptItem;
      }
    }

    // Sort grouped items by name in ascending order
    List<ReceiptItemModel> sortedItems =
        groupedItems.values.toList()
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

    // Build the widget list based on sorted and grouped items
    for (ReceiptItemModel receiptItem in sortedItems) {
      List<ModifierModel> modifiers = [];
      VariantOptionModel variantOption = VariantOptionModel();

      // Parse modifiers and variant option again for UI display
      if (receiptItem.modifiers != null && receiptItem.modifiers!.isNotEmpty) {
        List<dynamic> modifierJson = jsonDecode(receiptItem.modifiers!);
        modifiers = List.generate(
          modifierJson.length,
          (index) => ModifierModel.fromJsonReceiptItem(modifierJson[index]),
        );
      }

      if (receiptItem.variants != null) {
        dynamic variantOptionJson = jsonDecode(receiptItem.variants!);
        variantOption = VariantOptionModel.fromJson(variantOptionJson);
      }

      // Main item row with consolidated quantity

      String totalDiscount = 'RM'.tr(
        args: [receiptItem.totalDiscount?.toStringAsFixed(2) ?? '0.00'],
      );
      bool hasDiscount =
          receiptItem.totalDiscount != null && receiptItem.totalDiscount! > 0;
      listWidget.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Expanded(
              child: Text(
                '${receiptItem.name ?? ""} x${receiptItem.soldBy == ItemSoldByEnum.item ? receiptItem.quantity?.toStringAsFixed(0) : receiptItem.quantity?.toStringAsFixed(3)}',
              ),
            ),
            Text(
              'RM'.tr(args: [receiptItem.price?.toStringAsFixed(2) ?? '0.00']),
              style: textStyleItalic(color: kBlackColor),
            ),
          ],
        ),
      );

      // Variant option row if it exists
      if (variantOption.id != null) {
        listWidget.add(
          Row(
            children: [
              Expanded(
                child: Text(variantOption.name ?? '', style: textStyleItalic()),
              ),
              if (hasDiscount)
                Text("Disc: -$totalDiscount", style: textStyleItalic()),
            ],
          ),
        );
      }

      // Group modifiers by ID to list the options together
      Map<String, List<ModifierOptionModel>> groupedModifiers = {};

      // The options are already loaded by the fromJsonReceiptItem method
      for (ModifierModel modifier in modifiers) {
        if (modifier.id != null) {
          groupedModifiers.putIfAbsent(modifier.id!, () => []);
          groupedModifiers[modifier.id!]!.addAll(
            modifier.modifierOptions ?? [],
          );
        }
      }

      // Display each modifier and its options
      for (String modifierId in groupedModifiers.keys) {
        ModifierModel? modifier = modifiers.firstWhere(
          (mod) => mod.id == modifierId,
        );
        String modifierOptionsText = groupedModifiers[modifierId]!
            .map((option) => option.name)
            .join(', ');

        listWidget.add(
          Row(
            children: [
              Expanded(
                child: Text(
                  '${modifier.name ?? ""} : $modifierOptionsText',
                  style: AppTheme.italicTextStyle(),
                ),
              ),
            ],
          ),
        );
      }

      listWidget.add(SizedBox(height: 5.h));
    }

    return listWidget;
  }
}
