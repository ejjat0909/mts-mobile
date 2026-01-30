import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';

class CustomOrderFormBloc extends FormBloc<Map<String, dynamic>, String> {
  final TableModel tableModel;
  final WidgetRef ref;
  final PredefinedOrderNotifier predefinedOrderNotifier;
  final name = TextFieldBloc(validators: [ValidationUtils.validateRequired]);
  final comment = TextFieldBloc();
  bool hasValueChanged = false; // Track if the value has changed
  late String initialNameValue; // Store the initial value
  bool hasManuallyEdited =
      false; // Track if the value has been manually edited by the user

  CustomOrderFormBloc({
    required this.tableModel,
    required this.ref,
    required this.predefinedOrderNotifier,
  }) {
    String time = DateFormat('kk:mm', 'en_US').format(DateTime.now());
    initialNameValue = 'Order - $time'; // Store the initial value

    // Set the initial value
    name.updateInitialValue(initialNameValue);
    name.updateValue(initialNameValue);

    // We'll handle the clear functionality in the widget using stream listeners
    // since we can't directly override the clear method

    addFieldBlocs(fieldBlocs: [name, comment]);
  }

  @override
  Future<void> onSubmitting() async {
    try {
      OutletModel outletModel = ServiceLocator.get<OutletModel>();
      int columnOrder =
          await ref
              .read(predefinedOrderProvider.notifier)
              .getLatestColumnOrder();

      /// [create new predefined order model]
      PredefinedOrderModel newPO = PredefinedOrderModel(
        id: IdUtils.generateUUID(), // for safe id not null
        outletId: outletModel.id,
        name: name.value,
        remarks: comment.value,
        isOccupied: true,
        isCustom: true,
        orderColumn: columnOrder,
        tableId: tableModel.id,
        tableName: tableModel.name,
      );

      /// [save new predefined order]
      int response = await predefinedOrderNotifier.insert(newPO);

      if (response < 1) {
        await LogUtils.error('FAILED insert new predefined order');
        emitFailure(failureResponse: 'Failed to create new predefined order');
        return;
      }
      await LogUtils.info('SUCCESS create new predefined order');
      emitSuccess(
        successResponse: {'message': 'successCreateNewPO'.tr(), 'data': newPO},
      );

      // Call API to Login
      // UserResponseModel userResponseModel =
      //     await userBloc.login(email.value.trim(), password.value);

      // if (userResponseModel.isSuccess &&
      //     userResponseModel.data!.accessToken != null) {
      // } else {
      //   email.addFieldError(userResponseModel.message);
      //   emitFailure();
      // }
    } catch (e) {
      prints(e.toString());
      await LogUtils.error('FAILED create new predefined order');
      emitFailure(failureResponse: e.toString());
    }
  }
}
