import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/providers/payment/payment_state.dart';

/// StateNotifier for Payment
class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(const PaymentState());

  String get getAppBarTitle => state.appBarTitle;
  int get getCurrentPaymentNavigator => state.paymentNavigator;
  bool get getChangeToPaymentScreen => state.changeToPaymentScreen;

  void setNewPaymentNavigator(int index, {String? title}) {
    state = state.copyWith(
      paymentNavigator: index,
      appBarTitle: title ?? 'payment'.tr(),
    );
  }

  void setChangeToPaymentScreen(bool value) {
    state = state.copyWith(changeToPaymentScreen: value);
  }
}

/// Provider for Payment
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(),
);
