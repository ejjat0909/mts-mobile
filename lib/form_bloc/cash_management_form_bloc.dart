import 'package:easy_localization/easy_localization.dart';
import 'package:mts/core/enum/cash_management_type_enum.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/shift/shift_providers.dart';

class CashManagementFormBloc extends FormBloc<Map<String, dynamic>, String> {
  final amount = TextFieldBloc(
    validators: [
      ValidationUtils.validateRequired,
      ValidationUtils.validateDouble,
      ValidationUtils.validateDecimalPoint,
      ValidationUtils.numberCannotNegative,
    ],
  );
  final comment = TextFieldBloc();
  final type = TextFieldBloc();

  // Get notifier from Riverpod
  final ShiftNotifier _shiftNotifier;

  CashManagementFormBloc(this._shiftNotifier) {
    addFieldBlocs(fieldBlocs: [amount, comment, type]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      // Use notifier directly instead of BLoC
      double totalExpectedCash = await _shiftNotifier.getLatestExpectedCash();
      ShiftModel shiftModel = await _shiftNotifier.getLatestShift();

      if (type.value == CashManagementTypeEnum.payOut.toString()) {
        // if value is pay out
        if (double.parse(amount.value) > totalExpectedCash) {
          amount.addFieldError('insufficientAmountToPayOut'.tr());
          emitFailure();
        } else {
          CashManagementModel newCMM = CashManagementModel(
            amount: double.parse(amount.value),
            comment: comment.value,
            type: CashManagementTypeEnum.payOut,
            shiftId: shiftModel.id,
            staffId: shiftModel.openedBy,
          );
          ShiftModel newShiftModel = shiftModel.copyWith(
            updatedAt: DateTime.now(),
            expectedCash: totalExpectedCash - double.parse(amount.value),
          );
          Map<String, dynamic> dataSuccess = {
            'cashManagementModel': newCMM,
            'shiftModel': newShiftModel,
          };
          emitSuccess(canSubmitAgain: true, successResponse: dataSuccess);
        }
      } else {
        // if type is pay in
        CashManagementModel newCMM = CashManagementModel(
          amount: double.parse(amount.value),
          comment: comment.value,
          type: CashManagementTypeEnum.payIn,
          shiftId: shiftModel.id,
          staffId: shiftModel.openedBy,
        );
        ShiftModel newShiftModel = shiftModel.copyWith(
          expectedCash: totalExpectedCash + double.parse(amount.value),
        );
        Map<String, dynamic> dataSuccess = {
          'cashManagementModel': newCMM,
          'shiftModel': newShiftModel,
        };
        emitSuccess(canSubmitAgain: true, successResponse: dataSuccess);
      }
    } catch (exception) {
      emitFailure(failureResponse: exception.toString());
    }
  }
}
