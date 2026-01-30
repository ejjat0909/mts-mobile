import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/custom_floating_button.dart';
import 'package:mts/presentation/features/settings/printer/list_printer/components/list_printer_body.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';

class ListPrinterScreen extends ConsumerStatefulWidget {
  const ListPrinterScreen({super.key});

  @override
  ConsumerState<ListPrinterScreen> createState() => _ListPrinterScreenState();
}

class _ListPrinterScreenState extends ConsumerState<ListPrinterScreen> {
  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    bool hasPermissionSettings =
        permissionNotifier.hasChangeSettingsPermission();
    return Scaffold(
      body: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10.sp),
        ),
        child: const ListPrinterBody(),
      ),
      floatingActionButton: CustomFloatingButton(
        onPressed: () async {
          await onPressFloating(context, hasPermissionSettings);
        },
      ),
    );
  }

  Future<void> onPressFloating(
    BuildContext context,
    bool hasPermissionSettings,
  ) async {
    if (!hasPermissionSettings) {
      await DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.CHANGE_SETTINGS,
        onSuccess: () async {
          ref
              .read(myNavigatorProvider.notifier)
              .setSelectedTab(4210, 'addPrinter'.tr());
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
    }

    if (hasPermissionSettings) {
      ref
          .read(myNavigatorProvider.notifier)
          .setSelectedTab(4210, 'addPrinter'.tr());
    }
  }
}
