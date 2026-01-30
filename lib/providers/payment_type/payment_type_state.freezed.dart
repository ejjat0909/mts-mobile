// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_type_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PaymentTypeState {
  List<PaymentTypeModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of PaymentTypeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentTypeStateCopyWith<PaymentTypeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentTypeStateCopyWith<$Res> {
  factory $PaymentTypeStateCopyWith(
          PaymentTypeState value, $Res Function(PaymentTypeState) then) =
      _$PaymentTypeStateCopyWithImpl<$Res, PaymentTypeState>;
  @useResult
  $Res call({List<PaymentTypeModel> items, String? error, bool isLoading});
}

/// @nodoc
class _$PaymentTypeStateCopyWithImpl<$Res, $Val extends PaymentTypeState>
    implements $PaymentTypeStateCopyWith<$Res> {
  _$PaymentTypeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentTypeState
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
              as List<PaymentTypeModel>,
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
abstract class _$$PaymentTypeStateImplCopyWith<$Res>
    implements $PaymentTypeStateCopyWith<$Res> {
  factory _$$PaymentTypeStateImplCopyWith(_$PaymentTypeStateImpl value,
          $Res Function(_$PaymentTypeStateImpl) then) =
      __$$PaymentTypeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PaymentTypeModel> items, String? error, bool isLoading});
}

/// @nodoc
class __$$PaymentTypeStateImplCopyWithImpl<$Res>
    extends _$PaymentTypeStateCopyWithImpl<$Res, _$PaymentTypeStateImpl>
    implements _$$PaymentTypeStateImplCopyWith<$Res> {
  __$$PaymentTypeStateImplCopyWithImpl(_$PaymentTypeStateImpl _value,
      $Res Function(_$PaymentTypeStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaymentTypeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$PaymentTypeStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PaymentTypeModel>,
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

class _$PaymentTypeStateImpl implements _PaymentTypeState {
  const _$PaymentTypeStateImpl(
      {final List<PaymentTypeModel> items = const [],
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<PaymentTypeModel> _items;
  @override
  @JsonKey()
  List<PaymentTypeModel> get items {
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
    return 'PaymentTypeState(items: $items, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentTypeStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), error, isLoading);

  /// Create a copy of PaymentTypeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentTypeStateImplCopyWith<_$PaymentTypeStateImpl> get copyWith =>
      __$$PaymentTypeStateImplCopyWithImpl<_$PaymentTypeStateImpl>(
          this, _$identity);
}

abstract class _PaymentTypeState implements PaymentTypeState {
  const factory _PaymentTypeState(
      {final List<PaymentTypeModel> items,
      final String? error,
      final bool isLoading}) = _$PaymentTypeStateImpl;

  @override
  List<PaymentTypeModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of PaymentTypeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentTypeStateImplCopyWith<_$PaymentTypeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
