import 'package:easy_localization/easy_localization.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';

class SendEmailFormBloc extends FormBloc<DefaultResponseModel, String> {
  String? _receiptId;
  final ReceiptNotifier _receiptNotifier;
  final ReceiptItemNotifier _receiptItemNotifier;
  final email = TextFieldBloc(
    validators: [
      ValidationUtils.validateRequired,
      ValidationUtils.validateEmail,
    ],
  );

  SendEmailFormBloc({
    required String? receiptId,
    required ReceiptNotifier receiptNotifier,
    required ReceiptItemNotifier receiptItemNotifier,
  }) : _receiptNotifier = receiptNotifier,
       _receiptItemNotifier = receiptItemNotifier {
    _receiptId = receiptId;
    addFieldBlocs(fieldBlocs: [email]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      if (_receiptId == null) {
        emitFailure(failureResponse: 'receiptIdIsNull'.tr());
        return;
      }
      // check receipt model is synced or not
      ReceiptModel? receiptModel = await _receiptNotifier.getReceiptModelFromId(
        _receiptId ?? '',
      );

      if (receiptModel == null) {
        emitFailure(failureResponse: 'receiptModelNotFound'.tr());
        return;
      }

      List<ReceiptItemModel> listReceiptItems = await _receiptItemNotifier
          .getListReceiptItemsByReceiptId(receiptModel.id!);
      if (listReceiptItems.isNotEmpty) {
        // call api send email
        await callApiSendEmail(receiptModel);
      } else {
        emitFailure(failureResponse: 'receiptItemIsEmpty'.tr());
        return;
      }
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }

  Future<void> callApiSendEmail(ReceiptModel receiptModel) async {
    DefaultResponseModel responseModel = await _receiptNotifier
        .sendReceiptToEmail(email.value, receiptModel.id!);

    if (responseModel.isSuccess) {
      await LogUtils.info(responseModel.message);
      emitSuccess(canSubmitAgain: true, successResponse: responseModel);

      return;
    } else {
      await LogUtils.error(responseModel.message);
      emitFailure(failureResponse: responseModel.message);
      return;
    }
  }
}
