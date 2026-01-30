import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class OpenShiftFormBloc extends FormBloc<String, String> {
  final openShift = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  OpenShiftFormBloc() {
    addFieldBlocs(fieldBlocs: [openShift]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      emitSuccess(successResponse: openShift.value);
    } catch (exception) {
      emitFailure(failureResponse: 'Server error');
    }
  }
}
