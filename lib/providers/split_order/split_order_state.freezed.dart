// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'split_order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SplitOrderState {
  List<List<SaleItemModel>> get cards => throw _privateConstructorUsedError;
  Map<int, List<SaleItemModel>> get selectedItems =>
      throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of SplitOrderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SplitOrderStateCopyWith<SplitOrderState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SplitOrderStateCopyWith<$Res> {
  factory $SplitOrderStateCopyWith(
          SplitOrderState value, $Res Function(SplitOrderState) then) =
      _$SplitOrderStateCopyWithImpl<$Res, SplitOrderState>;
  @useResult
  $Res call(
      {List<List<SaleItemModel>> cards,
      Map<int, List<SaleItemModel>> selectedItems,
      String? error,
      bool isLoading});
}

/// @nodoc
class _$SplitOrderStateCopyWithImpl<$Res, $Val extends SplitOrderState>
    implements $SplitOrderStateCopyWith<$Res> {
  _$SplitOrderStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SplitOrderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cards = null,
    Object? selectedItems = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      cards: null == cards
          ? _value.cards
          : cards // ignore: cast_nullable_to_non_nullable
              as List<List<SaleItemModel>>,
      selectedItems: null == selectedItems
          ? _value.selectedItems
          : selectedItems // ignore: cast_nullable_to_non_nullable
              as Map<int, List<SaleItemModel>>,
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
abstract class _$$SplitOrderStateImplCopyWith<$Res>
    implements $SplitOrderStateCopyWith<$Res> {
  factory _$$SplitOrderStateImplCopyWith(_$SplitOrderStateImpl value,
          $Res Function(_$SplitOrderStateImpl) then) =
      __$$SplitOrderStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<List<SaleItemModel>> cards,
      Map<int, List<SaleItemModel>> selectedItems,
      String? error,
      bool isLoading});
}

/// @nodoc
class __$$SplitOrderStateImplCopyWithImpl<$Res>
    extends _$SplitOrderStateCopyWithImpl<$Res, _$SplitOrderStateImpl>
    implements _$$SplitOrderStateImplCopyWith<$Res> {
  __$$SplitOrderStateImplCopyWithImpl(
      _$SplitOrderStateImpl _value, $Res Function(_$SplitOrderStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SplitOrderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cards = null,
    Object? selectedItems = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$SplitOrderStateImpl(
      cards: null == cards
          ? _value._cards
          : cards // ignore: cast_nullable_to_non_nullable
              as List<List<SaleItemModel>>,
      selectedItems: null == selectedItems
          ? _value._selectedItems
          : selectedItems // ignore: cast_nullable_to_non_nullable
              as Map<int, List<SaleItemModel>>,
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

class _$SplitOrderStateImpl implements _SplitOrderState {
  const _$SplitOrderStateImpl(
      {final List<List<SaleItemModel>> cards = const [[], []],
      final Map<int, List<SaleItemModel>> selectedItems = const {},
      this.error,
      this.isLoading = false})
      : _cards = cards,
        _selectedItems = selectedItems;

  final List<List<SaleItemModel>> _cards;
  @override
  @JsonKey()
  List<List<SaleItemModel>> get cards {
    if (_cards is EqualUnmodifiableListView) return _cards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cards);
  }

  final Map<int, List<SaleItemModel>> _selectedItems;
  @override
  @JsonKey()
  Map<int, List<SaleItemModel>> get selectedItems {
    if (_selectedItems is EqualUnmodifiableMapView) return _selectedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_selectedItems);
  }

  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'SplitOrderState(cards: $cards, selectedItems: $selectedItems, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SplitOrderStateImpl &&
            const DeepCollectionEquality().equals(other._cards, _cards) &&
            const DeepCollectionEquality()
                .equals(other._selectedItems, _selectedItems) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_cards),
      const DeepCollectionEquality().hash(_selectedItems),
      error,
      isLoading);

  /// Create a copy of SplitOrderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SplitOrderStateImplCopyWith<_$SplitOrderStateImpl> get copyWith =>
      __$$SplitOrderStateImplCopyWithImpl<_$SplitOrderStateImpl>(
          this, _$identity);
}

abstract class _SplitOrderState implements SplitOrderState {
  const factory _SplitOrderState(
      {final List<List<SaleItemModel>> cards,
      final Map<int, List<SaleItemModel>> selectedItems,
      final String? error,
      final bool isLoading}) = _$SplitOrderStateImpl;

  @override
  List<List<SaleItemModel>> get cards;
  @override
  Map<int, List<SaleItemModel>> get selectedItems;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of SplitOrderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SplitOrderStateImplCopyWith<_$SplitOrderStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
