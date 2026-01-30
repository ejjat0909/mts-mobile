// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timecard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TimecardState {
  List<TimecardModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading =>
      throw _privateConstructorUsedError; // Old ChangeNotifier fields (UI state)
  TimecardModel? get currentTimecard => throw _privateConstructorUsedError;

  /// Create a copy of TimecardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimecardStateCopyWith<TimecardState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimecardStateCopyWith<$Res> {
  factory $TimecardStateCopyWith(
          TimecardState value, $Res Function(TimecardState) then) =
      _$TimecardStateCopyWithImpl<$Res, TimecardState>;
  @useResult
  $Res call(
      {List<TimecardModel> items,
      String? error,
      bool isLoading,
      TimecardModel? currentTimecard});
}

/// @nodoc
class _$TimecardStateCopyWithImpl<$Res, $Val extends TimecardState>
    implements $TimecardStateCopyWith<$Res> {
  _$TimecardStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimecardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? currentTimecard = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TimecardModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      currentTimecard: freezed == currentTimecard
          ? _value.currentTimecard
          : currentTimecard // ignore: cast_nullable_to_non_nullable
              as TimecardModel?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimecardStateImplCopyWith<$Res>
    implements $TimecardStateCopyWith<$Res> {
  factory _$$TimecardStateImplCopyWith(
          _$TimecardStateImpl value, $Res Function(_$TimecardStateImpl) then) =
      __$$TimecardStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<TimecardModel> items,
      String? error,
      bool isLoading,
      TimecardModel? currentTimecard});
}

/// @nodoc
class __$$TimecardStateImplCopyWithImpl<$Res>
    extends _$TimecardStateCopyWithImpl<$Res, _$TimecardStateImpl>
    implements _$$TimecardStateImplCopyWith<$Res> {
  __$$TimecardStateImplCopyWithImpl(
      _$TimecardStateImpl _value, $Res Function(_$TimecardStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TimecardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? currentTimecard = freezed,
  }) {
    return _then(_$TimecardStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TimecardModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      currentTimecard: freezed == currentTimecard
          ? _value.currentTimecard
          : currentTimecard // ignore: cast_nullable_to_non_nullable
              as TimecardModel?,
    ));
  }
}

/// @nodoc

class _$TimecardStateImpl implements _TimecardState {
  const _$TimecardStateImpl(
      {final List<TimecardModel> items = const [],
      this.error,
      this.isLoading = false,
      this.currentTimecard})
      : _items = items;

  final List<TimecardModel> _items;
  @override
  @JsonKey()
  List<TimecardModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;
// Old ChangeNotifier fields (UI state)
  @override
  final TimecardModel? currentTimecard;

  @override
  String toString() {
    return 'TimecardState(items: $items, error: $error, isLoading: $isLoading, currentTimecard: $currentTimecard)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimecardStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.currentTimecard, currentTimecard) ||
                other.currentTimecard == currentTimecard));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      error,
      isLoading,
      currentTimecard);

  /// Create a copy of TimecardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimecardStateImplCopyWith<_$TimecardStateImpl> get copyWith =>
      __$$TimecardStateImplCopyWithImpl<_$TimecardStateImpl>(this, _$identity);
}

abstract class _TimecardState implements TimecardState {
  const factory _TimecardState(
      {final List<TimecardModel> items,
      final String? error,
      final bool isLoading,
      final TimecardModel? currentTimecard}) = _$TimecardStateImpl;

  @override
  List<TimecardModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading; // Old ChangeNotifier fields (UI state)
  @override
  TimecardModel? get currentTimecard;

  /// Create a copy of TimecardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimecardStateImplCopyWith<_$TimecardStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
