import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/data/models/city/city_model.dart';
import 'package:mts/data/models/country/country_model.dart';
import 'package:mts/data/models/division/division_model.dart';
import 'package:mts/form_bloc/add_customer_form_bloc.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/common/widgets/styled_dropdown.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:mts/providers/city/city_providers.dart';
import 'package:mts/providers/country/country_providers.dart';
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

class AddCustomerBody extends ConsumerStatefulWidget {
  final AddCustomerFormBloc addCustomerFormBloc;

  const AddCustomerBody({super.key, required this.addCustomerFormBloc});

  @override
  ConsumerState<AddCustomerBody> createState() => _AddCustomerBodyState();
}

class _AddCustomerBodyState extends ConsumerState<AddCustomerBody> {
  CountryModel? selectedCountry;
  DivisionModel? selectedDivision;
  CityModel? selectedCity;

  @override
  void initState() {
    super.initState();
    ServiceLocator.get<BarcodeScannerNotifier>().disposeScanner();

    // Initialize with default country (ID 87) on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final country = ref.read(countryProvider.notifier).getCountryById(87);
      if (country != null && mounted) {
        setState(() {
          selectedCountry = country;
        });
        widget.addCustomerFormBloc.country.updateValue(country.id.toString());
      }
    });
  }

  @override
  void dispose() {
    ServiceLocator.get<BarcodeScannerNotifier>().initializeForSalesScreen();
    super.dispose();
  }

  void _onCountryChanged(CountryModel? country) {
    setState(() {
      selectedCountry = country;
      selectedDivision = null;
      selectedCity = null;
    });
    widget.addCustomerFormBloc.country.updateValue(
      country?.id.toString() ?? '',
    );
    widget.addCustomerFormBloc.division.updateValue('');
    widget.addCustomerFormBloc.city.updateValue('');
  }

  void _onDivisionChanged(DivisionModel? division) {
    setState(() {
      selectedDivision = division;
      selectedCity = null;
    });
    widget.addCustomerFormBloc.division.updateValue(
      division?.id.toString() ?? '',
    );
    widget.addCustomerFormBloc.city.updateValue('');
  }

  void _onCityChanged(CityModel? city) {
    setState(() {
      selectedCity = city;
    });
    widget.addCustomerFormBloc.city.updateValue(city?.id.toString() ?? '');
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

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                // Name Field
                MyTextFieldBlocBuilder(
                  leading: const Icon(FontAwesomeIcons.user),
                  textFieldBloc: widget.addCustomerFormBloc.name,
                  labelText: 'name'.tr(),
                  hintText: 'ex: Mr Wukong',
                ),

                // Phone Field
                MyTextFieldBlocBuilder(
                  keyboardType: TextInputType.number,
                  leading: const Icon(FontAwesomeIcons.phone),
                  textFieldBloc: widget.addCustomerFormBloc.phoneNo,
                  labelText: 'phone'.tr(),
                  hintText: '0123456789',
                ),

                // Email Field
                MyTextFieldBlocBuilder(
                  keyboardType: TextInputType.emailAddress,
                  leading: const Icon(FontAwesomeIcons.envelope),
                  textFieldBloc: widget.addCustomerFormBloc.email,
                  labelText: "${'email'.tr()} ${'optional'.tr()}",
                  hintText: 'example@mail.com',
                ),

                // Address Field
                MyTextFieldBlocBuilder(
                  leading: const Icon(FontAwesomeIcons.houseChimney),
                  textFieldBloc: widget.addCustomerFormBloc.address,
                  labelText: "${'address'.tr()} ${'optional'.tr()}",
                  hintText: 'ex: 123 Main Street',
                ),

                // Postcode Field
                MyTextFieldBlocBuilder(
                  leading: const Icon(FontAwesomeIcons.houseChimney),
                  textFieldBloc: widget.addCustomerFormBloc.postcode,
                  labelText: "${'postcode'.tr()} ${'optional'.tr()}",
                  hintText: 'ex: 12345',
                ),
                7.5.heightBox,

                // Country Dropdown (Default: ID 87 only)
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

                // Division (State) Dropdown
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
                                            overflow: TextOverflow.ellipsis,
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

                // City Dropdown
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
                                            overflow: TextOverflow.ellipsis,
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

                // Note Field
                MyTextFieldBlocBuilder(
                  leading: const Icon(FontAwesomeIcons.noteSticky),
                  textFieldBloc: widget.addCustomerFormBloc.note,
                  labelText: "${'note'.tr()} ${'optional'.tr()}",
                  hintText: 'ex: VIP Customer',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
