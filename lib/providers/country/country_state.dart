import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/country/country_model.dart';

part 'country_state.freezed.dart';

/// Immutable state class for Country domain using Freezed
@freezed
class CountryState with _$CountryState {
  const factory CountryState({
    @Default([]) List<CountryModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _CountryState;
}
