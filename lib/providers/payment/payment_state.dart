import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/core/enum/payment_navigator_enum.dart';

part 'payment_state.freezed.dart';

/// Immutable state class for PaymentType domain using Freezed
@freezed
class PaymentState with _$PaymentState {
  const factory PaymentState({
    @Default('Payment') String appBarTitle,
    @Default(PaymentNavigatorEnum.paymentScreen) int paymentNavigator,
    @Default(false) bool changeToPaymentScreen,
    String? error,
    @Default(false) bool isLoading,
  }) = _PaymentState;
}
