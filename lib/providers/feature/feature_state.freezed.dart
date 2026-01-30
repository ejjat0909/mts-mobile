// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FeatureState {
  List<FeatureModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of FeatureState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeatureStateCopyWith<FeatureState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeatureStateCopyWith<$Res> {
  factory $FeatureStateCopyWith(
          FeatureState value, $Res Function(FeatureState) then) =
      _$FeatureStateCopyWithImpl<$Res, FeatureState>;
  @useResult
  $Res call({List<FeatureModel> items, String? error, bool isLoading});
}

/// @nodoc
class _$FeatureStateCopyWithImpl<$Res, $Val extends FeatureState>
    implements $FeatureStateCopyWith<$Res> {
  _$FeatureStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeatureState
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
              as List<FeatureModel>,
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
abstract class _$$FeatureStateImplCopyWith<$Res>
    implements $FeatureStateCopyWith<$Res> {
  factory _$$FeatureStateImplCopyWith(
          _$FeatureStateImpl value, $Res Function(_$FeatureStateImpl) then) =
      __$$FeatureStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<FeatureModel> items, String? error, bool isLoading});
}

/// @nodoc
class __$$FeatureStateImplCopyWithImpl<$Res>
    extends _$FeatureStateCopyWithImpl<$Res, _$FeatureStateImpl>
    implements _$$FeatureStateImplCopyWith<$Res> {
  __$$FeatureStateImplCopyWithImpl(
      _$FeatureStateImpl _value, $Res Function(_$FeatureStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of FeatureState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$FeatureStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<FeatureModel>,
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

class _$FeatureStateImpl implements _FeatureState {
  const _$FeatureStateImpl(
      {final List<FeatureModel> items = const [],
      this.error,
      this.isLoading = false})
      : _items = items;

  final List<FeatureModel> _items;
  @override
  @JsonKey()
  List<FeatureModel> get items {
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
    return 'FeatureState(items: $items, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeatureStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), error, isLoading);

  /// Create a copy of FeatureState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeatureStateImplCopyWith<_$FeatureStateImpl> get copyWith =>
      __$$FeatureStateImplCopyWithImpl<_$FeatureStateImpl>(this, _$identity);
}

abstract class _FeatureState implements FeatureState {
  const factory _FeatureState(
      {final List<FeatureModel> items,
      final String? error,
      final bool isLoading}) = _$FeatureStateImpl;

  @override
  List<FeatureModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of FeatureState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeatureStateImplCopyWith<_$FeatureStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
