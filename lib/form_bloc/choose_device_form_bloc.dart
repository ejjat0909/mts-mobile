import 'package:easy_localization/easy_localization.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class ChooseDeviceFormBloc extends FormBloc<String, String> {
  final deviceModel = TextFieldBloc();

  // Get the integer value from the division field bloc
  // int getDeviceValue() {
  //   final deviceModelText = deviceModel.value;
  //   if (deviceModelText.isNotEmpty) {
  //     return int.parse(deviceModelText);
  //   } else {
  //     // Handle the case when the division field is empty or invalid
  //     return 0; // Or any default value you want to use
  //   }
  // }

  // Constructor, to add the field variable to the form
  ChooseDeviceFormBloc() {
    deviceModel.updateInitialValue('-1');
    addFieldBlocs(fieldBlocs: [deviceModel]);
  }

  @override
  void onSubmitting() async {
    if (deviceModel.value != '-1') {
      emitSuccess(successResponse: deviceModel.value);
    } else {
      emitFailure(failureResponse: 'pleaseSelectDevice'.tr());
    }
  }
}
