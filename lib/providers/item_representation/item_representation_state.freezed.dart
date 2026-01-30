// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_representation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ItemRepresentationState {
  List<ItemRepresentationModel> get items => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of ItemRepresentationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemRepresentationStateCopyWith<ItemRepresentationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemRepresentationStateCopyWith<$Res> {
  factory $ItemRepresentationStateCopyWith(ItemRepresentationState value,
          $Res Function(ItemRepresentationState) then) =
      _$ItemRepresentationStateCopyWithImpl<$Res, ItemRepresentationState>;
  @useResult
  $Res call(
      {List<ItemRepresentationModel> items, bool isLoading, String? error});
}

/// @nodoc
class _$ItemRepresentationStateCopyWithImpl<$Res,
        $Val extends ItemRepresentationState>
    implements $ItemRepresentationStateCopyWith<$Res> {
  _$ItemRepresentationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemRepresentationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemRepresentationModel>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemRepresentationStateImplCopyWith<$Res>
    implements $ItemRepresentationStateCopyWith<$Res> {
  factory _$$ItemRepresentationStateImplCopyWith(
          _$ItemRepresentationStateImpl value,
          $Res Function(_$ItemRepresentationStateImpl) then) =
      __$$ItemRepresentationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ItemRepresentationModel> items, bool isLoading, String? error});
}

/// @nodoc
class __$$ItemRepresentationStateImplCopyWithImpl<$Res>
    extends _$ItemRepresentationStateCopyWithImpl<$Res,
        _$ItemRepresentationStateImpl>
    implements _$$ItemRepresentationStateImplCopyWith<$Res> {
  __$$ItemRepresentationStateImplCopyWithImpl(
      _$ItemRepresentationStateImpl _value,
      $Res Function(_$ItemRepresentationStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItemRepresentationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$ItemRepresentationStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemRepresentationModel>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ItemRepresentationStateImpl implements _ItemRepresentationState {
  const _$ItemRepresentationStateImpl(
      {final List<ItemRepresentationModel> items = const [],
      this.isLoading = false,
      this.error})
      : _items = items;

  final List<ItemRepresentationModel> _items;
  @override
  @JsonKey()
  List<ItemRepresentationModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'ItemRepresentationState(items: $items, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemRepresentationStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), isLoading, error);

  /// Create a copy of ItemRepresentationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemRepresentationStateImplCopyWith<_$ItemRepresentationStateImpl>
      get copyWith => __$$ItemRepresentationStateImplCopyWithImpl<
          _$ItemRepresentationStateImpl>(this, _$identity);
}

abstract class _ItemRepresentationState implements ItemRepresentationState {
  const factory _ItemRepresentationState(
      {final List<ItemRepresentationModel> items,
      final bool isLoading,
      final String? error}) = _$ItemRepresentationStateImpl;

  @override
  List<ItemRepresentationModel> get items;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of ItemRepresentationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemRepresentationStateImplCopyWith<_$ItemRepresentationStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
