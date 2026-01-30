// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_changes_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PendingChangesState {
  List<PendingChangesModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isSyncing => throw _privateConstructorUsedError;

  /// Create a copy of PendingChangesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PendingChangesStateCopyWith<PendingChangesState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PendingChangesStateCopyWith<$Res> {
  factory $PendingChangesStateCopyWith(
          PendingChangesState value, $Res Function(PendingChangesState) then) =
      _$PendingChangesStateCopyWithImpl<$Res, PendingChangesState>;
  @useResult
  $Res call(
      {List<PendingChangesModel> items,
      String? error,
      bool isLoading,
      bool isSyncing});
}

/// @nodoc
class _$PendingChangesStateCopyWithImpl<$Res, $Val extends PendingChangesState>
    implements $PendingChangesStateCopyWith<$Res> {
  _$PendingChangesStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PendingChangesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? isSyncing = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PendingChangesModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSyncing: null == isSyncing
          ? _value.isSyncing
          : isSyncing // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PendingChangesStateImplCopyWith<$Res>
    implements $PendingChangesStateCopyWith<$Res> {
  factory _$$PendingChangesStateImplCopyWith(_$PendingChangesStateImpl value,
          $Res Function(_$PendingChangesStateImpl) then) =
      __$$PendingChangesStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<PendingChangesModel> items,
      String? error,
      bool isLoading,
      bool isSyncing});
}

/// @nodoc
class __$$PendingChangesStateImplCopyWithImpl<$Res>
    extends _$PendingChangesStateCopyWithImpl<$Res, _$PendingChangesStateImpl>
    implements _$$PendingChangesStateImplCopyWith<$Res> {
  __$$PendingChangesStateImplCopyWithImpl(_$PendingChangesStateImpl _value,
      $Res Function(_$PendingChangesStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PendingChangesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? isSyncing = null,
  }) {
    return _then(_$PendingChangesStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PendingChangesModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSyncing: null == isSyncing
          ? _value.isSyncing
          : isSyncing // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PendingChangesStateImpl implements _PendingChangesState {
  const _$PendingChangesStateImpl(
      {final List<PendingChangesModel> items = const [],
      this.error,
      this.isLoading = false,
      this.isSyncing = false})
      : _items = items;

  final List<PendingChangesModel> _items;
  @override
  @JsonKey()
  List<PendingChangesModel> get items {
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
  @JsonKey()
  final bool isSyncing;

  @override
  String toString() {
    return 'PendingChangesState(items: $items, error: $error, isLoading: $isLoading, isSyncing: $isSyncing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PendingChangesStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isSyncing, isSyncing) ||
                other.isSyncing == isSyncing));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), error, isLoading, isSyncing);

  /// Create a copy of PendingChangesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PendingChangesStateImplCopyWith<_$PendingChangesStateImpl> get copyWith =>
      __$$PendingChangesStateImplCopyWithImpl<_$PendingChangesStateImpl>(
          this, _$identity);
}

abstract class _PendingChangesState implements PendingChangesState {
  const factory _PendingChangesState(
      {final List<PendingChangesModel> items,
      final String? error,
      final bool isLoading,
      final bool isSyncing}) = _$PendingChangesStateImpl;

  @override
  List<PendingChangesModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading;
  @override
  bool get isSyncing;

  /// Create a copy of PendingChangesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PendingChangesStateImplCopyWith<_$PendingChangesStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
