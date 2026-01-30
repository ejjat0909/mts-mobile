// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale_modifier_option_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SaleModifierOptionState {
  List<SaleModifierOptionModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of SaleModifierOptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaleModifierOptionStateCopyWith<SaleModifierOptionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaleModifierOptionStateCopyWith<$Res> {
  factory $SaleModifierOptionStateCopyWith(SaleModifierOptionState value,
          $Res Function(SaleModifierOptionState) then) =
      _$SaleModifierOptionStateCopyWithImpl<$Res, SaleModifierOptionState>;
  @useResult
  $Res call(
      {List<SaleModifierOptionModel> items, String? error, bool isLoading});
}

/// @nodoc
class _$SaleModifierOptionStateCopyWithImpl<$Res,
        $Val extends SaleModifierOptionState>
    implements $SaleModifierOptionStateCopyWith<$Res> {
  _$SaleModifierOptionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaleModifierOptionState
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
              as List<SaleModifierOptionModel>,
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
abstract class _$$SaleModifierOptionStateImplCopyWith<$Res>
    implements $SaleModifierOptionStateCopyWith<$Res> {
  factory _$$SaleModifierOptionStateImplCopyWith(
          _$SaleModifierOptionStateImpl value,
          $Res Function(_$SaleModifierOptionStateImpl) then) =
      __$$SaleModifierOptionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<SaleModifierOptionModel> items, String? error, bool isLoading});
}

/// @nodoc
class __$$SaleModifierOptionStateImplCopyWithImpl<$Res>
    extends _$SaleModifierOptionStateCopyWithImpl<$Res,
        _$SaleModifierOptionStateImpl>
    implements _$$SaleModifierOptionStateImplCopyWith<$Res> {
  __$$SaleModifierOptionStateImplCopyWithImpl(
      _$SaleModifierOptionStateImpl _value,
      $Res Function(_$SaleModifierOptionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SaleModifierOptionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$SaleModifierOptionStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SaleModifierOptionModel>,
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

class _$SaleModifierOptionStateImpl implements _SaleModifierOptionState {
  const _$SaleModifierOptionStateImpl(
      {final List<SaleModifierOptionModel> items = const [],
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<SaleModifierOptionModel> _items;
  @override
  @JsonKey()
  List<SaleModifierOptionModel> get items {
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
    return 'SaleModifierOptionState(items: $items, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaleModifierOptionStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), error, isLoading);

  /// Create a copy of SaleModifierOptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaleModifierOptionStateImplCopyWith<_$SaleModifierOptionStateImpl>
      get copyWith => __$$SaleModifierOptionStateImplCopyWithImpl<
          _$SaleModifierOptionStateImpl>(this, _$identity);
}

abstract class _SaleModifierOptionState implements SaleModifierOptionState {
  const factory _SaleModifierOptionState(
      {final List<SaleModifierOptionModel> items,
      final String? error,
      final bool isLoading}) = _$SaleModifierOptionStateImpl;

  @override
  List<SaleModifierOptionModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of SaleModifierOptionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaleModifierOptionStateImplCopyWith<_$SaleModifierOptionStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
