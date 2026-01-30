import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';

part 'outlet_state.freezed.dart';

/// Immutable state class for Outlet domain using Freezed
@freezed
class OutletState with _$OutletState {
  const factory OutletState({
    @Default([]) List<OutletModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _OutletState;
}
