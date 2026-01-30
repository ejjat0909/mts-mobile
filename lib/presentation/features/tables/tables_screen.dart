import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/table_navigator_enum.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog2.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/widgets/no_permission.dart';
import 'package:mts/presentation/features/tables/components/custom_app_bar_tables.dart';
import 'package:mts/presentation/features/tables/tables_edit/components/tables_edit_body.dart';
import 'package:mts/presentation/features/tables/tables_view/tables_view_body.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  // Flag to track if the dialog has been shown
  bool _dialogShown = false;

  @override
  void dispose() {
    // Reset the dialog flag when the widget is disposed
    _dialogShown = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutState = ref.watch(tableLayoutProvider);
    final isTableLayoutActive = ref.watch(isTableLayoutActiveProvider);
    int tableNavigator = tableLayoutState.pageNavigator;

    // If table layout is not active, show CustomDialog2
    if (!isTableLayoutActive) {
      // Show the dialog when the widget is built, but only once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (tableNavigator == TableNavigatorEnum.tableEdit) {
          ref.read(tableLayoutProvider.notifier).resetEditChanges();
          ref
              .read(tableLayoutProvider.notifier)
              .setPageNavigator(TableNavigatorEnum.tableView);
        }

        // Only show the dialog if it hasn't been shown yet
        if (!_dialogShown) {
          _dialogShown = true;
          CustomDialog2.show(
            context,
            isDissmissable: false,
            icon: Icons.info_outline,
            title: 'Table Layout Inactive',
            description: 'The table layout feature is currently inactive.',
            dialogType: DialogType.info,
            btnOkText: 'Go Back',
            btnOkOnPress: () {
              // Close dialogue
              NavigationUtils.pop(context);
              // go back to sales screen // or close dialogue that popup
              NavigationUtils.pop(context);
            },
          );
        }
      });

      // Return an empty container as the base widget
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: NoPermission(
            btnText: 'Go Back',
            onPressed: () {
              // go to sales screen
              NavigationUtils.pop(context);
            },
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBarTables(
        onPressBack: () {
          onPressBack(tableNavigator);
        },
        title: getTitle(tableNavigator),
        action: ScaleTap(
          onPressed: () async {
            if (tableNavigator == TableNavigatorEnum.tableView) {
              ref
                  .read(tableLayoutProvider.notifier)
                  .setPageNavigator(TableNavigatorEnum.tableEdit);
            } else {
              LoadingDialog.show(context);
              //apply changes from Edit Table
              await ref.read(tableLayoutProvider.notifier).applyChanges();
              LoadingDialog.hide(context);

              ref
                  .read(tableLayoutProvider.notifier)
                  .setPageNavigator(TableNavigatorEnum.tableView);
            }
          },
          child: getAction(tableNavigator),
        ),
      ),
      body: getTablesBody(tableNavigator),
    );
  }

  String getTitle(int pageTableNavigator) {
    if (pageTableNavigator == TableNavigatorEnum.tableView) {
      return 'tables'.tr();
    } else if (pageTableNavigator == TableNavigatorEnum.tableEdit) {
      return 'editTable'.tr();
    } else {
      return 'tables'.tr();
    }
  }

  Widget getAction(int pageTableNavigator) {
    if (pageTableNavigator == TableNavigatorEnum.tableView) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: kWhiteColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(FontAwesomeIcons.penToSquare, color: canvasColor),
      );
    } else if (pageTableNavigator == TableNavigatorEnum.tableEdit) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: kWhiteColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(FontAwesomeIcons.floppyDisk, color: canvasColor),
      );
    } else {
      return Container();
    }
  }

  Widget getTablesBody(int pageTable) {
    switch (pageTable) {
      case TableNavigatorEnum.tableView:
        return const TablesViewBody();

      case TableNavigatorEnum.tableEdit:
        return const TablesEditBody();

      default:
        return const Center(child: Text('No Page Navigator Found'));
    }
  }

  void onPressBack(int pageTable) {
    prints(pageTable);
    if (pageTable == TableNavigatorEnum.tableView) {
      NavigationUtils.pop(context);
    } else if (pageTable == TableNavigatorEnum.tableEdit) {
      ref.read(tableLayoutProvider.notifier).resetEditChanges();
      ref
          .read(tableLayoutProvider.notifier)
          .setPageNavigator(TableNavigatorEnum.tableView);
    }
  }
}
