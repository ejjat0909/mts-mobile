import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/presentation/features/shift_screen/components/cash_drawer.dart';
import 'package:mts/presentation/features/shift_screen/components/double_button.dart';
import 'package:mts/presentation/features/shift_screen/components/sales_summary.dart';

class ShiftDetails extends StatefulWidget {
  final BuildContext shiftBodyContext;
  const ShiftDetails({super.key, required this.shiftBodyContext});

  @override
  State<ShiftDetails> createState() => _ShiftDetailsState();
}

class _ShiftDetailsState extends State<ShiftDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabSubIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabSubIndex = _tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DoubleButton(shiftBodyContext: widget.shiftBodyContext),
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
                    setState(() {
                      _selectedTabSubIndex = value;
                      prints(_selectedTabSubIndex);
                    });
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
            margin: const EdgeInsets.only(left: 200, right: 200, bottom: 20),
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
                  child: const CashDrawer(),
                ),
                GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: const SalesSummary(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
