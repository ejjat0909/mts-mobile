import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/presentation/features/cash_management/components/cash_management_input.dart';
import 'package:mts/presentation/features/cash_management/components/pay_in_out_side_bar.dart';
import 'package:mts/providers/cash_management/cash_management_providers.dart';

class Body extends ConsumerStatefulWidget {
  const Body({super.key});

  @override
  ConsumerState<Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<Body> {
  List<CashManagementModel> cashManagementList = [];

  @override
  void initState() {
    super.initState();
    getCashManagementList();
  }

  Future<void> getCashManagementList() async {
    final cashManagementNotifier = ref.read(cashManagementProvider.notifier);
    cashManagementList =
        await cashManagementNotifier.getListCashManagementModel();
    setState(() {});
  }

  void updateCashManagementList(List<CashManagementModel> listCMM) {
    setState(() {
      cashManagementList = listCMM;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        PayInOutSidebar(cashManagementList: cashManagementList),
        CashManagementInput(
          onRefreshListCMM: (listCMM) {
            updateCashManagementList(listCMM);
          },
        ),
      ],
    );
  }
}
