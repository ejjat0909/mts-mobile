import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/data/models/city/city_model.dart';
import 'package:mts/data/models/country/country_model.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/division/division_model.dart';
import 'package:mts/form_bloc/edit_customer_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/common/widgets/styled_dropdown.dart';
import 'package:mts/providers/city/city_providers.dart';
import 'package:mts/providers/country/country_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/division/division_providers.dart';

/// Provider for divisions filtered by country ID
final divisionsByCountryProvider = Provider.family<List<DivisionModel>, int>((
  ref,
  countryId,
) {
  final divisions = ref.watch(divisionProvider).items;
  return divisions.where((d) => d.countryId == countryId).toList();
});

/// Provider for cities filtered by division ID
final citiesByDivisionProvider = Provider.family<List<CityModel>, String>((
  ref,
  divisionId,
) {
  final cities = ref.watch(cityProvider).items;
  return cities.where((c) => c.divisionId == divisionId).toList();
});

class EditCustomerBody extends ConsumerStatefulWidget {
  final EditCustomerFormBloc formBloc;

  const EditCustomerBody({super.key, required this.formBloc});

  @override
  ConsumerState<EditCustomerBody> createState() => _EditCustomerBodyState();
}

class _EditCustomerBodyState extends ConsumerState<EditCustomerBody> {
  CountryModel? selectedCountry;
  DivisionModel? selectedDivision;
  CityModel? selectedCity;

