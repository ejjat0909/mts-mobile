import 'package:easy_localization/easy_localization.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/device/device_providers.dart';

class ChooseStoreFormBloc extends FormBloc<String, String> {
  final storeModel = TextFieldBloc();
  final DeviceNotifier _deviceNotifier;

  // Get the integer value from the division field bloc
  // int getStoreValue() {
  //   final storeModelText = storeModel.value;
  //   if (storeModelText.isNotEmpty) {
  //     return int.parse(storeModelText);
  //   } else {
  //     // Handle the case when the division field is empty or invalid
  //     return 0; // Or any default value you want to use
  //   }
  // }

  // Constructor, to add the field variable to the form
  ChooseStoreFormBloc(this._deviceNotifier) {
    storeModel.updateInitialValue('-1');
    addFieldBlocs(fieldBlocs: [storeModel]);
  }

  @override
  void onSubmitting() async {
    List<PosDeviceModel> listDevices =
        await _deviceNotifier.getListDevicesFromLocalDB();
    String outletId = storeModel.value;
    prints(listDevices.map((e) => '${e.name} ${e.isActive}').toList());

    listDevices =
        listDevices
            .where(
              (element) =>
                  element.outletId == outletId && element.isActive == false,
            )
            .toList();

    if (storeModel.value != '-1') {
      if (listDevices.isNotEmpty) {
        emitSuccess(successResponse: storeModel.value);
      } else {
        emitFailure(failureResponse: 'noPosDeviceForThisStore'.tr());
      }
    } else {
      emitFailure(failureResponse: 'pleaseSelectStore'.tr());
    }
  }
}
