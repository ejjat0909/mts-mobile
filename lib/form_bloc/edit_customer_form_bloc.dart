import 'package:flutter/material.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/customer/customer_providers.dart';

class EditCustomerFormBloc extends FormBloc<CustomerModel, String> {
  final CustomerModel customerModel;
  final BuildContext context;
  final CustomerNotifier _customerNotifier;

  final name = TextFieldBloc(validators: [ValidationUtils.validateRequired]);
  final phoneNo = TextFieldBloc(
    validators: [ValidationUtils.validatePhoneNumber],
  );
  final email = TextFieldBloc(validators: [ValidationUtils.validateEmail]);
  final address = TextFieldBloc();
  final postcode = TextFieldBloc();
  final note = TextFieldBloc();
  final country = SelectFieldBloc();
  final division = SelectFieldBloc();
  final city = SelectFieldBloc();

  EditCustomerFormBloc(
    this.context,
    this.customerModel,
    this._customerNotifier,
  ) {
    name.updateInitialValue(customerModel.name ?? '');
    phoneNo.updateInitialValue(customerModel.phoneNo ?? '');
    email.updateInitialValue(customerModel.email ?? '');
    address.updateInitialValue(customerModel.address ?? '');
    postcode.updateInitialValue(customerModel.postcode ?? '');
    note.updateInitialValue(customerModel.note ?? '');
    country.updateInitialValue(customerModel.worldCountryId?.toString() ?? '');
    division.updateInitialValue(
      customerModel.worldDivisionId?.toString() ?? '',
    );
    city.updateInitialValue(customerModel.worldCityId?.toString() ?? '');
    addFieldBlocs(
      fieldBlocs: [
        name,
        phoneNo,
        email,
        address,
        postcode,
        note,
        country,
        division,
        city,
      ],
    );
  }

  @override
  Future<void> onSubmitting() async {
    try {
      OutletModel outletModel = ServiceLocator.get<OutletModel>();
      if (customerModel.id != null) {
        CustomerModel editedCustomerModel = CustomerModel(
          id: customerModel.id,
          name: name.value,
          phoneNo: phoneNo.value,
          email: email.value.isNotEmpty ? email.value : null,
          address: address.value.isNotEmpty ? address.value : null,
          postcode: postcode.value.isNotEmpty ? postcode.value : null,
          note: note.value.isNotEmpty ? note.value : null,
          worldCountryId:
              country.value != null ? int.tryParse(country.value!) : null,
          worldDivisionId:
              division.value != null ? int.tryParse(division.value!) : null,
          worldCityId: city.value != null ? int.tryParse(city.value!) : null,
          companyId: outletModel.companyId,
        );

        await _customerNotifier.update(editedCustomerModel);

        emitSuccess(canSubmitAgain: true, successResponse: editedCustomerModel);
      }
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
