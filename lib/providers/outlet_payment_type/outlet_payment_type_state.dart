import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';

part 'outlet_payment_type_state.freezed.dart';

/// Immutable state class for OutletPaymentType domain using Freezed
@freezed
class OutletPaymentTypeState with _$OutletPaymentTypeState {
  const factory OutletPaymentTypeState({
    @Default([]) List<OutletPaymentTypeModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _OutletPaymentTypeState;
}
