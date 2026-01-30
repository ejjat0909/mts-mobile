import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/features/open_and_move_order/components/move_order_body.dart';
import 'package:mts/presentation/features/open_and_move_order/components/open_order_body.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/user/user_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';

class OpenAndMoveOrderDialogue extends ConsumerStatefulWidget {
  final Function(bool) isLoading;
  final Function(Map<String, dynamic>) dataMap;

  const OpenAndMoveOrderDialogue({
    super.key,
    required this.isLoading,
    required this.dataMap,
  });

  @override
  ConsumerState<OpenAndMoveOrderDialogue> createState() =>
      _OpenAndMoveOrderDialogueState();
}

class _OpenAndMoveOrderDialogueState
    extends ConsumerState<OpenAndMoveOrderDialogue> {
  late UserModel userModel;
  late StaffModel staffModel;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final staffState = ref.read(staffProvider);
      if (staffState.items.isNotEmpty) {
        staffModel = staffState.items.first;
        if (staffModel.userId != null) {
          final user = await ref
              .read(userProvider.notifier)
              .getUserModelByIdUser(staffModel.userId!);
          if (user != null) {
            userModel = user;
            setState(() {});
          }
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    final dialogueNavState = ref.watch(dialogNavigatorProvider);

    final navigator = dialogueNavState.pageIndex;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight,
          minHeight: availableHeight,
          maxWidth: availableWidth / 2,
        ),
        child: FutureBuilder(
          future: ref
              .read(saleProvider.notifier)
              .getSaleModelBasedOnCurrentUserAndChargedAt(context),
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: ThemeSpinner.spinner());
            }
            List<SaleModel> listSaleModel = snapshot.data!;
            return getBody(navigator, listSaleModel);
          },
        ),
      ),
    );
  }

  Widget getBody(int navigator, List<SaleModel> listSaleModel) {
    final selectedOrders = List.generate(
      listSaleModel.length,
      (index) => false,
    );
    switch (navigator) {
      case DialogNavigatorEnum.openOrder:
        return OpenOrderBody(
          isLoading: widget.isLoading,
          dataMap: widget.dataMap,
          userModel: userModel,
        );
      case DialogNavigatorEnum.moveOrder:
        return MoveOrderBody(
          listSaleModel: listSaleModel,
          isSelectedList: selectedOrders,
        );
      default:
        return OpenOrderBody(
          isLoading: widget.isLoading,
          dataMap: widget.dataMap,
          userModel: userModel,
        );
    }
  }
}
