import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/division/division_model.dart';

part 'division_state.freezed.dart';

/// Immutable state class for Division domain using Freezed
@freezed
class DivisionState with _$DivisionState {
  const factory DivisionState({
    @Default([]) List<DivisionModel> items,
    @Default([]) List<DivisionModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _DivisionState;
}
