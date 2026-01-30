// ignore_for_file: unused_import

import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/features/tables/tables_edit/components/dialogue_edit_section_name.dart';
import 'package:mts/presentation/features/tables/tables_edit/components/edit_table.dart';
import 'package:mts/presentation/features/tables/tables_edit/components/side_bar_body.dart';
import 'package:mts/presentation/features/tables/tables_edit/components/table_side_bar.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';

// Custom AnimatedFlex widget to animate flex values
class AnimatedFlex extends StatelessWidget {
  final int flex;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedFlex({
    super.key,
    required this.flex,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(begin: 0, end: flex.toDouble()),
      builder: (context, animatedFlex, child) {
        return Expanded(flex: animatedFlex.round(), child: this.child);
      },
    );
  }
}

class TablesEditBody extends ConsumerStatefulWidget {
  const TablesEditBody({super.key});

  @override
  ConsumerState<TablesEditBody> createState() => _TablesEditBodyState();
}

class _TablesEditBodyState extends ConsumerState<TablesEditBody>
    with TickerProviderStateMixin {
  final GlobalKey _editTablesKey = GlobalKey();

  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _fabSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize FAB animation controller
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _fabSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First, initialize table edit mode and wait for data to load
      await ref.read(tableLayoutProvider.notifier).initTableEdit();

      // Then check if sections exist after loading
      final tableLayoutState = ref.read(tableLayoutProvider);
      if (tableLayoutState.editSections.isEmpty) {
        prints('No sections found after init');
        showDialoguePutSections();
      }

      // Start FAB animation if sidebar is closed
      if (!tableLayoutState.showSidebar) {
        _fabController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future _onChangeSectName(TableSectionModel currSect) {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height / 2,
              maxWidth: MediaQuery.of(context).size.width / 3,
            ),
            child: DialogueEditSectionName(
              onSave: (newName) {
                if (newName.isEmpty) {
                  return;
                }
                ref
                    .read(tableLayoutProvider.notifier)
                    .modifySection(currSect, newName);
              },
              onDelete: () {
                final currentState = ref.read(tableLayoutProvider);
                if (currentState.editSections.length == 1) {
                  ThemeSnackBar.showSnackBar(
                    context,
                    'Cannot delete last section',
                  );
                  NavigationUtils.pop(context);
                  return;
                }
                ref
                    .read(tableLayoutProvider.notifier)
                    .removeSection(currSect.id!);
                NavigationUtils.pop(context);
              },
              currentSectName: currSect.name.toString(),
            ),
          ),
        );
      },
    );
  }

  void _handleTableDrop(String tableType, int status, Offset globalPosition) {
    final tableLayoutState = ref.read(tableLayoutProvider);

    // Get the EditTables render box using the key
    final RenderBox? editTablesRenderBox =
        _editTablesKey.currentContext?.findRenderObject() as RenderBox?;

    if (editTablesRenderBox == null) {
      prints('EditTables render box not found');
      return;
    }

    // Convert global position to local position within EditTables
    final localPosition = editTablesRenderBox.globalToLocal(globalPosition);

    prints('Global position: $globalPosition');
    prints('Local position: $localPosition');

    // Check if drop is within EditTables bounds
    final size = editTablesRenderBox.size;
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy > size.height) {
      prints('Drop outside EditTables bounds');
      return;
    }

    // Create new table at the exact drop position
    final newTable = TableModel(
      id: IdUtils.generateUUID(),
      left: localPosition.dx,
      top: localPosition.dy,
      name: 'new'.tr(),
      type: tableType,
      status: status,
      tableSectionId: tableLayoutState.currSection?.id,
    );

    prints('Creating table at: ${localPosition.dx}, ${localPosition.dy}');

    // Add table through provider
    ref.read(tableLayoutProvider.notifier).addTable(newTable);
  }

  void _openSidebar() {
    _fabController.reverse().then((_) {
      ref.read(tableLayoutProvider.notifier).setShowSidebar(true);
    });
  }

  bool isShowDialogPutSections = false;
  void showDialoguePutSections() {
    CustomDialog.show(
      context,
      dialogType: DialogType.warning,
      icon: FontAwesomeIcons.layerGroup,
      title: 'noSectionsAdded'.tr(),
      description: 'addASectionFirst'.tr(),
      btnOkText: 'OK'.tr(),
      btnOkOnPress: () {
        NavigationUtils.pop(context);
        isShowDialogPutSections = true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutState = ref.watch(tableLayoutProvider);

    // Handle FAB animation based on sidebar state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!tableLayoutState.showSidebar && !_fabController.isCompleted) {
        _fabController.forward();
      } else if (tableLayoutState.showSidebar && _fabController.isCompleted) {
        _fabController.reverse();
      }
    });

    final screenWidth = 1194.w;
    final sidebarWidth = screenWidth / 10 * 1.5;
    final mainContentWidth = screenWidth - sidebarWidth;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: UIUtils.itemShadows,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          Row(
                            children: List.generate(
                              tableLayoutState.editSections.length,
                              (index) {
                                final isSelected =
                                    tableLayoutState.editSections[index].id ==
                                    tableLayoutState.currSection?.id;
                                return InkWell(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 22,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? kPrimaryLightColor
                                              : white,
                                      border: Border(
                                        bottom: BorderSide(
                                          width: 2,
                                          color:
                                              isSelected
                                                  ? kPrimaryColor
                                                  : Colors.white,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          tableLayoutState
                                              .editSections[index]
                                              .name!,
                                          style: TextStyle(
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            fontSize: 16.sp,
                                            color:
                                                isSelected
                                                    ? kPrimaryColor
                                                    : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    ref
                                        .read(tableLayoutProvider.notifier)
                                        .setCurrSection(
                                          tableLayoutState.editSections[index],
                                        );
                                  },
                                  onLongPress: () async {
                                    await _onChangeSectName(
                                      tableLayoutState.editSections[index],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          InkWell(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.w,
                                vertical: 22.h,
                              ),
                              child: Row(
                                children: [
                                  const Icon(FontAwesomeIcons.plus, size: 20),
                                  const SizedBox(width: 5),
                                  Text(
                                    'addSection'.tr(),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              TableSectionModel section = TableSectionModel(
                                id: IdUtils.generateUUID().toString(),
                                name:
                                    'Section ${tableLayoutState.editSections.length + 1}',
                              );
                              ref
                                  .read(tableLayoutProvider.notifier)
                                  .addSection(section);
                              ref
                                  .read(tableLayoutProvider.notifier)
                                  .setCurrSection(section);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Row(
                    children: [
                      Expanded(
                        flex:
                            tableLayoutState.showSidebar
                                ? 10
                                : 12, // Expand EditTables when sidebar is hidden
                        child: Container(
                          key: _editTablesKey, // Key for coordinate conversion
                          child: EditTables(
                            mainContentWidth: mainContentWidth,
                            section: tableLayoutState.currSection,
                          ),
                        ),
                      ),
                      // Conditionally show the sidebar with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: tableLayoutState.showSidebar ? null : 0,
                        child:
                            tableLayoutState.showSidebar
                                ? Expanded(
                                  flex: 2,
                                  child: TableSideBar(
                                    title: 'tables'.tr(),
                                    body: SideBarBody(
                                      onTableDrop:
                                          _handleTableDrop, // Pass the callback
                                    ),
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Floating Action Button when sidebar is closed
      floatingActionButton:
          !tableLayoutState.showSidebar
              ? SlideTransition(
                position: _fabSlideAnimation,
                child: ScaleTransition(
                  scale: _fabScaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).canvasColor,
                          Theme.of(context).canvasColor.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openSidebar,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            FontAwesomeIcons.tableCellsLarge,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.black.withValues(alpha: 0.8),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
