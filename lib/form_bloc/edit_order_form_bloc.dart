import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';

class EditOrderFormBloc extends FormBloc<PredefinedOrderModel, String> {
  final PredefinedOrderNotifier predefinedOrderNotifier;
  final PredefinedOrderModel currentPOM;
  final name = TextFieldBloc(validators: [ValidationUtils.validateRequired]);

  final comment = TextFieldBloc();
  bool hasValueChanged = false; // Track if the value has changed
  late String initialNameValue; // Store the initial value
  late String initialCommentValue;

  bool hasManuallyEdited = false;

  EditOrderFormBloc({
    required this.currentPOM,
    required this.predefinedOrderNotifier,
  }) {
    String time = DateFormat('kk:mm', 'en_US').format(DateTime.now());
    if (currentPOM.id != null) {
      initialNameValue = '${currentPOM.name}';
      initialCommentValue = currentPOM.remarks ?? '';
    } else {
      /// [this case shoulld never happen because currentPOM.id should be not null]
      initialNameValue = 'Order $time';
      initialCommentValue = '';
    }

    // Set the initial value
    name.updateInitialValue(initialNameValue);
    name.updateValue(initialNameValue);

    // set the initial comment
    comment.updateInitialValue(initialCommentValue);
    comment.updateValue(initialCommentValue);
    addFieldBlocs(fieldBlocs: [name, comment]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      /// [update the predefined order]
      if (currentPOM.id != null) {
        PredefinedOrderModel updatePOM = currentPOM.copyWith(
          name: name.value,
          remarks: comment.value,
          isCustom: true,
        );

        await predefinedOrderNotifier.update(updatePOM);
        emitSuccess(canSubmitAgain: true, successResponse: updatePOM);
      } else {
        emitFailure(failureResponse: 'No order is opened');
      }
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
