// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error_log_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ErrorLogState {
  List<ErrorLogModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of ErrorLogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ErrorLogStateCopyWith<ErrorLogState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ErrorLogStateCopyWith<$Res> {
  factory $ErrorLogStateCopyWith(
          ErrorLogState value, $Res Function(ErrorLogState) then) =
      _$ErrorLogStateCopyWithImpl<$Res, ErrorLogState>;
  @useResult
  $Res call({List<ErrorLogModel> items, String? error, bool isLoading});
}

/// @nodoc
class _$ErrorLogStateCopyWithImpl<$Res, $Val extends ErrorLogState>
    implements $ErrorLogStateCopyWith<$Res> {
  _$ErrorLogStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ErrorLogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ErrorLogModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ErrorLogStateImplCopyWith<$Res>
    implements $ErrorLogStateCopyWith<$Res> {
  factory _$$ErrorLogStateImplCopyWith(
          _$ErrorLogStateImpl value, $Res Function(_$ErrorLogStateImpl) then) =
      __$$ErrorLogStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ErrorLogModel> items, String? error, bool isLoading});
}

/// @nodoc
class __$$ErrorLogStateImplCopyWithImpl<$Res>
    extends _$ErrorLogStateCopyWithImpl<$Res, _$ErrorLogStateImpl>
    implements _$$ErrorLogStateImplCopyWith<$Res> {
  __$$ErrorLogStateImplCopyWithImpl(
      _$ErrorLogStateImpl _value, $Res Function(_$ErrorLogStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ErrorLogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$ErrorLogStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ErrorLogModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ErrorLogStateImpl implements _ErrorLogState {
  const _$ErrorLogStateImpl(
      {final List<ErrorLogModel> items = const [],
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<ErrorLogModel> _items;
  @override
  @JsonKey()
  List<ErrorLogModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'ErrorLogState(items: $items, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorLogStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), error, isLoading);

  /// Create a copy of ErrorLogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorLogStateImplCopyWith<_$ErrorLogStateImpl> get copyWith =>
      __$$ErrorLogStateImplCopyWithImpl<_$ErrorLogStateImpl>(this, _$identity);
}

abstract class _ErrorLogState implements ErrorLogState {
  const factory _ErrorLogState(
      {final List<ErrorLogModel> items,
      final String? error,
      final bool isLoading}) = _$ErrorLogStateImpl;

  @override
  List<ErrorLogModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of ErrorLogState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorLogStateImplCopyWith<_$ErrorLogStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
