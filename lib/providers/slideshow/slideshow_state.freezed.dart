// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'slideshow_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SlideshowState {
  List<SlideshowModel> get items => throw _privateConstructorUsedError;
  List<SlideshowModel> get itemsFromHive => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading =>
      throw _privateConstructorUsedError; // Old ChangeNotifier fields (UI state)
  SlideshowModel? get currentSlideshow => throw _privateConstructorUsedError;
  bool get isPlaying => throw _privateConstructorUsedError;
  int get currentSlideIndex => throw _privateConstructorUsedError;

  /// Create a copy of SlideshowState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SlideshowStateCopyWith<SlideshowState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SlideshowStateCopyWith<$Res> {
  factory $SlideshowStateCopyWith(
          SlideshowState value, $Res Function(SlideshowState) then) =
      _$SlideshowStateCopyWithImpl<$Res, SlideshowState>;
  @useResult
  $Res call(
      {List<SlideshowModel> items,
      List<SlideshowModel> itemsFromHive,
      String? error,
      bool isLoading,
      SlideshowModel? currentSlideshow,
      bool isPlaying,
      int currentSlideIndex});
}

/// @nodoc
class _$SlideshowStateCopyWithImpl<$Res, $Val extends SlideshowState>
    implements $SlideshowStateCopyWith<$Res> {
  _$SlideshowStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SlideshowState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemsFromHive = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? currentSlideshow = freezed,
    Object? isPlaying = null,
    Object? currentSlideIndex = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SlideshowModel>,
      itemsFromHive: null == itemsFromHive
          ? _value.itemsFromHive
          : itemsFromHive // ignore: cast_nullable_to_non_nullable
              as List<SlideshowModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      currentSlideshow: freezed == currentSlideshow
          ? _value.currentSlideshow
          : currentSlideshow // ignore: cast_nullable_to_non_nullable
              as SlideshowModel?,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      currentSlideIndex: null == currentSlideIndex
          ? _value.currentSlideIndex
          : currentSlideIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SlideshowStateImplCopyWith<$Res>
    implements $SlideshowStateCopyWith<$Res> {
  factory _$$SlideshowStateImplCopyWith(_$SlideshowStateImpl value,
          $Res Function(_$SlideshowStateImpl) then) =
      __$$SlideshowStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<SlideshowModel> items,
      List<SlideshowModel> itemsFromHive,
      String? error,
      bool isLoading,
      SlideshowModel? currentSlideshow,
      bool isPlaying,
      int currentSlideIndex});
}

/// @nodoc
class __$$SlideshowStateImplCopyWithImpl<$Res>
    extends _$SlideshowStateCopyWithImpl<$Res, _$SlideshowStateImpl>
    implements _$$SlideshowStateImplCopyWith<$Res> {
  __$$SlideshowStateImplCopyWithImpl(
      _$SlideshowStateImpl _value, $Res Function(_$SlideshowStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SlideshowState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemsFromHive = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? currentSlideshow = freezed,
    Object? isPlaying = null,
    Object? currentSlideIndex = null,
  }) {
    return _then(_$SlideshowStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SlideshowModel>,
      itemsFromHive: null == itemsFromHive
          ? _value._itemsFromHive
          : itemsFromHive // ignore: cast_nullable_to_non_nullable
              as List<SlideshowModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      currentSlideshow: freezed == currentSlideshow
          ? _value.currentSlideshow
          : currentSlideshow // ignore: cast_nullable_to_non_nullable
              as SlideshowModel?,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      currentSlideIndex: null == currentSlideIndex
          ? _value.currentSlideIndex
          : currentSlideIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$SlideshowStateImpl implements _SlideshowState {
  const _$SlideshowStateImpl(
      {final List<SlideshowModel> items = const [],
      final List<SlideshowModel> itemsFromHive = const [],
      this.error,
      this.isLoading = false,
      this.currentSlideshow,
      this.isPlaying = false,
      this.currentSlideIndex = 0})
      : _items = items,
        _itemsFromHive = itemsFromHive;

  final List<SlideshowModel> _items;
  @override
  @JsonKey()
  List<SlideshowModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<SlideshowModel> _itemsFromHive;
  @override
  @JsonKey()
  List<SlideshowModel> get itemsFromHive {
    if (_itemsFromHive is EqualUnmodifiableListView) return _itemsFromHive;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_itemsFromHive);
  }

  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;
// Old ChangeNotifier fields (UI state)
  @override
  final SlideshowModel? currentSlideshow;
  @override
  @JsonKey()
  final bool isPlaying;
  @override
  @JsonKey()
  final int currentSlideIndex;

  @override
  String toString() {
    return 'SlideshowState(items: $items, itemsFromHive: $itemsFromHive, error: $error, isLoading: $isLoading, currentSlideshow: $currentSlideshow, isPlaying: $isPlaying, currentSlideIndex: $currentSlideIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlideshowStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality()
                .equals(other._itemsFromHive, _itemsFromHive) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.currentSlideshow, currentSlideshow) ||
                other.currentSlideshow == currentSlideshow) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.currentSlideIndex, currentSlideIndex) ||
                other.currentSlideIndex == currentSlideIndex));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      const DeepCollectionEquality().hash(_itemsFromHive),
      error,
      isLoading,
      currentSlideshow,
      isPlaying,
      currentSlideIndex);

  /// Create a copy of SlideshowState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SlideshowStateImplCopyWith<_$SlideshowStateImpl> get copyWith =>
      __$$SlideshowStateImplCopyWithImpl<_$SlideshowStateImpl>(
          this, _$identity);
}

abstract class _SlideshowState implements SlideshowState {
  const factory _SlideshowState(
      {final List<SlideshowModel> items,
      final List<SlideshowModel> itemsFromHive,
      final String? error,
      final bool isLoading,
      final SlideshowModel? currentSlideshow,
      final bool isPlaying,
      final int currentSlideIndex}) = _$SlideshowStateImpl;

  @override
  List<SlideshowModel> get items;
  @override
  List<SlideshowModel> get itemsFromHive;
  @override
  String? get error;
  @override
  bool get isLoading; // Old ChangeNotifier fields (UI state)
  @override
  SlideshowModel? get currentSlideshow;
  @override
  bool get isPlaying;
  @override
  int get currentSlideIndex;

  /// Create a copy of SlideshowState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SlideshowStateImplCopyWith<_$SlideshowStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
