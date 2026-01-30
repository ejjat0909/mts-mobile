import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/presentation/common/layouts/error_page.dart';
import 'package:mts/presentation/features/shift_screen/components/close_shift.dart';
import 'package:mts/presentation/features/shift_screen/components/open_shift_input.dart';
import 'package:mts/presentation/features/shift_screen/components/shift_details.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';

class Body extends ConsumerStatefulWidget {
  const Body({super.key});

  @override
  ConsumerState<Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<Body> {
  // 3100 = open shift
  // 3200 = shift details
  // 3300 = close shift

  bool isShiftOpen = false;
  ShiftModel shiftModel = ShiftModel();

  Future<void> getShiftModel() async {
    shiftModel = await ref.read(shiftProvider.notifier).getLatestShift();
    //prints('expected amount ${shiftModel.expectedCash}');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getShiftModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isShiftOpen = ref.read(shiftProvider).isOpenShift;
      if (isShiftOpen) {
        ref
            .read(myNavigatorProvider.notifier)
            .setSelectedTab(3200, 'shiftDetails'.tr());
      } else {
        ref
            .read(myNavigatorProvider.notifier)
            .setSelectedTab(3100, 'openShift'.tr());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int pageIndex = ref.watch(myNavigatorProvider).selectedTab;
    switch (pageIndex) {
      case 3100:
        return Column(children: [OpenShift(homeContext: context)]);
      case 3200:
        return ShiftDetails(shiftBodyContext: context);
      case 3300:
        return const Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: CloseShift(),
              ),
            ),
          ],
        );

      default:
        prints('${pageIndex}sd');
        return ErrorPage(index: pageIndex.toString());
    }
  }
}
