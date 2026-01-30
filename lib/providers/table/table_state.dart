import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/table/table_model.dart';

part 'table_state.freezed.dart';

/// Immutable state class for Table domain using Freezed
@freezed
class TableState with _$TableState {
  const factory TableState({
    @Default([]) List<TableModel> items,
    @Default([]) List<TableModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _TableState;
}
