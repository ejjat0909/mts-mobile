import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/user/user_model.dart';

part 'user_state.freezed.dart';

/// Immutable state class for User domain using Freezed
@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default([]) List<UserModel> items,
    String? error,
    @Default(false) bool isLoading,
    UserModel? currentUser,
  }) = _UserState;
}