  @override
  void initState() {
    super.initState();

    // Initialize with default country (ID 87) on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final country = ref.read(countryProvider.notifier).getCountryById(87);
      if (country == null) return;

      setState(() {
        selectedCountry = country;
      });
      widget.formBloc.country.updateValue(country.id.toString());

      // Load existing division and city if available
      if (widget.formBloc.customerModel.worldDivisionId != null) {
        final divisions = ref.read(divisionsByCountryProvider(country.id!));

        final division =
            divisions
                .where(
                  (d) => d.id == widget.formBloc.customerModel.worldDivisionId,
                )
                .firstOrNull;

        if (division != null) {
          setState(() {
            selectedDivision = division;
          });

          if (widget.formBloc.customerModel.worldCityId != null) {
            final cities = ref.read(
              citiesByDivisionProvider(division.id.toString()),
            );

            final city =
                cities
                    .where(
                      (c) => c.id == widget.formBloc.customerModel.worldCityId,
                    )
                    .firstOrNull;

            if (city != null && mounted) {
              setState(() {
                selectedCity = city;
              });
            }
          }
        }
      }
    });
  }

  void _onCountryChanged(CountryModel? country) {
    setState(() {
      selectedCountry = country;
      selectedDivision = null;
      selectedCity = null;
    });
    widget.formBloc.country.updateValue(country?.id.toString() ?? '');
    widget.formBloc.division.updateValue('');
    widget.formBloc.city.updateValue('');
  }

  void _onDivisionChanged(DivisionModel? division) {
    setState(() {
      selectedDivision = division;
      selectedCity = null;
    });
    widget.formBloc.division.updateValue(division?.id.toString() ?? '');
    widget.formBloc.city.updateValue('');
  }

  void _onCityChanged(CityModel? city) {
    setState(() {
      selectedCity = city;
    });
    widget.formBloc.city.updateValue(city?.id.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    // Read filtered divisions and cities (no reactive updates needed)
    final filteredDivisions =
        selectedCountry != null
            ? ref.read(divisionsByCountryProvider(selectedCountry!.id!))
            : <DivisionModel>[];

    final filteredCities =
        selectedDivision != null
            ? ref.read(
              citiesByDivisionProvider(selectedDivision!.id.toString()),
            )
            : <CityModel>[];

    return BlocProvider(
      create: (context) {
        return widget.formBloc;
      },
      child: Builder(
        builder: (context) {
          final editCustomerFormBloc = BlocProvider.of<EditCustomerFormBloc>(
            context,
          );

          ref
              .read(customerProvider.notifier)
              .setEditCustomerFormBloc(editCustomerFormBloc);

          return FormBlocListener<EditCustomerFormBloc, CustomerModel, String>(
            onSubmitting: (context, state) {},
            onSuccess: (context, state) {
              editCustomerFormBloc.clear();
              final orderCustomerModel =
                  ref.read(customerProvider).orderCustomer;
              final newCustomerModel = state.successResponse;
              ref
                  .read(dialogNavigatorProvider.notifier)
                  .setPageIndex(DialogNavigatorEnum.viewCustomer);
              if (orderCustomerModel != null) {
                ref
                    .read(customerProvider.notifier)
                    .setOrderCustomerModel(newCustomerModel);
              } else {
                ref
                    .read(customerProvider.notifier)
                    .setCurrentCustomerModel(newCustomerModel);
              }
            },
            onFailure: (context, state) {},
            onSubmissionFailed: (context, state) {},
            child: Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  // physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      MyTextFieldBlocBuilder(
                        leading: const Icon(FontAwesomeIcons.user),
                        textFieldBloc: editCustomerFormBloc.name,
                        labelText: 'name'.tr(),
                        hintText: 'ex: Mr Wukong',
                      ),
                      MyTextFieldBlocBuilder(
                        leading: const Icon(FontAwesomeIcons.phone),
                        textFieldBloc: editCustomerFormBloc.phoneNo,
                        labelText: 'phone'.tr(),
                        hintText: '0123456789',
                      ),
                      MyTextFieldBlocBuilder(
                        keyboardType: TextInputType.emailAddress,
                        leading: const Icon(FontAwesomeIcons.envelope),
                        textFieldBloc: editCustomerFormBloc.email,
                        labelText: "${'email'.tr()} ${'optional'.tr()}",
                        hintText: 'example@mail.com',
                      ),
                      MyTextFieldBlocBuilder(
                        leading: const Icon(FontAwesomeIcons.houseChimney),
                        textFieldBloc: editCustomerFormBloc.address,
                        labelText: "${'address'.tr()} ${'optional'.tr()}",
                        hintText: 'ex: 123 Main Street',
                      ),
                      MyTextFieldBlocBuilder(
                        leading: const Icon(FontAwesomeIcons.houseChimney),
                        textFieldBloc: editCustomerFormBloc.postcode,
                        labelText: "${'postcode'.tr()} ${'optional'.tr()}",
                        hintText: 'ex: 12345',
                      ),
                      7.5.heightBox,
                      Visibility(
                        visible: false,
                        child: StyledDropdown<CountryModel>(
                          items:
                              [selectedCountry!]
                                  .map<DropdownMenuItem<CountryModel>>(
                                    (CountryModel model) =>
                                        DropdownMenuItem<CountryModel>(
                                          value: model,
                                          child: Text(
                                            model.name ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                  )
                                  .toList(),
                          selected: selectedCountry,
                          list: [selectedCountry!],
                          setDropdownValue: _onCountryChanged,
                        ),
                      ),
                      if (filteredDivisions.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${'state'.tr()} ${'optional'.tr()}",
                              style: textStyleNormal(),
                            ),
                            5.heightBox,
                            StyledDropdown<DivisionModel>(
                              items:
                                  filteredDivisions
                                      .map<DropdownMenuItem<DivisionModel>>(
                                        (DivisionModel model) =>
                                            DropdownMenuItem<DivisionModel>(
                                              value: model,
                                              child: Text(
                                                model.name ?? 'N/A',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList(),
                              selected: selectedDivision,
                              list: filteredDivisions,
                              setDropdownValue: _onDivisionChanged,
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('noDivisionsAvailable'.tr()),
                        ),
                      12.5.heightBox,
                      if (filteredCities.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${'city'.tr()} ${'optional'.tr()}",
                              style: textStyleNormal(),
                            ),
                            5.heightBox,
                            StyledDropdown<CityModel>(
                              items:
                                  filteredCities
                                      .map<DropdownMenuItem<CityModel>>(
                                        (CityModel model) =>
                                            DropdownMenuItem<CityModel>(
                                              value: model,
                                              child: Text(
                                                model.name ?? 'N/A',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList(),
                              selected: selectedCity,
                              list: filteredCities,
                              setDropdownValue: _onCityChanged,
                            ),
                          ],
                        )
                      else if (selectedDivision != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('noCitiesAvailable'.tr()),
                        ),
                      5.heightBox,
                      MyTextFieldBlocBuilder(
                        leading: const Icon(FontAwesomeIcons.noteSticky),
                        textFieldBloc: editCustomerFormBloc.note,
                        labelText: "${'note'.tr()} ${'optional'.tr()}",
                        hintText: 'ex: VIP Customer',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
