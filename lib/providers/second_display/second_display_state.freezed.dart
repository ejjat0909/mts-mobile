// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'second_display_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SecondDisplayState {
  String get currentRouteName => throw _privateConstructorUsedError;
  SlideshowModel? get currentSdModel => throw _privateConstructorUsedError;

  /// Create a copy of SecondDisplayState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SecondDisplayStateCopyWith<SecondDisplayState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SecondDisplayStateCopyWith<$Res> {
  factory $SecondDisplayStateCopyWith(
          SecondDisplayState value, $Res Function(SecondDisplayState) then) =
      _$SecondDisplayStateCopyWithImpl<$Res, SecondDisplayState>;
  @useResult
  $Res call({String currentRouteName, SlideshowModel? currentSdModel});
}

/// @nodoc
class _$SecondDisplayStateCopyWithImpl<$Res, $Val extends SecondDisplayState>
    implements $SecondDisplayStateCopyWith<$Res> {
  _$SecondDisplayStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SecondDisplayState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentRouteName = null,
    Object? currentSdModel = freezed,
  }) {
    return _then(_value.copyWith(
      currentRouteName: null == currentRouteName
          ? _value.currentRouteName
          : currentRouteName // ignore: cast_nullable_to_non_nullable
              as String,
      currentSdModel: freezed == currentSdModel
          ? _value.currentSdModel
          : currentSdModel // ignore: cast_nullable_to_non_nullable
              as SlideshowModel?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SecondDisplayStateImplCopyWith<$Res>
    implements $SecondDisplayStateCopyWith<$Res> {
  factory _$$SecondDisplayStateImplCopyWith(_$SecondDisplayStateImpl value,
          $Res Function(_$SecondDisplayStateImpl) then) =
      __$$SecondDisplayStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String currentRouteName, SlideshowModel? currentSdModel});
}

/// @nodoc
class __$$SecondDisplayStateImplCopyWithImpl<$Res>
    extends _$SecondDisplayStateCopyWithImpl<$Res, _$SecondDisplayStateImpl>
    implements _$$SecondDisplayStateImplCopyWith<$Res> {
  __$$SecondDisplayStateImplCopyWithImpl(_$SecondDisplayStateImpl _value,
      $Res Function(_$SecondDisplayStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SecondDisplayState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentRouteName = null,
    Object? currentSdModel = freezed,
  }) {
    return _then(_$SecondDisplayStateImpl(
      currentRouteName: null == currentRouteName
          ? _value.currentRouteName
          : currentRouteName // ignore: cast_nullable_to_non_nullable
              as String,
      currentSdModel: freezed == currentSdModel
          ? _value.currentSdModel
          : currentSdModel // ignore: cast_nullable_to_non_nullable
              as SlideshowModel?,
    ));
  }
}

/// @nodoc

class _$SecondDisplayStateImpl implements _SecondDisplayState {
  const _$SecondDisplayStateImpl(
      {this.currentRouteName = '', this.currentSdModel});

  @override
  @JsonKey()
  final String currentRouteName;
  @override
  final SlideshowModel? currentSdModel;

  @override
  String toString() {
    return 'SecondDisplayState(currentRouteName: $currentRouteName, currentSdModel: $currentSdModel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SecondDisplayStateImpl &&
            (identical(other.currentRouteName, currentRouteName) ||
                other.currentRouteName == currentRouteName) &&
            (identical(other.currentSdModel, currentSdModel) ||
                other.currentSdModel == currentSdModel));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, currentRouteName, currentSdModel);

  /// Create a copy of SecondDisplayState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SecondDisplayStateImplCopyWith<_$SecondDisplayStateImpl> get copyWith =>
      __$$SecondDisplayStateImplCopyWithImpl<_$SecondDisplayStateImpl>(
          this, _$identity);
}

abstract class _SecondDisplayState implements SecondDisplayState {
  const factory _SecondDisplayState(
      {final String currentRouteName,
      final SlideshowModel? currentSdModel}) = _$SecondDisplayStateImpl;

  @override
  String get currentRouteName;
  @override
  SlideshowModel? get currentSdModel;

  /// Create a copy of SecondDisplayState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SecondDisplayStateImplCopyWith<_$SecondDisplayStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
