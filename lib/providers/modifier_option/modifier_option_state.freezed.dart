// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modifier_option_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ModifierOptionState {
  List<ModifierOptionModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of ModifierOptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModifierOptionStateCopyWith<ModifierOptionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModifierOptionStateCopyWith<$Res> {
  factory $ModifierOptionStateCopyWith(
          ModifierOptionState value, $Res Function(ModifierOptionState) then) =
      _$ModifierOptionStateCopyWithImpl<$Res, ModifierOptionState>;
  @useResult
  $Res call({List<ModifierOptionModel> items, String? error, bool isLoading});
}

/// @nodoc
class _$ModifierOptionStateCopyWithImpl<$Res, $Val extends ModifierOptionState>
    implements $ModifierOptionStateCopyWith<$Res> {
  _$ModifierOptionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModifierOptionState
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
              as List<ModifierOptionModel>,
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
abstract class _$$ModifierOptionStateImplCopyWith<$Res>
    implements $ModifierOptionStateCopyWith<$Res> {
  factory _$$ModifierOptionStateImplCopyWith(_$ModifierOptionStateImpl value,
          $Res Function(_$ModifierOptionStateImpl) then) =
      __$$ModifierOptionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ModifierOptionModel> items, String? error, bool isLoading});
}

/// @nodoc
class __$$ModifierOptionStateImplCopyWithImpl<$Res>
    extends _$ModifierOptionStateCopyWithImpl<$Res, _$ModifierOptionStateImpl>
    implements _$$ModifierOptionStateImplCopyWith<$Res> {
  __$$ModifierOptionStateImplCopyWithImpl(_$ModifierOptionStateImpl _value,
      $Res Function(_$ModifierOptionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModifierOptionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$ModifierOptionStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ModifierOptionModel>,
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

class _$ModifierOptionStateImpl implements _ModifierOptionState {
  const _$ModifierOptionStateImpl(
      {final List<ModifierOptionModel> items = const [],
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<ModifierOptionModel> _items;
  @override
  @JsonKey()
  List<ModifierOptionModel> get items {
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
    return 'ModifierOptionState(items: $items, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModifierOptionStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), error, isLoading);

  /// Create a copy of ModifierOptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModifierOptionStateImplCopyWith<_$ModifierOptionStateImpl> get copyWith =>
      __$$ModifierOptionStateImplCopyWithImpl<_$ModifierOptionStateImpl>(
          this, _$identity);
}

abstract class _ModifierOptionState implements ModifierOptionState {
  const factory _ModifierOptionState(
      {final List<ModifierOptionModel> items,
      final String? error,
      final bool isLoading}) = _$ModifierOptionStateImpl;

  @override
  List<ModifierOptionModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of ModifierOptionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModifierOptionStateImplCopyWith<_$ModifierOptionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
