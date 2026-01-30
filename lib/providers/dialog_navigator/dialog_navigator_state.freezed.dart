// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dialog_navigator_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DialogNavigatorState {
  int get pageIndex => throw _privateConstructorUsedError;

  /// Create a copy of DialogNavigatorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DialogNavigatorStateCopyWith<DialogNavigatorState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DialogNavigatorStateCopyWith<$Res> {
  factory $DialogNavigatorStateCopyWith(DialogNavigatorState value,
          $Res Function(DialogNavigatorState) then) =
      _$DialogNavigatorStateCopyWithImpl<$Res, DialogNavigatorState>;
  @useResult
  $Res call({int pageIndex});
}

/// @nodoc
class _$DialogNavigatorStateCopyWithImpl<$Res,
        $Val extends DialogNavigatorState>
    implements $DialogNavigatorStateCopyWith<$Res> {
  _$DialogNavigatorStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DialogNavigatorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pageIndex = null,
  }) {
    return _then(_value.copyWith(
      pageIndex: null == pageIndex
          ? _value.pageIndex
          : pageIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DialogNavigatorStateImplCopyWith<$Res>
    implements $DialogNavigatorStateCopyWith<$Res> {
  factory _$$DialogNavigatorStateImplCopyWith(_$DialogNavigatorStateImpl value,
          $Res Function(_$DialogNavigatorStateImpl) then) =
      __$$DialogNavigatorStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int pageIndex});
}

/// @nodoc
class __$$DialogNavigatorStateImplCopyWithImpl<$Res>
    extends _$DialogNavigatorStateCopyWithImpl<$Res, _$DialogNavigatorStateImpl>
    implements _$$DialogNavigatorStateImplCopyWith<$Res> {
  __$$DialogNavigatorStateImplCopyWithImpl(_$DialogNavigatorStateImpl _value,
      $Res Function(_$DialogNavigatorStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DialogNavigatorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pageIndex = null,
  }) {
    return _then(_$DialogNavigatorStateImpl(
      pageIndex: null == pageIndex
          ? _value.pageIndex
          : pageIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$DialogNavigatorStateImpl implements _DialogNavigatorState {
  const _$DialogNavigatorStateImpl(
      {this.pageIndex = DialogNavigatorEnum.reset});

  @override
  @JsonKey()
  final int pageIndex;

  @override
  String toString() {
    return 'DialogNavigatorState(pageIndex: $pageIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DialogNavigatorStateImpl &&
            (identical(other.pageIndex, pageIndex) ||
                other.pageIndex == pageIndex));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pageIndex);

  /// Create a copy of DialogNavigatorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DialogNavigatorStateImplCopyWith<_$DialogNavigatorStateImpl>
      get copyWith =>
          __$$DialogNavigatorStateImplCopyWithImpl<_$DialogNavigatorStateImpl>(
              this, _$identity);
}

abstract class _DialogNavigatorState implements DialogNavigatorState {
  const factory _DialogNavigatorState({final int pageIndex}) =
      _$DialogNavigatorStateImpl;

  @override
  int get pageIndex;

  /// Create a copy of DialogNavigatorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DialogNavigatorStateImplCopyWith<_$DialogNavigatorStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
