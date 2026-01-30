import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/feature/feature_model.dart';

part 'feature_state.freezed.dart';

/// Immutable state class for Feature domain using Freezed
@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    @Default([]) List<FeatureModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _FeatureState;
}
