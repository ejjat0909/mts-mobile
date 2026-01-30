import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/features/home_receipt/components/initial_receipt_order_item.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class InitialMenuList extends ConsumerStatefulWidget {
  const InitialMenuList({super.key});

  @override
  ConsumerState<InitialMenuList> createState() => _InitialMenuListState();
}

class _InitialMenuListState extends ConsumerState<InitialMenuList> {
  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptProvider);
    final listReceiptItemModel = receiptState.initialListReceiptItems;

    return Column(
      children: [
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: kLightGray,
                child: Text('items'.tr(), style: AppTheme.mediumTextStyle()),
              ),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listReceiptItemModel.length,
          itemBuilder: (BuildContext context, int index) {
            return InitialReceiptOrderItem(
              receiptItemModel: listReceiptItemModel[index],
            );
          },
        ),
      ],
    );
  }
}
