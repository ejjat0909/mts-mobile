// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tax_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TaxState {
  List<TaxModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of TaxState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaxStateCopyWith<TaxState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaxStateCopyWith<$Res> {
  factory $TaxStateCopyWith(TaxState value, $Res Function(TaxState) then) =
      _$TaxStateCopyWithImpl<$Res, TaxState>;
  @useResult
  $Res call({List<TaxModel> items, String? error, bool isLoading});
}

/// @nodoc
class _$TaxStateCopyWithImpl<$Res, $Val extends TaxState>
    implements $TaxStateCopyWith<$Res> {
  _$TaxStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaxState
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
              as List<TaxModel>,
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
abstract class _$$TaxStateImplCopyWith<$Res>
    implements $TaxStateCopyWith<$Res> {
  factory _$$TaxStateImplCopyWith(
          _$TaxStateImpl value, $Res Function(_$TaxStateImpl) then) =
      __$$TaxStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<TaxModel> items, String? error, bool isLoading});
}

/// @nodoc
class __$$TaxStateImplCopyWithImpl<$Res>
    extends _$TaxStateCopyWithImpl<$Res, _$TaxStateImpl>
    implements _$$TaxStateImplCopyWith<$Res> {
  __$$TaxStateImplCopyWithImpl(
      _$TaxStateImpl _value, $Res Function(_$TaxStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaxState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$TaxStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TaxModel>,
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

class _$TaxStateImpl implements _TaxState {
  const _$TaxStateImpl(
      {final List<TaxModel> items = const [],
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<TaxModel> _items;
  @override
  @JsonKey()
  List<TaxModel> get items {
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
    return 'TaxState(items: $items, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaxStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), error, isLoading);

  /// Create a copy of TaxState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaxStateImplCopyWith<_$TaxStateImpl> get copyWith =>
      __$$TaxStateImplCopyWithImpl<_$TaxStateImpl>(this, _$identity);
}

abstract class _TaxState implements TaxState {
  const factory _TaxState(
      {final List<TaxModel> items,
      final String? error,
      final bool isLoading}) = _$TaxStateImpl;

  @override
  List<TaxModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of TaxState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaxStateImplCopyWith<_$TaxStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
