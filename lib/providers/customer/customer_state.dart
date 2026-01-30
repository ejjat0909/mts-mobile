import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/customer/customer_model.dart';

part 'customer_state.freezed.dart';

/// Immutable state class for Customer domain using Freezed
@freezed
class CustomerState with _$CustomerState {
  const factory CustomerState({
    @Default([]) List<CustomerModel> items,
    CustomerModel? currentCustomer, // Current customer in the customer dialogue
    CustomerModel? orderCustomer, // Current customer for the order
    dynamic editCustomerFormBloc, // Form bloc for editing customer
    String? error,
    @Default(false) bool isLoading,
  }) = _CustomerState;
}
