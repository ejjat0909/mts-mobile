import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_state.freezed.dart';

@freezed
class AppState with _$AppState {
  const factory AppState({
    @Default('') String currentRoute,
    @Default(true) bool isOnline,
    @Default(false) bool isDarkMode,
    @Default('') String appVersion,
    @Default({}) Map<String, dynamic> additionalContext,
    @Default(false) bool isSyncing,
    @Default(0.0) double syncProgress,
    @Default('') String syncProgressText,
    @Default(true) bool everDontHaveInternet,
  }) = _AppState;
}
