// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'supplier_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SupplierState {
  List<SupplierModel> get items => throw _privateConstructorUsedError;
  SupplierModel? get currentSupplier =>
      throw _privateConstructorUsedError; // Current supplier for operations
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of SupplierState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SupplierStateCopyWith<SupplierState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SupplierStateCopyWith<$Res> {
  factory $SupplierStateCopyWith(
          SupplierState value, $Res Function(SupplierState) then) =
      _$SupplierStateCopyWithImpl<$Res, SupplierState>;
  @useResult
  $Res call(
      {List<SupplierModel> items,
      SupplierModel? currentSupplier,
      String? error,
      bool isLoading});
}

/// @nodoc
class _$SupplierStateCopyWithImpl<$Res, $Val extends SupplierState>
    implements $SupplierStateCopyWith<$Res> {
  _$SupplierStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SupplierState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? currentSupplier = freezed,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SupplierModel>,
      currentSupplier: freezed == currentSupplier
          ? _value.currentSupplier
          : currentSupplier // ignore: cast_nullable_to_non_nullable
              as SupplierModel?,
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
abstract class _$$SupplierStateImplCopyWith<$Res>
    implements $SupplierStateCopyWith<$Res> {
  factory _$$SupplierStateImplCopyWith(
          _$SupplierStateImpl value, $Res Function(_$SupplierStateImpl) then) =
      __$$SupplierStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<SupplierModel> items,
      SupplierModel? currentSupplier,
      String? error,
      bool isLoading});
}

/// @nodoc
class __$$SupplierStateImplCopyWithImpl<$Res>
    extends _$SupplierStateCopyWithImpl<$Res, _$SupplierStateImpl>
    implements _$$SupplierStateImplCopyWith<$Res> {
  __$$SupplierStateImplCopyWithImpl(
      _$SupplierStateImpl _value, $Res Function(_$SupplierStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SupplierState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? currentSupplier = freezed,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$SupplierStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SupplierModel>,
      currentSupplier: freezed == currentSupplier
          ? _value.currentSupplier
          : currentSupplier // ignore: cast_nullable_to_non_nullable
              as SupplierModel?,
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

class _$SupplierStateImpl implements _SupplierState {
  const _$SupplierStateImpl(
      {final List<SupplierModel> items = const [],
      this.currentSupplier,
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<SupplierModel> _items;
  @override
  @JsonKey()
  List<SupplierModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final SupplierModel? currentSupplier;
// Current supplier for operations
  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'SupplierState(items: $items, currentSupplier: $currentSupplier, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SupplierStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.currentSupplier, currentSupplier) ||
                other.currentSupplier == currentSupplier) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      currentSupplier,
      error,
      isLoading);

  /// Create a copy of SupplierState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SupplierStateImplCopyWith<_$SupplierStateImpl> get copyWith =>
      __$$SupplierStateImplCopyWithImpl<_$SupplierStateImpl>(this, _$identity);
}

abstract class _SupplierState implements SupplierState {
  const factory _SupplierState(
      {final List<SupplierModel> items,
      final SupplierModel? currentSupplier,
      final String? error,
      final bool isLoading}) = _$SupplierStateImpl;

  @override
  List<SupplierModel> get items;
  @override
  SupplierModel? get currentSupplier; // Current supplier for operations
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of SupplierState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SupplierStateImplCopyWith<_$SupplierStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
