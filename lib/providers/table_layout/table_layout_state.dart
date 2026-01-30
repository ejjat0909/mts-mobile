import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';

part 'table_layout_state.freezed.dart';

/// Immutable state class for TableLayout UI using Freezed
@freezed
class TableLayoutState with _$TableLayoutState {
  const factory TableLayoutState({
    @Default(true) bool showSidebar,
    @Default([]) List<TableModel> tableList,
    @Default([]) List<TableModel> tableEditList,
    @Default([]) List<TableSectionModel> sections,
    @Default([]) List<TableSectionModel> editSections,
    TableSectionModel? currSection,
    @Default([]) List<PredefinedOrderModel> poBank,
    @Default(0) int pageNavigator,
    @Default('') String errorMessage,
    @Default(false) bool isLoading,
  }) = _TableLayoutState;
}
