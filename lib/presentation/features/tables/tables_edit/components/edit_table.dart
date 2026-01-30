import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/core/enum/table_type_enum.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/form_bloc/tables_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/layouts/colored_safe_area.dart';
import 'package:mts/presentation/common/widgets/button_circle_delete.dart';
import 'package:mts/presentation/features/tables/components/circular_table.dart';
import 'package:mts/presentation/features/tables/components/edit_table_detail_dialog.dart';
import 'package:mts/presentation/features/tables/components/line_horizontal.dart';
import 'package:mts/presentation/features/tables/components/line_vertical.dart';
import 'package:mts/presentation/features/tables/components/rectangle_horizontal.dart';
import 'package:mts/presentation/features/tables/components/rectangle_vertical.dart';
import 'package:mts/presentation/features/tables/components/square_table.dart';
import 'package:mts/presentation/features/tables/tables_edit/components/edit_detail.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';

class EditTables extends ConsumerStatefulWidget {
  final double? left;
  final double? top;
  final String? type;
  final TableSectionModel? section;
  final double mainContentWidth;

  const EditTables({
    super.key,
    this.left,
    this.top,
    this.type,
    this.section,
    required this.mainContentWidth,
  });

  @override
  ConsumerState<EditTables> createState() => _EditTableState();
}

class _EditTableState extends ConsumerState<EditTables> {

  final _barcodeScannerNotifier = ServiceLocator.get<BarcodeScannerNotifier>();

  @override
  void initState() {
    super.initState();
    //  _barcodeScannerNotifier.initialize();
    _barcodeScannerNotifier.initializeForEditTables();
  }

