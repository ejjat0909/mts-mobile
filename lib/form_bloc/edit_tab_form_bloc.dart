import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class EditTabFormBloc extends FormBloc<String, String> {
  final name = TextFieldBloc(validators: [ValidationUtils.validateRequired]);

  bool hasValueChanged = false; // Track if the value has changed
  late String initialNameValue; // Store the initial value
  bool hasManuallyEdited =
      false; // Track if the value has been manually edited by the user

  EditTabFormBloc(PageModel? pageModel) {
    initialNameValue = pageModel?.pageName ?? '';
    name.updateInitialValue(initialNameValue);

    // Listen to changes in the TextFieldBloc
    name.stream.listen((state) {
      // Check if the value has changed and if it has been manually edited
      if (state.value != initialNameValue && !hasManuallyEdited) {
        hasValueChanged = true;
      } else {
        hasValueChanged = false;
      }
    });

    addFieldBlocs(fieldBlocs: [name]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      // Call API to Login
      // UserResponseModel userResponseModel =
      //     await userBloc.login(email.value.trim(), password.value);

      // if (userResponseModel.isSuccess &&
      //     userResponseModel.data!.accessToken != null) {

      emitSuccess(canSubmitAgain: true, successResponse: name.value);
      // } else {
      //   email.addFieldError(userResponseModel.message);
      //   emitFailure();
      // }
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
