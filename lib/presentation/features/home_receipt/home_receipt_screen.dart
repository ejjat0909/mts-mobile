import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/presentation/features/home_receipt/components/empty_receipt.dart';
import 'package:mts/presentation/features/home_receipt/components/home_receipt_body_details.dart';
import 'package:mts/presentation/features/home_receipt/components/home_receipt_sidebar.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class HomeReceiptScreen extends ConsumerStatefulWidget {
  const HomeReceiptScreen({super.key});

  @override
  ConsumerState<HomeReceiptScreen> createState() => _HomeReceiptScreenState();
}

class _HomeReceiptScreenState extends ConsumerState<HomeReceiptScreen> {
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int? selectedReceiptIndex =
          ref.read(receiptProvider).selectedReceiptIndex;

      _selectedIndex = selectedReceiptIndex ?? -1;
      setState(() {});

      // ReceiptModel? receiptModel =
      //     ref.read(receiptProvider).tempReceiptModel;

      // prints("receiptModel: $receiptModel");
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectIndex = ref.watch(receiptProvider).selectedReceiptIndex;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeReceiptSidebar(
          selectedIndexCallback: (value) {
            setState(() {
              _selectedIndex = value;
            });
          },
        ),
        getBody(selectIndex),
      ],
    );
  }

  Widget getBody(int? index) {
    if (index == null) {
      _selectedIndex = -1;
    }
    if (_selectedIndex == -1) {
      return const EmptyReceipt();
    } else {
      return const HomeReceiptBodyDetails();
    }
  }
}
