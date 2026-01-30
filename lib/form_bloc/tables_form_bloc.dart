import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class TablesFormBloc extends FormBloc<String, String> {
  final predefinedOrder = TextFieldBloc(name: 'predefinedOrder');

  TablesFormBloc() {
    addFieldBlocs(fieldBlocs: [predefinedOrder]);
  }

  @override
  Future<void> onSubmitting() async {
    emitSuccess(successResponse: predefinedOrder.value);
    // if (predefinedOrder.value != '') {
    //   emitSuccess(successResponse: predefinedOrder.value);
    // } else {
    //   emitFailure(failureResponse: 'Please select one open order');
    // }
  }
}
