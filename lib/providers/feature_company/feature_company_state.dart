import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';

part 'feature_company_state.freezed.dart';

/// Immutable state class for FeatureCompany domain using Freezed
@freezed
class FeatureCompanyState with _$FeatureCompanyState {
  const factory FeatureCompanyState({
    @Default([]) List<FeatureCompanyModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _FeatureCompanyState;
}
