import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class CloseShiftFormBloc extends FormBloc<String, String> {
  ShiftModel? shiftModel;
  final expectedAmount = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );
  final actualAmount = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  final differenceAmount = TextFieldBloc();

  CloseShiftFormBloc(this.shiftModel) {
    expectedAmount.updateInitialValue(
      shiftModel!.expectedCash?.toStringAsFixed(2) ?? '0.00',
    );
    double amountExpected = double.parse(expectedAmount.value);
    double diff = 0.00 - amountExpected;

    differenceAmount.updateInitialValue(diff.toStringAsFixed(2));
    addFieldBlocs(fieldBlocs: [expectedAmount, actualAmount, differenceAmount]);

    // double amountActual =
    //     double.parse(actualAmount.value == "" ? "0.00" : actualAmount.value);
    // double different = amountActual - amountExpected;

    // differenceAmount.updateValue(different.toStringAsFixed(2));
  }

  @override
  Future<void> onSubmitting() async {
    try {
      emitSuccess(successResponse: differenceAmount.value);
    } catch (exception) {
      emitFailure(failureResponse: 'Server error');
    }
  }
}
