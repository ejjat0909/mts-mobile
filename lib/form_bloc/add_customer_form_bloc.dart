import 'package:flutter/material.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/customer/customer_providers.dart';

class AddCustomerFormBloc extends FormBloc<CustomerModel, String> {
  final BuildContext context;
  final CustomerNotifier _customerNotifier;

  // Required fields
  final name = TextFieldBloc(validators: [ValidationUtils.validateRequired]);
  final phoneNo = TextFieldBloc(
    validators: [
      ValidationUtils.validatePhoneNumber,
      ValidationUtils.validateRequired,
    ],
  );

  // Optional fields
  final email = TextFieldBloc(validators: [ValidationUtils.validateEmail]);
  final address = TextFieldBloc();
  final postcode = TextFieldBloc();
  final note = TextFieldBloc();

  // Dropdown fields
  final country = SelectFieldBloc();
  final division = SelectFieldBloc();
  final city = SelectFieldBloc();

  AddCustomerFormBloc(this.context, this._customerNotifier) {
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
      CustomerModel newCustomerModel = CustomerModel(
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

      await _customerNotifier.insert(newCustomerModel);

      prints('done add customer');

      emitSuccess(canSubmitAgain: true, successResponse: newCustomerModel);
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
