import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/features/setting_receipt/components/receipt_logo.dart';

class SettingReceiptScreen extends StatefulWidget {
  const SettingReceiptScreen({super.key});

  @override
  State<SettingReceiptScreen> createState() => _SettingReceiptScreenState();
}

class _SettingReceiptScreenState extends State<SettingReceiptScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(() {
      setState(() {
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
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
                        'receiptLogo'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: canvasColor,
                        ),
                      ),
                    ),
                    // Tab(
                    //   child: Text(
                    //     "footer".tr(),
                    //     style: const TextStyle(
                    //       fontSize: 15,
                    //       fontWeight: FontWeight.bold,
                    //       color: canvasColor,
                    //     ),
                    //   ),
                    // ),
                    // Tab(
                    //   child: Text(
                    //     "header".tr(),
                    //     style: const TextStyle(
                    //       fontSize: 15,
                    //       fontWeight: FontWeight.bold,
                    //       color: canvasColor,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
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
                  child: const ReceiptLogo(),
                ),
                // GestureDetector(
                //   onTap: () => FocusScope.of(context).unfocus(),
                //   child: const ReceiptFooter(),
                // ),
                // GestureDetector(
                //   onTap: () => FocusScope.of(context).unfocus(),
                //   child: const ReceiptHeader(),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
