// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CustomerState {
  List<CustomerModel> get items => throw _privateConstructorUsedError;
  CustomerModel? get currentCustomer =>
      throw _privateConstructorUsedError; // Current customer in the customer dialogue
  CustomerModel? get orderCustomer =>
      throw _privateConstructorUsedError; // Current customer for the order
  dynamic get editCustomerFormBloc =>
      throw _privateConstructorUsedError; // Form bloc for editing customer
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of CustomerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerStateCopyWith<CustomerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerStateCopyWith<$Res> {
  factory $CustomerStateCopyWith(
          CustomerState value, $Res Function(CustomerState) then) =
      _$CustomerStateCopyWithImpl<$Res, CustomerState>;
  @useResult
  $Res call(
      {List<CustomerModel> items,
      CustomerModel? currentCustomer,
      CustomerModel? orderCustomer,
      dynamic editCustomerFormBloc,
      String? error,
      bool isLoading});
}

/// @nodoc
class _$CustomerStateCopyWithImpl<$Res, $Val extends CustomerState>
    implements $CustomerStateCopyWith<$Res> {
  _$CustomerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? currentCustomer = freezed,
    Object? orderCustomer = freezed,
    Object? editCustomerFormBloc = freezed,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CustomerModel>,
      currentCustomer: freezed == currentCustomer
          ? _value.currentCustomer
          : currentCustomer // ignore: cast_nullable_to_non_nullable
              as CustomerModel?,
      orderCustomer: freezed == orderCustomer
          ? _value.orderCustomer
          : orderCustomer // ignore: cast_nullable_to_non_nullable
              as CustomerModel?,
      editCustomerFormBloc: freezed == editCustomerFormBloc
          ? _value.editCustomerFormBloc
          : editCustomerFormBloc // ignore: cast_nullable_to_non_nullable
              as dynamic,
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
abstract class _$$CustomerStateImplCopyWith<$Res>
    implements $CustomerStateCopyWith<$Res> {
  factory _$$CustomerStateImplCopyWith(
          _$CustomerStateImpl value, $Res Function(_$CustomerStateImpl) then) =
      __$$CustomerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<CustomerModel> items,
      CustomerModel? currentCustomer,
      CustomerModel? orderCustomer,
      dynamic editCustomerFormBloc,
      String? error,
      bool isLoading});
}

/// @nodoc
class __$$CustomerStateImplCopyWithImpl<$Res>
    extends _$CustomerStateCopyWithImpl<$Res, _$CustomerStateImpl>
    implements _$$CustomerStateImplCopyWith<$Res> {
  __$$CustomerStateImplCopyWithImpl(
      _$CustomerStateImpl _value, $Res Function(_$CustomerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of CustomerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? currentCustomer = freezed,
    Object? orderCustomer = freezed,
    Object? editCustomerFormBloc = freezed,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$CustomerStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CustomerModel>,
      currentCustomer: freezed == currentCustomer
          ? _value.currentCustomer
          : currentCustomer // ignore: cast_nullable_to_non_nullable
              as CustomerModel?,
      orderCustomer: freezed == orderCustomer
          ? _value.orderCustomer
          : orderCustomer // ignore: cast_nullable_to_non_nullable
              as CustomerModel?,
      editCustomerFormBloc: freezed == editCustomerFormBloc
          ? _value.editCustomerFormBloc
          : editCustomerFormBloc // ignore: cast_nullable_to_non_nullable
              as dynamic,
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

class _$CustomerStateImpl implements _CustomerState {
  const _$CustomerStateImpl(
      {final List<CustomerModel> items = const [],
      this.currentCustomer,
      this.orderCustomer,
      this.editCustomerFormBloc,
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<CustomerModel> _items;
  @override
  @JsonKey()
  List<CustomerModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final CustomerModel? currentCustomer;
// Current customer in the customer dialogue
  @override
  final CustomerModel? orderCustomer;
// Current customer for the order
  @override
  final dynamic editCustomerFormBloc;
// Form bloc for editing customer
  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'CustomerState(items: $items, currentCustomer: $currentCustomer, orderCustomer: $orderCustomer, editCustomerFormBloc: $editCustomerFormBloc, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.currentCustomer, currentCustomer) ||
                other.currentCustomer == currentCustomer) &&
            (identical(other.orderCustomer, orderCustomer) ||
                other.orderCustomer == orderCustomer) &&
            const DeepCollectionEquality()
                .equals(other.editCustomerFormBloc, editCustomerFormBloc) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      currentCustomer,
      orderCustomer,
      const DeepCollectionEquality().hash(editCustomerFormBloc),
      error,
      isLoading);

  /// Create a copy of CustomerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerStateImplCopyWith<_$CustomerStateImpl> get copyWith =>
      __$$CustomerStateImplCopyWithImpl<_$CustomerStateImpl>(this, _$identity);
}

abstract class _CustomerState implements CustomerState {
  const factory _CustomerState(
      {final List<CustomerModel> items,
      final CustomerModel? currentCustomer,
      final CustomerModel? orderCustomer,
      final dynamic editCustomerFormBloc,
      final String? error,
      final bool isLoading}) = _$CustomerStateImpl;

  @override
  List<CustomerModel> get items;
  @override
  CustomerModel?
      get currentCustomer; // Current customer in the customer dialogue
  @override
  CustomerModel? get orderCustomer; // Current customer for the order
  @override
  dynamic get editCustomerFormBloc; // Form bloc for editing customer
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of CustomerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerStateImplCopyWith<_$CustomerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
