import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';

part 'payment_type_state.freezed.dart';

/// Immutable state class for PaymentType domain using Freezed
@freezed
class PaymentTypeState with _$PaymentTypeState {
  const factory PaymentTypeState({
    @Default([]) List<PaymentTypeModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _PaymentTypeState;
}