  @override
  void dispose() {
    // Reinitialize to sales screen when screen closes
    _barcodeScannerNotifier.reinitializeToSalesScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scannerNotifier = context.watch<BarcodeScannerNotifier>();
    final tableLayoutState = ref.watch(tableLayoutProvider);

    // Get tables for current section in edit mode
    List<TableModel> listTablesSectionModel =
        widget.section?.id != null
            ? tableLayoutState.tableEditList.where((table) {
              return table.tableSectionId == widget.section!.id;
            }).toList()
            : [];

    return ColoredSafeArea(
      width: widget.mainContentWidth,
      color: kBg,
      child: SizedBox(
        width: widget.mainContentWidth,
        height: MediaQuery.of(context).size.height,
        child:
            listTablesSectionModel.isEmpty
                ? const Center(child: Text('Add new table'))
                : Stack(
                  children: List.generate(
                    listTablesSectionModel.length,
                    (index) => _generateTable(
                      listTablesSectionModel[index],
                      () => ref
                          .read(tableLayoutProvider.notifier)
                          .removeTable(listTablesSectionModel[index]),
                      (left, top) => ref
                          .read(tableLayoutProvider.notifier)
                          .modifyTable(
                            listTablesSectionModel[index],
                            left,
                            top,
                          ),
                      context,
                      scannerNotifier,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _generateTable(
    TableModel tableModel,
    Function() onDelete,
    Function(double left, double top) onUpdate,
    BuildContext context,
    BarcodeScannerNotifier scannerNotifier,
  ) {
    return BlocProvider(
      create: (context) => TablesFormBloc(),
      child: Builder(
        builder: (context) {
          final editTableDetailBloc = context.read<TablesFormBloc>();

          return FormBlocListener<TablesFormBloc, String, String>(
            onSuccess: (context, states) async {
              prints('Form submitted successfully: $states');
              NavigationUtils.pop(context);
            },
            onFailure: (context, state) {
              prints('Form submission failed');
              ref
                  .read(tableLayoutProvider.notifier)
                  .setErrorMessage(state.failureResponse.toString());
            },
            child: Positioned(
              left: tableModel.left,
              top: tableModel.top,
              child: GestureDetector(
                onPanUpdate: (details) {
                  onUpdate(
                    max(0, tableModel.left! + details.delta.dx),
                    max(0, tableModel.top! + details.delta.dy),
                  );
                },
                onTap: () {
                  _showEditDialog(
                    context,
                    tableModel,
                    onDelete,
                    editTableDetailBloc,
                    scannerNotifier,
                  );
                },
                child: getTableShape(tableModel),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    TableModel tableModel,
    Function() onDelete,
    TablesFormBloc editTableDetailBloc,
    BarcodeScannerNotifier scannerNotifier,
  ) {
    // Create controllers that will persist throughout the dialog lifecycle
    late TextEditingController nameController;
    late TextEditingController seatsController;

    // Initialize controllers with current values
    nameController = TextEditingController(text: tableModel.name ?? '');
    seatsController = TextEditingController(
      text: tableModel.seats?.toString() ?? '',
    );

    // Variables to track changes
    int? selectedStatus = tableModel.status;
    PredefinedOrderModel? selectedOpenOrder;

    // Store the current values for comparison
    String originalName = tableModel.name ?? '';
    int? originalSeats = tableModel.seats;
    int? originalStatus = tableModel.status;

    showDialog(
      context: context,
      builder:
          (dialogContext) => EditTableDetailDialog(
            tableModel: tableModel,
            headerTitleController: nameController,
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: EditDetail(
                tablesFormBloc: editTableDetailBloc,
                seatsController: seatsController,
                onChangeSwitch: (value) {
                  selectedStatus =
                      value
                          ? TableStatusEnum.UNOCCUPIED
                          : TableStatusEnum.DISABLED;
                  prints('Status changed to: $selectedStatus');
                },
                onChangeOpenOrder: (predefinedOrder) {
                  selectedOpenOrder = predefinedOrder;
                  prints('Selected open order: ${predefinedOrder.id}');
                },
                selectedPredefinedOrderId: tableModel.predefinedOrderId,
                tableStatus: tableModel.status,
                isAvailable:
                    tableModel.status == TableStatusEnum.UNOCCUPIED ||
                    tableModel.status == TableStatusEnum.OCCUPIED,
                tableModel: tableModel,
              ),
            ),
            headerRightAction: ButtonCircleDelete(
              onPressed: () {
                onDelete();
                NavigationUtils.pop(dialogContext);
              },
            ),
            footerTitle: 'save'.tr(),
            saveAction: () async {
              ref.read(tableLayoutProvider.notifier).setErrorMessage('');

              // Get the latest values from controllers
              String newName = nameController.text.trim();
              String newSeatsText = seatsController.text.trim();

              prints('=== SAVE ACTION VALUES ===');
              prints('Original name: "$originalName" -> New name: "$newName"');
              prints(
                'Original seats: $originalSeats -> New seats text: "$newSeatsText"',
              );
              prints(
                'Original status: $originalStatus -> New status: $selectedStatus',
              );

              bool hasChanges = false;

              // Update table name if changed
              if (newName.isNotEmpty && newName != originalName) {
                tableModel.name = newName;
                hasChanges = true;
                prints('✅ Name updated to: "$newName"');
              }

              // Update table seats if changed
              if (newSeatsText.isNotEmpty) {
                try {
                  int newSeats = int.parse(newSeatsText);
                  if (newSeats != originalSeats) {
                    tableModel.seats = newSeats;
                    hasChanges = true;
                    prints('✅ Seats updated to: $newSeats');
                  }
                } catch (e) {
                  prints('❌ Invalid seats number: "$newSeatsText"');
                }
              } else if (originalSeats != null) {
                // Clear seats if field is empty
                tableModel.seats = null;
                hasChanges = true;
                prints('✅ Seats cleared');
              }

              // Update status if changed
              if (selectedStatus != null && selectedStatus != originalStatus) {
                tableModel.status = selectedStatus;
                hasChanges = true;
                prints('✅ Status updated to: $selectedStatus');
              }

              // Handle predefined order changes
              if (selectedOpenOrder != null) {
                await _handlePredefinedOrderChange(
                  tableModel,
                  selectedOpenOrder!,
                  context,
                );
                hasChanges = true;
              }

              if (hasChanges) {
                // Force UI update
                setState(() {});
                prints('✅ Table updated successfully');
                prints('Final table state: ${tableModel.toJson()}');
              } else {
                prints('ℹ️ No changes detected');
              }

              // Submit the form
              editTableDetailBloc.submit();
            },
            cancelAction: () {
              ref.read(tableLayoutProvider.notifier).setErrorMessage('');
              prints('Dialog cancelled');
              NavigationUtils.pop(dialogContext);
            },
          ),
    ).then((_) {
      // Dispose controllers when dialog closes
      // nameController.dispose();
      // seatsController.dispose();
    });
  }

  Future<void> _handlePredefinedOrderChange(
    TableModel tableModel,
    PredefinedOrderModel selectedOpenOrder,
    BuildContext context,
  ) async {
    try {
      PredefinedOrderModel? currPoModel =
          tableModel.predefinedOrderId != null
              ? await ref.read(predefinedOrderProvider.notifier).getPredefinedOrderById(
                tableModel.predefinedOrderId,
              )
              : null;

      if (selectedOpenOrder.id == '-1') {
        // Remove predefined order
        ref.read(tableLayoutProvider.notifier).removeFromPOBank(currPoModel!);
        tableModel.predefinedOrderId = null;
        prints('✅ Predefined order removed');
      } else {
        // Set new predefined order
        PredefinedOrderModel? poModel = await ref.read(predefinedOrderProvider.notifier).getPredefinedOrderById(selectedOpenOrder.id);

        ref.read(tableLayoutProvider.notifier).addToPOBank(poModel!);
        if (currPoModel?.id != null) {
          ref.read(tableLayoutProvider.notifier).removeFromPOBank(currPoModel!);
        }
        tableModel.predefinedOrderId = selectedOpenOrder.id;
        prints('✅ Predefined order updated to: ${selectedOpenOrder.id}');
      }
    } catch (e) {
      prints('❌ Error handling predefined order: $e');
    }
  }

  Widget getTableShape(TableModel tableModel) {
    switch (tableModel.type) {
      case TableTypeEnum.SQUARE:
        return SquareTable(
          tableModel: tableModel,
          status: tableModel.status ?? TableStatusEnum.UNOCCUPIED,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.CIRCLE:
        return CircularTable(
          tableModel: tableModel,
          status: tableModel.status ?? TableStatusEnum.UNOCCUPIED,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.RECTANGLEVERTICAL:
        return RectangleVertical(
          tableModel: tableModel,
          status: tableModel.status ?? TableStatusEnum.UNOCCUPIED,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.RECTANGLEHORIZONTAL:
        return RectangleHorizontal(
          tableModel: tableModel,
          status: tableModel.status ?? TableStatusEnum.UNOCCUPIED,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.LINEHORIZONTAL:
        return LineHorizontal(
          tableModel: tableModel,
          status: tableModel.status ?? TableStatusEnum.UNOCCUPIED,
          seats: tableModel.seats?.toString(),
        );
      case TableTypeEnum.LINEVERTICAL:
        return LineVertical(
          tableModel: tableModel,
          status: tableModel.status ?? TableStatusEnum.UNOCCUPIED,
          seats: tableModel.seats?.toString(),
        );
      default:
        return Container();
    }
  }
}
