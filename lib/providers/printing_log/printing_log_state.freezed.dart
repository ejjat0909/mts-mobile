// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'printing_log_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PrintingLogState {
  List<PrintingLogModel> get items => throw _privateConstructorUsedError;
  List<PrintingLogModel> get itemsFromHive =>
      throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of PrintingLogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrintingLogStateCopyWith<PrintingLogState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrintingLogStateCopyWith<$Res> {
  factory $PrintingLogStateCopyWith(
          PrintingLogState value, $Res Function(PrintingLogState) then) =
      _$PrintingLogStateCopyWithImpl<$Res, PrintingLogState>;
  @useResult
  $Res call(
      {List<PrintingLogModel> items,
      List<PrintingLogModel> itemsFromHive,
      String? error,
      bool isLoading});
}

/// @nodoc
class _$PrintingLogStateCopyWithImpl<$Res, $Val extends PrintingLogState>
    implements $PrintingLogStateCopyWith<$Res> {
  _$PrintingLogStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrintingLogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemsFromHive = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PrintingLogModel>,
      itemsFromHive: null == itemsFromHive
          ? _value.itemsFromHive
          : itemsFromHive // ignore: cast_nullable_to_non_nullable
              as List<PrintingLogModel>,
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
abstract class _$$PrintingLogStateImplCopyWith<$Res>
    implements $PrintingLogStateCopyWith<$Res> {
  factory _$$PrintingLogStateImplCopyWith(_$PrintingLogStateImpl value,
          $Res Function(_$PrintingLogStateImpl) then) =
      __$$PrintingLogStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<PrintingLogModel> items,
      List<PrintingLogModel> itemsFromHive,
      String? error,
      bool isLoading});
}

/// @nodoc
class __$$PrintingLogStateImplCopyWithImpl<$Res>
    extends _$PrintingLogStateCopyWithImpl<$Res, _$PrintingLogStateImpl>
    implements _$$PrintingLogStateImplCopyWith<$Res> {
  __$$PrintingLogStateImplCopyWithImpl(_$PrintingLogStateImpl _value,
      $Res Function(_$PrintingLogStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PrintingLogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemsFromHive = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$PrintingLogStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PrintingLogModel>,
      itemsFromHive: null == itemsFromHive
          ? _value._itemsFromHive
          : itemsFromHive // ignore: cast_nullable_to_non_nullable
              as List<PrintingLogModel>,
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

class _$PrintingLogStateImpl implements _PrintingLogState {
  const _$PrintingLogStateImpl(
      {final List<PrintingLogModel> items = const [],
      final List<PrintingLogModel> itemsFromHive = const [],
      this.error,
      this.isLoading = false})
      : _items = items,
        _itemsFromHive = itemsFromHive;

  final List<PrintingLogModel> _items;
  @override
  @JsonKey()
  List<PrintingLogModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<PrintingLogModel> _itemsFromHive;
  @override
  @JsonKey()
  List<PrintingLogModel> get itemsFromHive {
    if (_itemsFromHive is EqualUnmodifiableListView) return _itemsFromHive;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_itemsFromHive);
  }

  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'PrintingLogState(items: $items, itemsFromHive: $itemsFromHive, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrintingLogStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality()
                .equals(other._itemsFromHive, _itemsFromHive) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      const DeepCollectionEquality().hash(_itemsFromHive),
      error,
      isLoading);

  /// Create a copy of PrintingLogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrintingLogStateImplCopyWith<_$PrintingLogStateImpl> get copyWith =>
      __$$PrintingLogStateImplCopyWithImpl<_$PrintingLogStateImpl>(
          this, _$identity);
}

abstract class _PrintingLogState implements PrintingLogState {
  const factory _PrintingLogState(
      {final List<PrintingLogModel> items,
      final List<PrintingLogModel> itemsFromHive,
      final String? error,
      final bool isLoading}) = _$PrintingLogStateImpl;

  @override
  List<PrintingLogModel> get items;
  @override
  List<PrintingLogModel> get itemsFromHive;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of PrintingLogState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrintingLogStateImplCopyWith<_$PrintingLogStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
