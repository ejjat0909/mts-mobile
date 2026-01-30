import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/city/city_model.dart';

part 'city_state.freezed.dart';

/// Immutable state class for City domain using Freezed
@freezed
class CityState with _$CityState {
  const factory CityState({
    @Default([]) List<CityModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _CityState;
}
