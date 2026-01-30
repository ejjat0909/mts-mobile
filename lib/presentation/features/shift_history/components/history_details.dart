import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/shift_history/components/history_cash_drawer.dart';
import 'package:mts/presentation/features/shift_history/components/history_sales_summary.dart';
import 'package:mts/presentation/features/shift_history/components/history_time.dart';
import 'package:mts/providers/shift/shift_providers.dart';

class HistoryDetails extends ConsumerStatefulWidget {
  const HistoryDetails({super.key});

  @override
  ConsumerState<HistoryDetails> createState() => _HistoryDetailsState();
}

class _HistoryDetailsState extends ConsumerState<HistoryDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    ShiftModel? shiftModel = ref.watch(shiftProvider).currShiftModel;

    if (shiftModel != null &&
        shiftModel.openedBy != null &&
        shiftModel.closedBy != null &&
        shiftModel.saleSummaryJson != null) {
      return mainBody(context, shiftModel);
    }

    return bodyShiftNull(context);
  }

  Widget bodyShiftNull(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.clockRotateLeft,
            size: 100,
            color: kTextGray.withValues(alpha: 0.5),
          ),
          Space(40.h),
          Text(
            'pleaseChooseShiftHistory'.tr(),
            style: AppTheme.mediumTextStyle(),
          ),
        ],
      ),
    );
  }

  Widget mainBody(BuildContext context, ShiftModel shiftModel) {
    return Expanded(
      flex: 5,
      child: Column(
        children: [
          SizedBox(height: 50.h),
          // openBy and Closeby
          HistoryTime(shiftModel: shiftModel),
          SizedBox(height: 10.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                // margin: EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 7.5),
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: TabBar(
                    padding: const EdgeInsets.symmetric(horizontal: 7.5),
                    onTap: (value) {
                      setState(() {});
                    },
                    tabAlignment: TabAlignment.center,
                    physics: const BouncingScrollPhysics(),
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: kPrimaryBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    splashFactory: InkSplash.splashFactory,
                    splashBorderRadius: BorderRadius.circular(10),
                    overlayColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      return states.contains(WidgetState.focused)
                          ? null
                          : kPrimaryColor;
                    }),
                    isScrollable: true,
                    enableFeedback: true,
                    tabs: [
                      Tab(
                        child: Text(
                          'cashDrawer'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: canvasColor,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'salesSummary'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: canvasColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 200, right: 200, bottom: 50),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(10.sp),
              ),
              width: double.infinity,
              child: TabBarView(
                controller: _tabController,
                children: [
                  GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: HistoryCashDrawer(shiftModel: shiftModel),
                  ),
                  GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: HistorySalesSummary(shiftModel: shiftModel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
