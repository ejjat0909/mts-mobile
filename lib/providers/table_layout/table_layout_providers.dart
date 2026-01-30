import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/table_type_enum.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/table/table_providers.dart';
import 'package:mts/providers/table_layout/table_layout_state.dart';
import 'package:mts/providers/table_section/table_section_providers.dart';

/// Riverpod StateNotifier for TableLayout UI
class TableLayoutNotifier extends StateNotifier<TableLayoutState> {
  final Ref _ref;

  TableLayoutNotifier({required Ref ref})
    : _ref = ref,
      super(const TableLayoutState());

  /// Initialize table view mode - load tables and sections from database
  Future<void> initTableView() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    final tableNotifier = _ref.read(tableProvider.notifier);
    final tableSectionNotifier = _ref.read(tableSectionProvider.notifier);
    try {
      // Load tables and sections from facades
      final tables = await tableNotifier.getTables();
      final sections = await tableSectionNotifier.getTableSections();

      // Set first section as current if available
      final currSection = sections.isNotEmpty ? sections[0] : null;

      state = state.copyWith(
        tableList: tables,
        sections: sections,
        currSection: currSection,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load table view: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Initialize table edit mode - create deep copies for editing
  Future<void> initTableEdit() async {
    final tableNotifier = _ref.read(tableProvider.notifier);
    final tableSectionNotifier = _ref.read(tableSectionProvider.notifier);
    final predefinedOrderNotifier = _ref.read(predefinedOrderProvider.notifier);

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      // Load tables and create deep copies for editing
      final tables = await tableNotifier.getTables();
      final tableEditList = tables.map((table) => table.copyWith()).toList();

      // Load sections and create deep copies for editing
      final sections = await tableSectionNotifier.getTableSections();
      final editSections =
          sections.map((section) => section.copyWith()).toList();

      // Set first section as current if available
      final currSection = editSections.isNotEmpty ? editSections[0] : null;

      // Load predefined order bank - get IDs from tables
      final poIDList = tableEditList.map((e) => e.predefinedOrderId).toList();
      final poBank = await predefinedOrderNotifier.getPredefinedOrderByIds(
        poIDList,
      );

      state = state.copyWith(
        tableList: tables,
        tableEditList: tableEditList,
        sections: sections,
        editSections: editSections,
        currSection: currSection,
        poBank: poBank,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load table edit: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // ----- TABLE OPERATIONS (Edit Mode) -----

  /// Add new table to edit list
  void addTable(TableModel table) {
    final updatedEditList = [...state.tableEditList, table];
    state = state.copyWith(tableEditList: updatedEditList);
  }

  /// Modify table position (for dragging in edit mode)
  void modifyTable(TableModel table, double? left, double? top) {
    if (left != null) {
      table.left = left;
    }
    if (top != null) {
      table.top = top;
    }

    table.updatedAt = DateTime.now();

    final updatedEditList =
        state.tableEditList.map((t) {
          return t.id == table.id ? table : t;
        }).toList();
    state = state.copyWith(tableEditList: updatedEditList);
  }

  /// Remove table from edit list
  void removeTable(TableModel table) {
    final updatedEditList =
        state.tableEditList.where((t) => t.id != table.id).toList();
    state = state.copyWith(tableEditList: updatedEditList);
  }

  // ----- SECTION OPERATIONS (Edit Mode) -----

  /// Add new section to edit list
  void addSection(TableSectionModel section) {
    final updatedEditSections = [...state.editSections, section];
    state = state.copyWith(editSections: updatedEditSections);
  }

  /// Modify section name in the edit list (matches old notifier)
  void modifySection(TableSectionModel model, String newName) {
    model.name = newName;
    model.updatedAt = DateTime.now();

    final updatedEditSections =
        state.editSections.map((s) {
          return s.id == model.id ? model : s;
        }).toList();
    state = state.copyWith(editSections: updatedEditSections);
  }

  /// Remove section from edit list (matches old notifier)
  void removeSection(String id) {
    final updatedEditSections =
        state.editSections.where((s) => s.id != id).toList();
    final updatedTableEditList =
        state.tableEditList.where((t) => t.tableSectionId != id).toList();

    // Update current section if needed
    TableSectionModel? newCurrSection = state.currSection;
    if (updatedEditSections.isNotEmpty && state.currSection?.id == id) {
      newCurrSection = updatedEditSections[0];
    }

    state = state.copyWith(
      editSections: updatedEditSections,
      tableEditList: updatedTableEditList,
      currSection: newCurrSection,
    );
  }

  // ----- COMPLEX DATABASE SYNC -----

  /// Apply all changes from edit mode to database
  /// Complex logic: handles inserts, updates, deletes for both tables and sections
  Future<void> applyChanges() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    final tableNotifier = _ref.read(tableProvider.notifier);
    final tableSectionNotifier = _ref.read(tableSectionProvider.notifier);
    final predefinedOrderNotifier = _ref.read(predefinedOrderProvider.notifier);

    try {
      final saleNotifier = _ref.read(saleProvider.notifier);
      final OutletModel outlet = ServiceLocator.get<OutletModel>();

      // ----- SECTION CHANGES -----

      // Find sections to delete (in original but not in edit)
      final sectionsToDelete =
          state.sections.where((original) {
            return !state.editSections.any((edit) => edit.id == original.id);
          }).toList();

      // Find sections to insert (no id or id not in original)
      final sectionsToInsert =
          state.editSections.where((edit) {
            return edit.id == null ||
                !state.sections.any((original) => original.id == edit.id);
          }).toList();

      // Find sections to update (id exists in both)
      final sectionsToUpdate =
          state.editSections.where((edit) {
            return edit.id != null &&
                state.sections.any((original) => original.id == edit.id);
          }).toList();

      // Execute section operations
      for (final section in sectionsToDelete) {
        await tableSectionNotifier.delete(section.id!);
      }

      for (final section in sectionsToInsert) {
        final newSection = section.copyWith(outletId: outlet.id);
        await tableSectionNotifier.insert(newSection);
      }

      for (final section in sectionsToUpdate) {
        await tableSectionNotifier.update(section);
      }

      // ----- TABLE CHANGES -----

      // Find tables to delete (in original but not in edit)
      final tablesToDelete =
          state.tableList.where((original) {
            return !state.tableEditList.any((edit) => edit.id == original.id);
          }).toList();

      // Find tables to insert (no id or id not in original)
      final tablesToInsert =
          state.tableEditList.where((edit) {
            return edit.id == null ||
                !state.tableList.any((original) => original.id == edit.id);
          }).toList();

      // Find tables to update (id exists in both)
      final tablesToUpdate =
          state.tableEditList.where((edit) {
            return edit.id != null &&
                state.tableList.any((original) => original.id == edit.id);
          }).toList();

      // Execute table operations
      for (final table in tablesToDelete) {
        await tableNotifier.delete(table.id!);
      }

      for (final table in tablesToInsert) {
        final newTable = table.copyWith(outletId: outlet.id);
        await tableNotifier.insert(newTable);
      }

      for (final table in tablesToUpdate) {
        await tableNotifier.update(table);
      }

      // Handle predefined order updates - assign table IDs to POs
      List<TableModel> tablesWithPO =
          state.tableEditList
              .where(
                (element) =>
                    element.predefinedOrderId != null &&
                    element.predefinedOrderId!.isNotEmpty,
              )
              .toList();

      List<TableModel> tablesWithoutPO =
          state.tableEditList
              .where((element) => element.predefinedOrderId == null)
              .toList();

      // Get custom POs that have tables assigned
      List<PredefinedOrderModel> customPoHaveTable =
          await predefinedOrderNotifier.getCustomPoThatHaveTable();

      final updatedPOBank = [...state.poBank, ...customPoHaveTable];

      // Update POs that have tables assigned
      for (TableModel table in tablesWithPO) {
        try {
          PredefinedOrderModel predefinedOrder = updatedPOBank.firstWhere(
            (element) => element.id == table.predefinedOrderId,
          );
          predefinedOrder.tableId = table.id;
          predefinedOrder.tableName = table.name;
          await predefinedOrderNotifier.update(predefinedOrder);
        } catch (e) {
          // PO not found in bank, skip
        }
      }

      // Clear table reference from POs that no longer have tables
      List<String> tableWithoutPOIds =
          tablesWithoutPO.map((e) => e.id!).toList();
      if (tableWithoutPOIds.isNotEmpty) {
        List<PredefinedOrderModel> poList = await predefinedOrderNotifier
            .getListPoByTableIds(tableWithoutPOIds);
        for (PredefinedOrderModel predefinedOrder in poList) {
          predefinedOrder.tableId = null;
          predefinedOrder.tableName = null;
          await predefinedOrderNotifier.update(predefinedOrder);
        }
      }

      // Clear table references from deleted tables
      for (final table in tablesToDelete) {
        await predefinedOrderNotifier.clearTableReferenceByTableId(table.id!);
        await saleNotifier.clearTableReferenceByTableId(table.id!);
      }

      // Reload fresh data after all changes
      await initTableView();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to apply changes: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // ----- TABLE STATE MANAGEMENT (View Mode) -----

  /// Reset table by ID (matches old notifier signature)
  Future<TableModel> resetTableById(
    String id, {
    bool clearOpenOrder = true,
  }) async {
    final tableNotifier = _ref.read(tableProvider.notifier);
    try {
      TableModel? model = state.tableList.firstWhere(
        (element) => element.id == id,
        orElse: () => TableModel(),
      );

      if (model.id != null) {
        final updatedModel = model.copyWith(
          saleId: null,
          staffId: null,
          status: 0,
          customerId: null,
          predefinedOrderId: clearOpenOrder ? null : model.predefinedOrderId,
          updatedAt: DateTime.now(),
        );

        await tableNotifier.update(updatedModel);

        // Update in tableList
        final updatedTableList =
            state.tableList.map((t) {
              return t.id == id ? updatedModel : t;
            }).toList();

        // Update in tableEditList if exists
        final updatedEditList =
            state.tableEditList.map((t) {
              if (t.id == id) {
                return updatedModel.copyWith(
                  tableSectionId:
                      updatedModel.tableSectionId ?? t.tableSectionId,
                );
              }
              return t;
            }).toList();

        state = state.copyWith(
          tableList: updatedTableList,
          tableEditList: updatedEditList,
        );

        return updatedModel;
      }
      return TableModel();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to reset table: ${e.toString()}',
      );
      return TableModel();
    }
  }

  /// Update table by ID (backward compatibility with old notifier)
  Future<TableModel> updateTableById(
    String id, {
    String? saleId,
    int? status,
    String? staffId,
    String? predefinedOrderId,
    String? customerId,
  }) async {
    try {
      final tableNotifier = _ref.read(tableProvider.notifier);

      TableModel model = state.tableList.firstWhere(
        (element) => element.id == id,
        orElse: () => TableModel(),
      );

      if (model.id != null) {
        bool changed = false;
        Map<String, dynamic> updates = {};

        if (saleId != null && model.saleId != saleId) {
          updates['saleId'] = saleId;
          changed = true;
        }
        if (staffId != null && model.staffId != staffId) {
          updates['staffId'] = staffId;
          changed = true;
        }
        if (status != null && model.status != status) {
          updates['status'] = status;
          changed = true;
        }
        if (predefinedOrderId != null &&
            model.predefinedOrderId != predefinedOrderId) {
          updates['predefinedOrderId'] = predefinedOrderId;
          changed = true;
        }
        if (customerId != null && model.customerId != customerId) {
          updates['customerId'] = customerId;
          changed = true;
        }

        if (changed) {
          updates['updatedAt'] = DateTime.now();
          final updatedModel = model.copyWith(
            saleId: saleId ?? model.saleId,
            staffId: staffId ?? model.staffId,
            status: status ?? model.status,
            predefinedOrderId: predefinedOrderId ?? model.predefinedOrderId,
            customerId: customerId ?? model.customerId,
            updatedAt: DateTime.now(),
          );

          await tableNotifier.update(updatedModel);

          // Update in tableList
          final updatedTableList =
              state.tableList.map((t) {
                return t.id == id ? updatedModel : t;
              }).toList();

          // Update in tableEditList if exists
          final updatedEditList =
              state.tableEditList.map((t) {
                if (t.id == id) {
                  return updatedModel.copyWith(
                    tableSectionId:
                        updatedModel.tableSectionId ?? t.tableSectionId,
                  );
                }
                return t;
              }).toList();

          state = state.copyWith(
            tableList: updatedTableList,
            tableEditList: updatedEditList,
          );

          return updatedModel;
        }
      }
      return model.id != null ? model : TableModel();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update table: ${e.toString()}',
      );
      return TableModel();
    }
  }

  // ----- UI STATE CHANGES -----

  /// Toggle sidebar visibility
  void setShowSidebar(bool value) {
    state = state.copyWith(showSidebar: value);
  }

  /// Set current page navigator
  void setPageNavigator(int value) {
    state = state.copyWith(pageNavigator: value);
  }

  /// Set error message
  void setErrorMessage(String message) {
    state = state.copyWith(errorMessage: message);
  }

  /// Add predefined order to bank
  void addToPOBank(PredefinedOrderModel model) {
    final updatedBank = [...state.poBank, model];
    state = state.copyWith(poBank: updatedBank);
  }

  /// Remove predefined order from bank
  void removeFromPOBank(PredefinedOrderModel model) {
    final updatedBank = state.poBank.where((po) => po.id != model.id).toList();
    state = state.copyWith(poBank: updatedBank);
  }

  /// Reset edit changes (clear edit lists and reset current section if needed)
  void resetEditChanges() {
    // Reset current section if it's not in the sections list
    TableSectionModel? newCurrSection = state.currSection;
    if (state.sections.isNotEmpty && state.currSection != null) {
      final sectionExists = state.sections.any(
        (s) => s.id == state.currSection!.id,
      );
      if (!sectionExists) {
        newCurrSection = state.sections.last;
      }
    }

    state = state.copyWith(
      tableEditList: [],
      editSections: [],
      currSection: newCurrSection,
    );
  }

  // ----- QUERIES -----

  /// Get table by ID or predefinedOrderId from current list
  TableModel? getTableModel(String? id, {String? predefinedOrderId}) {
    if (predefinedOrderId != null) {
      List<TableModel> res =
          state.tableList
              .where(
                (element) => element.predefinedOrderId == predefinedOrderId,
              )
              .toList();
      if (res.isNotEmpty) {
        return res.first;
      }
      return null;
    }

    if (id == null) {
      return null;
    }
    return state.tableList.firstWhere(
      (element) => element.id == id,
      orElse: () => TableModel(),
    );
  }

  /// Get all tables
  List<TableModel> get allTable => state.tableList;

  /// Get edit list
  List<TableModel> get tableEditList => state.tableEditList;

  /// Get edit sections
  List<TableSectionModel> get editSections => state.editSections;

  /// Get edit tables for specific section (matches old setTableEditList)
  List<TableModel> setTableEditList(String? tableSectionId) {
    if (tableSectionId == null) {
      return [];
    }
    return state.tableEditList
        .where((element) => element.tableSectionId == tableSectionId)
        .toList();
  }

  /// Get current table list for section (matches old getCurrentTableList)
  List<TableModel> getCurrentTableList(String tableSectionId) {
    return state.tableList
        .where((element) => element.tableSectionId == tableSectionId)
        .toList();
  }

  /// Add or update predefined orders in bank
  void addOrUpdatePoBank(List<PredefinedOrderModel> list) {
    final updatedBank = [...state.poBank];
    for (PredefinedOrderModel po in list) {
      int index = updatedBank.indexWhere((element) => element.id == po.id);
      if (index != -1) {
        updatedBank[index] = po;
      } else {
        updatedBank.add(po);
      }
    }
    state = state.copyWith(poBank: updatedBank);
  }

  /// Check if table shape can be edited (for dialog display)
  bool tableShapeCanEdit(TableModel tableModel) {
    return tableModel.type == TableTypeEnum.CIRCLE ||
        tableModel.type == TableTypeEnum.SQUARE ||
        tableModel.type == TableTypeEnum.RECTANGLEVERTICAL ||
        tableModel.type == TableTypeEnum.RECTANGLEHORIZONTAL;
  }

  // ----- SYNC/UPDATE METHODS (for backward compatibility) -----

  /// Set table list (for manually sync data)
  void setTableList(List<TableModel> list) {
    state = state.copyWith(tableList: list, tableEditList: list);
  }

  /// Set sections list (for manually sync data)
  void setSections(List<TableSectionModel> list) {
    state = state.copyWith(sections: list, editSections: list);
  }

  /// Update table list from sync/real-time updates
  void addOrUpdateListTable(List<TableModel> tables) {
    if (tables.isEmpty) return;

    final updatedTableList = [...state.tableList];
    for (final newTable in tables) {
      final index = updatedTableList.indexWhere((t) => t.id == newTable.id);
      if (index != -1) {
        updatedTableList[index] = newTable;
      } else {
        updatedTableList.add(newTable);
      }
    }
    state = state.copyWith(tableList: updatedTableList);
  }

  /// Update section list from sync/real-time updates
  void addOrUpdateListSections(List<TableSectionModel> sections) {
    if (sections.isEmpty) return;

    final updatedSections = [...state.sections];
    for (final newSection in sections) {
      final index = updatedSections.indexWhere((s) => s.id == newSection.id);
      if (index != -1) {
        updatedSections[index] = newSection;
      } else {
        updatedSections.add(newSection);
      }
    }
    state = state.copyWith(sections: updatedSections);
  }

  /// Delete tables from list (for sync operations)
  void deleteBulkTable(List<TableModel> tables) {
    final updatedTableList =
        state.tableList.where((table) {
          return !tables.any((t) => t.id == table.id);
        }).toList();
    state = state.copyWith(tableList: updatedTableList);
  }

  /// Delete sections from list (for sync operations)
  void deleteBulkSections(List<TableSectionModel> sections) {
    final updatedSections =
        state.sections.where((section) {
          return !sections.any((s) => s.id == section.id);
        }).toList();
    state = state.copyWith(sections: updatedSections);
  }

  /// Legacy method for backward compatibility - matches old notifier signature
  void setCurrSection(TableSectionModel section) {
    state = state.copyWith(currSection: section);
  }

  /// Legacy getter for backward compatibility
  TableSectionModel? get currSection => state.currSection;

  /// Legacy getter for backward compatibility
  List<TableSectionModel> get sections => state.sections;

  /// Legacy getter for backward compatibility
  bool get showSidebar => state.showSidebar;

  /// Legacy getter for backward compatibility
  int get getPageNavigator => state.pageNavigator;

  /// Legacy getter for backward compatibility
  List<PredefinedOrderModel> get poBank => state.poBank;

  /// Legacy getter for backward compatibility
  String get getErrorMessage => state.errorMessage;
}

/// StateNotifierProvider for TableLayout
final tableLayoutProvider =
    StateNotifierProvider<TableLayoutNotifier, TableLayoutState>((ref) {
      return TableLayoutNotifier(ref: ref);
    });

/// Computed providers for common queries

/// Get tables for current section
final currentSectionTablesProvider = Provider<List<TableModel>>((ref) {
  final state = ref.watch(tableLayoutProvider);
  if (state.currSection == null) return [];
  return state.tableList.where((table) {
    return table.tableSectionId == state.currSection!.id;
  }).toList();
});

/// Get occupied tables count
final occupiedTablesCountProvider = Provider<int>((ref) {
  final tables = ref.watch(tableLayoutProvider).tableList;
  return tables.where((table) => table.status == 1).length;
});

/// Get total tables count
final totalTablesCountProvider = Provider<int>((ref) {
  return ref.watch(tableLayoutProvider).tableList.length;
});
