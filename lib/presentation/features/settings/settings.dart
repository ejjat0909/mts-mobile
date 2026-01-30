import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/side_bar/side_bar_model.dart';
import 'package:mts/presentation/features/setting_receipt/setting_receipt_screen.dart';
import 'package:mts/presentation/features/settings/customer_display/customer_display_screen.dart';
import 'package:mts/presentation/features/settings/nested_sidebar.dart';
import 'package:mts/presentation/features/settings/permission/permission_screen.dart';
import 'package:mts/presentation/features/settings/printer/add_printer/add_printer_screen.dart';
import 'package:mts/presentation/features/settings/printer/edit_printer/edit_printer_screen.dart';
import 'package:mts/presentation/features/settings/printer/list_printer/list_printer_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  List<SideBarModel> sidebarItems = [
    SideBarModel(
      title: 'receipt'.tr(),
      icon: Icons.receipt,
      haveNestedSideBar: false,
      index: 4100,
    ),
    SideBarModel(
      title: 'printers'.tr(),
      icon: Icons.print_rounded,
      haveNestedSideBar: false,
      index: 4200,
    ),
    SideBarModel(
      title: 'customerDisplay'.tr(),
      icon: Icons.screen_share_outlined,
      haveNestedSideBar: false,
      index: 4300,
    ),
    SideBarModel(
      title: 'permission'.tr(),
      icon: Icons.lock_rounded,
      haveNestedSideBar: false,
      index: 4400,
    ),
  ];

  @override
  void initState() {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<MyNavigator>().setSelectedTab(4100, 'receipt'.tr());
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        NestedSidebar(nestedSidebarModels: sidebarItems),
        Expanded(flex: 5, child: getBodySetting()),
      ],
    );
  }

  Widget getBodySetting() {
    int pageIndex = ref.watch(myNavigatorProvider).selectedTab;
    switch (pageIndex) {
      case 4100:
        return const SettingReceiptScreen();
      case 4200:
        return const ListPrinterScreen();
      case 4210:
        return const AddPrinterScreen();
      case 4220:
        return const EditPrinterScreen();
      case 4300:
        return const CustomerDisplayScreen();

      case 4400:
        return const PermissionScreen();

      default:
        // Default case, return a message or an empty container based on your needs
        return Center(child: Text('settings error $pageIndex'));
    }
  }
}
