import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';

part 'table_section_state.freezed.dart';

/// Immutable state class for TableSection domain using Freezed
@freezed
class TableSectionState with _$TableSectionState {
  const factory TableSectionState({
    @Default([]) List<TableSectionModel> items,
    @Default([]) List<TableSectionModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _TableSectionState;
}
