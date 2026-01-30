import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/side_bar/side_bar_model.dart';
import 'package:mts/providers/user/user_providers.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';

class NestedSidebar extends ConsumerStatefulWidget {
  final List<SideBarModel> nestedSidebarModels;

  const NestedSidebar({super.key, required this.nestedSidebarModels});

  @override
  ConsumerState<NestedSidebar> createState() => _NestedSidebarState();
}

class _NestedSidebarState extends ConsumerState<NestedSidebar> {
  String _packageInfo = '';
  int index = 0;

  Future<void> getVersionInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _packageInfo =
          '${packageInfo.appName} ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  void getSelectedNestedIndex() {
    final selectedTab = ref.read(myNavigatorProvider).selectedTab;
    index = switch (selectedTab) {
      4100 => 0,
      4200 => 1,
      4300 => 2,
      4400 => 3,
      _ => index,
    };
  }

  @override
  void initState() {
    super.initState();
    getVersionInfo();
    getSelectedNestedIndex();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: kPrimaryColor.withValues(alpha: 1),
              width: 0.05,
            ),
          ),
          boxShadow: [
            BoxShadow(
              offset: const Offset(1, 4),
              blurRadius: 10,
              spreadRadius: 0,
              color: Colors.black.withValues(alpha: 0.10),
            ),
          ],
        ),
        // this column is to make the container have max height
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children:
                        widget.nestedSidebarModels.asMap().entries.map((entry) {
                          int key = entry.key;
                          String text = entry.value.title;
                          IconData iconData = entry.value.icon;

                          return ScaleTap(
                            onPressed: () {
                              setState(() {
                                index = key;
                              });
                              ref
                                  .read(myNavigatorProvider.notifier)
                                  .setSelectedTab(entry.value.index, text);
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              decoration: BoxDecoration(
                                color: index == key ? kItemColor : white,
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 15,
                                      top: 15,
                                      bottom: 15,
                                    ),
                                    child: Icon(
                                      iconData,
                                      size: 25,
                                      color:
                                          index == key
                                              ? kPrimaryColor
                                              : canvasColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 15,
                                        top: 15,
                                        bottom: 15,
                                      ),
                                      child: Text(text),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2.5,
                                      vertical: 26,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color:
                                          index == key ? kPrimaryColor : white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            const Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: ButtonTertiary(
                onPressed: () async {
                  await ref
                      .read(userProvider.notifier)
                      .logoutConfirmation(context);
                },
                text: 'logout'.tr(),
              ),
            ),
            Text(
              _packageInfo,
              style: AppTheme.normalTextStyle(color: kDisabledText),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}
