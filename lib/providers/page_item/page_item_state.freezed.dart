// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_item_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PageItemState {
  List<PageItemModel> get items => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading =>
      throw _privateConstructorUsedError; // Old ChangeNotifier fields (UI state)
  String get type => throw _privateConstructorUsedError;
  String? get lastPageId => throw _privateConstructorUsedError;
  String? get currentPageId => throw _privateConstructorUsedError;

  /// Create a copy of PageItemState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PageItemStateCopyWith<PageItemState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PageItemStateCopyWith<$Res> {
  factory $PageItemStateCopyWith(
          PageItemState value, $Res Function(PageItemState) then) =
      _$PageItemStateCopyWithImpl<$Res, PageItemState>;
  @useResult
  $Res call(
      {List<PageItemModel> items,
      String? error,
      bool isLoading,
      String type,
      String? lastPageId,
      String? currentPageId});
}

/// @nodoc
class _$PageItemStateCopyWithImpl<$Res, $Val extends PageItemState>
    implements $PageItemStateCopyWith<$Res> {
  _$PageItemStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PageItemState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? type = null,
    Object? lastPageId = freezed,
    Object? currentPageId = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PageItemModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      lastPageId: freezed == lastPageId
          ? _value.lastPageId
          : lastPageId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentPageId: freezed == currentPageId
          ? _value.currentPageId
          : currentPageId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PageItemStateImplCopyWith<$Res>
    implements $PageItemStateCopyWith<$Res> {
  factory _$$PageItemStateImplCopyWith(
          _$PageItemStateImpl value, $Res Function(_$PageItemStateImpl) then) =
      __$$PageItemStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<PageItemModel> items,
      String? error,
      bool isLoading,
      String type,
      String? lastPageId,
      String? currentPageId});
}

/// @nodoc
class __$$PageItemStateImplCopyWithImpl<$Res>
    extends _$PageItemStateCopyWithImpl<$Res, _$PageItemStateImpl>
    implements _$$PageItemStateImplCopyWith<$Res> {
  __$$PageItemStateImplCopyWithImpl(
      _$PageItemStateImpl _value, $Res Function(_$PageItemStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PageItemState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? type = null,
    Object? lastPageId = freezed,
    Object? currentPageId = freezed,
  }) {
    return _then(_$PageItemStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PageItemModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      lastPageId: freezed == lastPageId
          ? _value.lastPageId
          : lastPageId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentPageId: freezed == currentPageId
          ? _value.currentPageId
          : currentPageId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PageItemStateImpl implements _PageItemState {
  const _$PageItemStateImpl(
      {final List<PageItemModel> items = const [],
      this.error,
      this.isLoading = false,
      this.type = '',
      this.lastPageId,
      this.currentPageId})
      : _items = items;

  final List<PageItemModel> _items;
  @override
  @JsonKey()
  List<PageItemModel> get items {
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
  @JsonKey()
  final String type;
  @override
  final String? lastPageId;
  @override
  final String? currentPageId;

  @override
  String toString() {
    return 'PageItemState(items: $items, error: $error, isLoading: $isLoading, type: $type, lastPageId: $lastPageId, currentPageId: $currentPageId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PageItemStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.lastPageId, lastPageId) ||
                other.lastPageId == lastPageId) &&
            (identical(other.currentPageId, currentPageId) ||
                other.currentPageId == currentPageId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      error,
      isLoading,
      type,
      lastPageId,
      currentPageId);

  /// Create a copy of PageItemState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PageItemStateImplCopyWith<_$PageItemStateImpl> get copyWith =>
      __$$PageItemStateImplCopyWithImpl<_$PageItemStateImpl>(this, _$identity);
}

abstract class _PageItemState implements PageItemState {
  const factory _PageItemState(
      {final List<PageItemModel> items,
      final String? error,
      final bool isLoading,
      final String type,
      final String? lastPageId,
      final String? currentPageId}) = _$PageItemStateImpl;

  @override
  List<PageItemModel> get items;
  @override
  String? get error;
  @override
  bool get isLoading; // Old ChangeNotifier fields (UI state)
  @override
  String get type;
  @override
  String? get lastPageId;
  @override
  String? get currentPageId;

  /// Create a copy of PageItemState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PageItemStateImplCopyWith<_$PageItemStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
