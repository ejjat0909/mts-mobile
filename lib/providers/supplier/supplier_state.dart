import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/supplier/supplier_model.dart';

part 'supplier_state.freezed.dart';

/// Immutable state class for Supplier domain using Freezed
@freezed
class SupplierState with _$SupplierState {
  const factory SupplierState({
    @Default([]) List<SupplierModel> items,
    SupplierModel? currentSupplier, // Current supplier for operations
    String? error,
    @Default(false) bool isLoading,
  }) = _SupplierState;
}
