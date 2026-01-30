import 'package:flutter/material.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class DiscountFormBloc extends FormBloc<String, String> {
  BuildContext context;
  bool isSplitPayment = false;
  final double totalAmountRemaining;
  final discount = TextFieldBloc(
    validators: [
      ValidationUtils.validateRequired,
      ValidationUtils.validateDouble,
      ValidationUtils.validateDecimalPoint,
      ValidationUtils.numberCannotNegative,
    ],
  );

  DiscountFormBloc(
    this.context,
    this.isSplitPayment,
    this.totalAmountRemaining,
  ) {
    addFieldBlocs(fieldBlocs: [discount]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      final discountAmount = double.parse(discount.value);

      // Validate against total amount remaining (business rule)
      if (discountAmount > totalAmountRemaining) {
        discount.addFieldError(
          'Adjustment amount cannot be greater than total amount remaining',
        );
        emitFailure();
        return;
      }

      emitSuccess(canSubmitAgain: true, successResponse: discount.value);
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
