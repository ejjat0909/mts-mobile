import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/enum/table_type_enum.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/form_bloc/tables_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/tables/components/circular_table.dart';
import 'package:mts/presentation/features/tables/components/edit_table_detail_dialog.dart';
import 'package:mts/presentation/features/tables/components/line_horizontal.dart';
import 'package:mts/presentation/features/tables/components/line_vertical.dart';
import 'package:mts/presentation/features/tables/components/rectangle_horizontal.dart';
import 'package:mts/presentation/features/tables/components/rectangle_vertical.dart';
import 'package:mts/presentation/features/tables/components/square_table.dart';
import 'package:mts/presentation/features/tables/tables_edit/components/edit_detail.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';

// Global callback for handling drops
typedef DropCallback =
    void Function(String tableType, int status, Offset globalPosition);

class SideBarBody extends ConsumerStatefulWidget {
  final DropCallback? onTableDrop;

  const SideBarBody({super.key, this.onTableDrop});

  @override
  ConsumerState<SideBarBody> createState() => _SideBarBodyState();
}

class _SideBarBodyState extends ConsumerState<SideBarBody>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right (hidden)
      end: Offset.zero, // End at normal position
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    // Start animation when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tableLayoutState = ref.read(tableLayoutProvider);
      if (tableLayoutState.showSidebar) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleDrop(String tableType, int status, Offset globalPosition) {
    final tableLayoutState = ref.read(tableLayoutProvider);

    // Call the callback if provided (for dropping on EditTables)
    if (widget.onTableDrop != null) {
      widget.onTableDrop!(tableType, status, globalPosition);
      return;
    }

    // Fallback: Create table at global position
    TableModel model = TableModel(
      id: IdUtils.generateUUID(),
      left: globalPosition.dx,
      top: globalPosition.dy - 100,
      name: 'new'.tr(),
      type: tableType,
      status: status,
      tableSectionId: tableLayoutState.currSection?.id,
    );

    if (tableLayoutState.editSections.isEmpty) {
      _warningDialog();
    } else {
      if (tableType == TableTypeEnum.LINEVERTICAL ||
          tableType == TableTypeEnum.LINEHORIZONTAL) {
        ref.read(tableLayoutProvider.notifier).addTable(model);
        prints('MASUK 1');
      } else {
        prints('MASUK 2');
        _openDialog(model, context, (tableModel) {
          ref.read(tableLayoutProvider.notifier).addTable(tableModel);
          NavigationUtils.pop(context);
        });
      }
    }
  }

  void _closeSidebar() {
    _slideController.reverse().then((_) {
      ref.read(tableLayoutProvider.notifier).setShowSidebar(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutState = ref.watch(tableLayoutProvider);

    // Check if sidebar should be shown
    if (!tableLayoutState.showSidebar) {
      return const SizedBox.shrink(); // Return empty widget when sidebar is hidden
    }

    // Trigger slide animation when sidebar becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tableLayoutState.showSidebar && !_slideController.isCompleted) {
        _slideController.forward();
      }
    });

    final tableEmpty = TableModel(name: '', status: TableStatusEnum.UNOCCUPIED);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.1),
          //     blurRadius: 8,
          //     offset: const Offset(-2, 0),
          //   ),
          // ],
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                // border: Border(
                //   bottom: BorderSide(color: Colors.grey[200]!, width: 10),
                // ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'elements'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeSidebar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        FontAwesomeIcons.chevronRight,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Space(10.h),
                    Draggable<String>(
                      data: 'circle',
                      feedback: Material(
                        color: Colors.transparent,
                        child: CircularTable(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.UNOCCUPIED,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: CircularTable(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.UNOCCUPIED,
                        ),
                      ),
                      onDragEnd: (details) {
                        _handleDrop(
                          TableTypeEnum.CIRCLE,
                          TableStatusEnum.UNOCCUPIED,
                          details.offset,
                        );
                      },
                      child: CircularTable(
                        tableModel: tableEmpty,
                        status: TableStatusEnum.UNOCCUPIED,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Draggable<String>(
                      data: 'square',
                      feedback: Material(
                        color: Colors.transparent,
                        child: SquareTable(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.UNOCCUPIED,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: SquareTable(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.UNOCCUPIED,
                        ),
                      ),
                      onDragEnd: (details) {
                        _handleDrop(
                          TableTypeEnum.SQUARE,
                          TableStatusEnum.UNOCCUPIED,
                          details.offset,
                        );
                      },
                      child: SquareTable(
                        tableModel: tableEmpty,
                        status: TableStatusEnum.UNOCCUPIED,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Draggable<String>(
                      data: 'rectangle_vertical',
                      feedback: Material(
                        color: Colors.transparent,
                        child: RectangleVertical(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.UNOCCUPIED,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: RectangleVertical(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.UNOCCUPIED,
                        ),
                      ),
                      onDragEnd: (details) {
                        _handleDrop(
                          TableTypeEnum.RECTANGLEVERTICAL,
                          TableStatusEnum.UNOCCUPIED,
                          details.offset,
                        );
                      },
                      child: RectangleVertical(
                        tableModel: tableEmpty,
                        status: TableStatusEnum.UNOCCUPIED,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Draggable<String>(
                      data: 'rectangle_horizontal',
                      feedback: Material(
                        color: Colors.transparent,
                        child: RectangleHorizontal(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.UNOCCUPIED,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: RectangleHorizontal(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.UNOCCUPIED,
                        ),
                      ),
                      onDragEnd: (details) {
                        _handleDrop(
                          TableTypeEnum.RECTANGLEHORIZONTAL,
                          TableStatusEnum.UNOCCUPIED,
                          details.offset,
                        );
                      },
                      child: RectangleHorizontal(
                        tableModel: tableEmpty,
                        status: TableStatusEnum.UNOCCUPIED,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Draggable<String>(
                      data: 'line_vertical',
                      feedback: Material(
                        color: Colors.transparent,
                        child: LineVertical(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.DISABLED,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: LineVertical(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.DISABLED,
                        ),
                      ),
                      onDragEnd: (details) {
                        _handleDrop(
                          TableTypeEnum.LINEVERTICAL,
                          TableStatusEnum.DISABLED,
                          details.offset,
                        );
                      },
                      child: LineVertical(
                        tableModel: tableEmpty,
                        status: TableStatusEnum.DISABLED,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Draggable<String>(
                      data: 'line_horizontal',
                      feedback: Material(
                        color: Colors.transparent,
                        child: LineHorizontal(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.DISABLED,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: LineHorizontal(
                          tableModel: tableEmpty,
                          status: TableStatusEnum.DISABLED,
                        ),
                      ),
                      onDragEnd: (details) {
                        _handleDrop(
                          TableTypeEnum.LINEHORIZONTAL,
                          TableStatusEnum.DISABLED,
                          details.offset,
                        );
                      },
                      child: LineHorizontal(
                        tableModel: tableEmpty,
                        status: TableStatusEnum.DISABLED,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDialog(
    TableModel tableModel,
    BuildContext context,
    Function(TableModel) onSuccess,
  ) {
    TextEditingController controller = TextEditingController();
    controller.text = tableModel.name!;

    TextEditingController seatsController = TextEditingController();
    PredefinedOrderModel? selectedOpenOrder;
    int status = TableStatusEnum.UNOCCUPIED;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (builder) => BlocProvider(
            create: (context) => TablesFormBloc(),
            child: Builder(
              builder: (context) {
                final editTableDetailBloc = context.read<TablesFormBloc>();

                return FormBlocListener<TablesFormBloc, String, String>(
                  onFailure: (context, state) {
                    ref
                        .read(tableLayoutProvider.notifier)
                        .setErrorMessage('Please select open order');
                  },
                  onSuccess: (context, state) async {
                    tableModel.status = status;

                    if (controller.text.isNotEmpty) {
                      tableModel.name = controller.text;
                    }
                    if (seatsController.text.isNotEmpty) {
                      tableModel.seats = int.parse(seatsController.text);
                    }

                    if (selectedOpenOrder != null) {
                      tableModel.predefinedOrderId = state.valueOf(
                        'predefinedOrder',
                      );
                    }

                    ref.read(tableLayoutProvider.notifier).setErrorMessage('');

                    PredefinedOrderModel? poModel =
                        tableModel.predefinedOrderId != null
                            ? await ref
                                .read(predefinedOrderProvider.notifier)
                                .getPredefinedOrderById(
                                  tableModel.predefinedOrderId,
                                )
                            : null;
                    if (mounted) {
                      ref
                          .read(tableLayoutProvider.notifier)
                          .addToPOBank(poModel!);
                    }

                    onSuccess(tableModel);
                  },
                  child: EditTableDetailDialog(
                    tableModel: tableModel,
                    headerTitleController: controller,
                    content: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: EditDetail(
                        tablesFormBloc: editTableDetailBloc,
                        seatsController: seatsController,
                        onChangeSwitch: (value) {
                          status =
                              value
                                  ? TableStatusEnum.UNOCCUPIED
                                  : TableStatusEnum.DISABLED;
                        },
                        onChangeOpenOrder: (p0) {
                          selectedOpenOrder = p0;
                        },
                        selectedPredefinedOrderId: tableModel.predefinedOrderId,
                        tableStatus: tableModel.status,
                        isAvailable:
                            tableModel.status == TableStatusEnum.UNOCCUPIED ||
                            tableModel.status == TableStatusEnum.OCCUPIED,
                        tableModel: tableModel,
                      ),
                    ),
                    headerRightAction: null,
                    footerTitle: 'save'.tr(),
                    saveAction: () {
                      editTableDetailBloc.submit();
                    },
                    cancelAction: () {
                      ref
                          .read(tableLayoutProvider.notifier)
                          .setErrorMessage('');
                      NavigationUtils.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
    );
  }

  void _warningDialog() {
    CustomDialog.show(
      context,
      icon: FontAwesomeIcons.triangleExclamation,
      dialogType: DialogType.warning,
      title: 'Warning'.tr(),
      description: 'Please create a section first',
      btnOkText: 'ok'.tr(),
      btnOkOnPress: () => NavigationUtils.pop(context),
    );
  }
}
