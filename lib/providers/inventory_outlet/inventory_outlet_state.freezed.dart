// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_outlet_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$InventoryOutletState {
  List<InventoryOutletModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of InventoryOutletState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InventoryOutletStateCopyWith<InventoryOutletState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InventoryOutletStateCopyWith<$Res> {
  factory $InventoryOutletStateCopyWith(InventoryOutletState value,
          $Res Function(InventoryOutletState) then) =
      _$InventoryOutletStateCopyWithImpl<$Res, InventoryOutletState>;
  @useResult
  $Res call({List<InventoryOutletModel> items, String? error, bool isLoading});
}

/// @nodoc
class _$InventoryOutletStateCopyWithImpl<$Res,
        $Val extends InventoryOutletState>
    implements $InventoryOutletStateCopyWith<$Res> {
  _$InventoryOutletStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InventoryOutletState
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
              as List<InventoryOutletModel>,
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
abstract class _$$InventoryOutletStateImplCopyWith<$Res>
    implements $InventoryOutletStateCopyWith<$Res> {
  factory _$$InventoryOutletStateImplCopyWith(_$InventoryOutletStateImpl value,
          $Res Function(_$InventoryOutletStateImpl) then) =
      __$$InventoryOutletStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<InventoryOutletModel> items, String? error, bool isLoading});
}

/// @nodoc
class __$$InventoryOutletStateImplCopyWithImpl<$Res>
    extends _$InventoryOutletStateCopyWithImpl<$Res, _$InventoryOutletStateImpl>
    implements _$$InventoryOutletStateImplCopyWith<$Res> {
  __$$InventoryOutletStateImplCopyWithImpl(_$InventoryOutletStateImpl _value,
      $Res Function(_$InventoryOutletStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of InventoryOutletState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$InventoryOutletStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<InventoryOutletModel>,
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

class _$InventoryOutletStateImpl implements _InventoryOutletState {
  const _$InventoryOutletStateImpl(
      {final List<InventoryOutletModel> items = const [],
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<InventoryOutletModel> _items;
  @override
  @JsonKey()
  List<InventoryOutletModel> get items {
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
    return 'InventoryOutletState(items: $items, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InventoryOutletStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), error, isLoading);

  /// Create a copy of InventoryOutletState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InventoryOutletStateImplCopyWith<_$InventoryOutletStateImpl>
      get copyWith =>
          __$$InventoryOutletStateImplCopyWithImpl<_$InventoryOutletStateImpl>(
              this, _$identity);
}

abstract class _InventoryOutletState implements InventoryOutletState {
  const factory _InventoryOutletState(
      {final List<InventoryOutletModel> items,
      final String? error,
      final bool isLoading}) = _$InventoryOutletStateImpl;

  @override
  List<InventoryOutletModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of InventoryOutletState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InventoryOutletStateImplCopyWith<_$InventoryOutletStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
