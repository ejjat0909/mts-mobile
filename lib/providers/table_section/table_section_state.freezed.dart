// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table_section_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TableSectionState {
  List<TableSectionModel> get items => throw _privateConstructorUsedError;
  List<TableSectionModel> get itemsFromHive =>
      throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of TableSectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TableSectionStateCopyWith<TableSectionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TableSectionStateCopyWith<$Res> {
  factory $TableSectionStateCopyWith(
          TableSectionState value, $Res Function(TableSectionState) then) =
      _$TableSectionStateCopyWithImpl<$Res, TableSectionState>;
  @useResult
  $Res call(
      {List<TableSectionModel> items,
      List<TableSectionModel> itemsFromHive,
      String? error,
      bool isLoading});
}

/// @nodoc
class _$TableSectionStateCopyWithImpl<$Res, $Val extends TableSectionState>
    implements $TableSectionStateCopyWith<$Res> {
  _$TableSectionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TableSectionState
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
              as List<TableSectionModel>,
      itemsFromHive: null == itemsFromHive
          ? _value.itemsFromHive
          : itemsFromHive // ignore: cast_nullable_to_non_nullable
              as List<TableSectionModel>,
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
abstract class _$$TableSectionStateImplCopyWith<$Res>
    implements $TableSectionStateCopyWith<$Res> {
  factory _$$TableSectionStateImplCopyWith(_$TableSectionStateImpl value,
          $Res Function(_$TableSectionStateImpl) then) =
      __$$TableSectionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<TableSectionModel> items,
      List<TableSectionModel> itemsFromHive,
      String? error,
      bool isLoading});
}

/// @nodoc
class __$$TableSectionStateImplCopyWithImpl<$Res>
    extends _$TableSectionStateCopyWithImpl<$Res, _$TableSectionStateImpl>
    implements _$$TableSectionStateImplCopyWith<$Res> {
  __$$TableSectionStateImplCopyWithImpl(_$TableSectionStateImpl _value,
      $Res Function(_$TableSectionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TableSectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemsFromHive = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$TableSectionStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TableSectionModel>,
      itemsFromHive: null == itemsFromHive
          ? _value._itemsFromHive
          : itemsFromHive // ignore: cast_nullable_to_non_nullable
              as List<TableSectionModel>,
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

class _$TableSectionStateImpl implements _TableSectionState {
  const _$TableSectionStateImpl(
      {final List<TableSectionModel> items = const [],
      final List<TableSectionModel> itemsFromHive = const [],
      this.error,
      this.isLoading = false})
      : _items = items,
        _itemsFromHive = itemsFromHive;

  final List<TableSectionModel> _items;
  @override
  @JsonKey()
  List<TableSectionModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<TableSectionModel> _itemsFromHive;
  @override
  @JsonKey()
  List<TableSectionModel> get itemsFromHive {
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
    return 'TableSectionState(items: $items, itemsFromHive: $itemsFromHive, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TableSectionStateImpl &&
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

  /// Create a copy of TableSectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TableSectionStateImplCopyWith<_$TableSectionStateImpl> get copyWith =>
      __$$TableSectionStateImplCopyWithImpl<_$TableSectionStateImpl>(
          this, _$identity);
}

abstract class _TableSectionState implements TableSectionState {
  const factory _TableSectionState(
      {final List<TableSectionModel> items,
      final List<TableSectionModel> itemsFromHive,
      final String? error,
      final bool isLoading}) = _$TableSectionStateImpl;

  @override
  List<TableSectionModel> get items;
  @override
  List<TableSectionModel> get itemsFromHive;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of TableSectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TableSectionStateImplCopyWith<_$TableSectionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
