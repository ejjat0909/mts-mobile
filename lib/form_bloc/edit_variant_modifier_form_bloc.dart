import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';

class EditVariantModifierFormBloc extends FormBloc<String, String> {
  SaleItemModel? saleItemModel;
  final qty = TextFieldBloc(validators: [ValidationUtils.validateNumeric]);
  final comment = TextFieldBloc();

  EditVariantModifierFormBloc(this.saleItemModel) {
    qty.updateInitialValue('1');
    if (saleItemModel?.comments != null) {
      comment.updateInitialValue(saleItemModel!.comments!);
    }
    addFieldBlocs(fieldBlocs: [qty, comment]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      // Call API to Login
      // UserResponseModel userResponseModel =
      //     await userBloc.login(email.value.trim(), password.value);

      // if (userResponseModel.isSuccess &&
      //     userResponseModel.data!.accessToken != null) {
      emitSuccess(canSubmitAgain: true);
      // } else {
      //   email.addFieldError(userResponseModel.message);
      //   emitFailure();
      // }
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
