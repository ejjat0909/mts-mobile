// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ItemState {
  List<ItemModel> get items => throw _privateConstructorUsedError;
  List<ItemRepresentationModel> get itemRepresentations =>
      throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading =>
      throw _privateConstructorUsedError; // Old notifier UI state fields
  String get itemName => throw _privateConstructorUsedError;
  String get searchItemName => throw _privateConstructorUsedError;
  String get dialogueNavigation => throw _privateConstructorUsedError;
  VariantOptionModel? get tempVariantOptionModel =>
      throw _privateConstructorUsedError;
  List<VariantOptionModel> get listVariantOptions =>
      throw _privateConstructorUsedError; // Price pad dialogue state
  String? get tempPrice => throw _privateConstructorUsedError;
  String? get previousPrice => throw _privateConstructorUsedError;
  String? get selectedPrice =>
      throw _privateConstructorUsedError; // Qty pad dialogue state
  String? get tempQty => throw _privateConstructorUsedError;
  String? get previousQty => throw _privateConstructorUsedError;
  String? get selectedQty => throw _privateConstructorUsedError;

  /// Create a copy of ItemState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemStateCopyWith<ItemState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemStateCopyWith<$Res> {
  factory $ItemStateCopyWith(ItemState value, $Res Function(ItemState) then) =
      _$ItemStateCopyWithImpl<$Res, ItemState>;
  @useResult
  $Res call(
      {List<ItemModel> items,
      List<ItemRepresentationModel> itemRepresentations,
      String? error,
      bool isLoading,
      String itemName,
      String searchItemName,
      String dialogueNavigation,
      VariantOptionModel? tempVariantOptionModel,
      List<VariantOptionModel> listVariantOptions,
      String? tempPrice,
      String? previousPrice,
      String? selectedPrice,
      String? tempQty,
      String? previousQty,
      String? selectedQty});
}

/// @nodoc
class _$ItemStateCopyWithImpl<$Res, $Val extends ItemState>
    implements $ItemStateCopyWith<$Res> {
  _$ItemStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemRepresentations = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? itemName = null,
    Object? searchItemName = null,
    Object? dialogueNavigation = null,
    Object? tempVariantOptionModel = freezed,
    Object? listVariantOptions = null,
    Object? tempPrice = freezed,
    Object? previousPrice = freezed,
    Object? selectedPrice = freezed,
    Object? tempQty = freezed,
    Object? previousQty = freezed,
    Object? selectedQty = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemModel>,
      itemRepresentations: null == itemRepresentations
          ? _value.itemRepresentations
          : itemRepresentations // ignore: cast_nullable_to_non_nullable
              as List<ItemRepresentationModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      itemName: null == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      searchItemName: null == searchItemName
          ? _value.searchItemName
          : searchItemName // ignore: cast_nullable_to_non_nullable
              as String,
      dialogueNavigation: null == dialogueNavigation
          ? _value.dialogueNavigation
          : dialogueNavigation // ignore: cast_nullable_to_non_nullable
              as String,
      tempVariantOptionModel: freezed == tempVariantOptionModel
          ? _value.tempVariantOptionModel
          : tempVariantOptionModel // ignore: cast_nullable_to_non_nullable
              as VariantOptionModel?,
      listVariantOptions: null == listVariantOptions
          ? _value.listVariantOptions
          : listVariantOptions // ignore: cast_nullable_to_non_nullable
              as List<VariantOptionModel>,
      tempPrice: freezed == tempPrice
          ? _value.tempPrice
          : tempPrice // ignore: cast_nullable_to_non_nullable
              as String?,
      previousPrice: freezed == previousPrice
          ? _value.previousPrice
          : previousPrice // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedPrice: freezed == selectedPrice
          ? _value.selectedPrice
          : selectedPrice // ignore: cast_nullable_to_non_nullable
              as String?,
      tempQty: freezed == tempQty
          ? _value.tempQty
          : tempQty // ignore: cast_nullable_to_non_nullable
              as String?,
      previousQty: freezed == previousQty
          ? _value.previousQty
          : previousQty // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedQty: freezed == selectedQty
          ? _value.selectedQty
          : selectedQty // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemStateImplCopyWith<$Res>
    implements $ItemStateCopyWith<$Res> {
  factory _$$ItemStateImplCopyWith(
          _$ItemStateImpl value, $Res Function(_$ItemStateImpl) then) =
      __$$ItemStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ItemModel> items,
      List<ItemRepresentationModel> itemRepresentations,
      String? error,
      bool isLoading,
      String itemName,
      String searchItemName,
      String dialogueNavigation,
      VariantOptionModel? tempVariantOptionModel,
      List<VariantOptionModel> listVariantOptions,
      String? tempPrice,
      String? previousPrice,
      String? selectedPrice,
      String? tempQty,
      String? previousQty,
      String? selectedQty});
}

/// @nodoc
class __$$ItemStateImplCopyWithImpl<$Res>
    extends _$ItemStateCopyWithImpl<$Res, _$ItemStateImpl>
    implements _$$ItemStateImplCopyWith<$Res> {
  __$$ItemStateImplCopyWithImpl(
      _$ItemStateImpl _value, $Res Function(_$ItemStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItemState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemRepresentations = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? itemName = null,
    Object? searchItemName = null,
    Object? dialogueNavigation = null,
    Object? tempVariantOptionModel = freezed,
    Object? listVariantOptions = null,
    Object? tempPrice = freezed,
    Object? previousPrice = freezed,
    Object? selectedPrice = freezed,
    Object? tempQty = freezed,
    Object? previousQty = freezed,
    Object? selectedQty = freezed,
  }) {
    return _then(_$ItemStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemModel>,
      itemRepresentations: null == itemRepresentations
          ? _value._itemRepresentations
          : itemRepresentations // ignore: cast_nullable_to_non_nullable
              as List<ItemRepresentationModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      itemName: null == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      searchItemName: null == searchItemName
          ? _value.searchItemName
          : searchItemName // ignore: cast_nullable_to_non_nullable
              as String,
      dialogueNavigation: null == dialogueNavigation
          ? _value.dialogueNavigation
          : dialogueNavigation // ignore: cast_nullable_to_non_nullable
              as String,
      tempVariantOptionModel: freezed == tempVariantOptionModel
          ? _value.tempVariantOptionModel
          : tempVariantOptionModel // ignore: cast_nullable_to_non_nullable
              as VariantOptionModel?,
      listVariantOptions: null == listVariantOptions
          ? _value._listVariantOptions
          : listVariantOptions // ignore: cast_nullable_to_non_nullable
              as List<VariantOptionModel>,
      tempPrice: freezed == tempPrice
          ? _value.tempPrice
          : tempPrice // ignore: cast_nullable_to_non_nullable
              as String?,
      previousPrice: freezed == previousPrice
          ? _value.previousPrice
          : previousPrice // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedPrice: freezed == selectedPrice
          ? _value.selectedPrice
          : selectedPrice // ignore: cast_nullable_to_non_nullable
              as String?,
      tempQty: freezed == tempQty
          ? _value.tempQty
          : tempQty // ignore: cast_nullable_to_non_nullable
              as String?,
      previousQty: freezed == previousQty
          ? _value.previousQty
          : previousQty // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedQty: freezed == selectedQty
          ? _value.selectedQty
          : selectedQty // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ItemStateImpl implements _ItemState {
  const _$ItemStateImpl(
      {final List<ItemModel> items = const [],
      final List<ItemRepresentationModel> itemRepresentations = const [],
      this.error,
      this.isLoading = false,
      this.itemName = '',
      this.searchItemName = '',
      this.dialogueNavigation = 'MAIN',
      this.tempVariantOptionModel,
      final List<VariantOptionModel> listVariantOptions = const [],
      this.tempPrice,
      this.previousPrice,
      this.selectedPrice,
      this.tempQty,
      this.previousQty,
      this.selectedQty})
      : _items = items,
        _itemRepresentations = itemRepresentations,
        _listVariantOptions = listVariantOptions;

  final List<ItemModel> _items;
  @override
  @JsonKey()
  List<ItemModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<ItemRepresentationModel> _itemRepresentations;
  @override
  @JsonKey()
  List<ItemRepresentationModel> get itemRepresentations {
    if (_itemRepresentations is EqualUnmodifiableListView)
      return _itemRepresentations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_itemRepresentations);
  }

  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;
// Old notifier UI state fields
  @override
  @JsonKey()
  final String itemName;
  @override
  @JsonKey()
  final String searchItemName;
  @override
  @JsonKey()
  final String dialogueNavigation;
  @override
  final VariantOptionModel? tempVariantOptionModel;
  final List<VariantOptionModel> _listVariantOptions;
  @override
  @JsonKey()
  List<VariantOptionModel> get listVariantOptions {
    if (_listVariantOptions is EqualUnmodifiableListView)
      return _listVariantOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listVariantOptions);
  }

// Price pad dialogue state
  @override
  final String? tempPrice;
  @override
  final String? previousPrice;
  @override
  final String? selectedPrice;
// Qty pad dialogue state
  @override
  final String? tempQty;
  @override
  final String? previousQty;
  @override
  final String? selectedQty;

  @override
  String toString() {
    return 'ItemState(items: $items, itemRepresentations: $itemRepresentations, error: $error, isLoading: $isLoading, itemName: $itemName, searchItemName: $searchItemName, dialogueNavigation: $dialogueNavigation, tempVariantOptionModel: $tempVariantOptionModel, listVariantOptions: $listVariantOptions, tempPrice: $tempPrice, previousPrice: $previousPrice, selectedPrice: $selectedPrice, tempQty: $tempQty, previousQty: $previousQty, selectedQty: $selectedQty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality()
                .equals(other._itemRepresentations, _itemRepresentations) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.searchItemName, searchItemName) ||
                other.searchItemName == searchItemName) &&
            (identical(other.dialogueNavigation, dialogueNavigation) ||
                other.dialogueNavigation == dialogueNavigation) &&
            (identical(other.tempVariantOptionModel, tempVariantOptionModel) ||
                other.tempVariantOptionModel == tempVariantOptionModel) &&
            const DeepCollectionEquality()
                .equals(other._listVariantOptions, _listVariantOptions) &&
            (identical(other.tempPrice, tempPrice) ||
                other.tempPrice == tempPrice) &&
            (identical(other.previousPrice, previousPrice) ||
                other.previousPrice == previousPrice) &&
            (identical(other.selectedPrice, selectedPrice) ||
                other.selectedPrice == selectedPrice) &&
            (identical(other.tempQty, tempQty) || other.tempQty == tempQty) &&
            (identical(other.previousQty, previousQty) ||
                other.previousQty == previousQty) &&
            (identical(other.selectedQty, selectedQty) ||
                other.selectedQty == selectedQty));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      const DeepCollectionEquality().hash(_itemRepresentations),
      error,
      isLoading,
      itemName,
      searchItemName,
      dialogueNavigation,
      tempVariantOptionModel,
      const DeepCollectionEquality().hash(_listVariantOptions),
      tempPrice,
      previousPrice,
      selectedPrice,
      tempQty,
      previousQty,
      selectedQty);

  /// Create a copy of ItemState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemStateImplCopyWith<_$ItemStateImpl> get copyWith =>
      __$$ItemStateImplCopyWithImpl<_$ItemStateImpl>(this, _$identity);
}

abstract class _ItemState implements ItemState {
  const factory _ItemState(
      {final List<ItemModel> items,
      final List<ItemRepresentationModel> itemRepresentations,
      final String? error,
      final bool isLoading,
      final String itemName,
      final String searchItemName,
      final String dialogueNavigation,
      final VariantOptionModel? tempVariantOptionModel,
      final List<VariantOptionModel> listVariantOptions,
      final String? tempPrice,
      final String? previousPrice,
      final String? selectedPrice,
      final String? tempQty,
      final String? previousQty,
      final String? selectedQty}) = _$ItemStateImpl;

  @override
  List<ItemModel> get items;
  @override
  List<ItemRepresentationModel> get itemRepresentations;
  @override
  String? get error;
  @override
  bool get isLoading; // Old notifier UI state fields
  @override
  String get itemName;
  @override
  String get searchItemName;
  @override
  String get dialogueNavigation;
  @override
  VariantOptionModel? get tempVariantOptionModel;
  @override
  List<VariantOptionModel> get listVariantOptions; // Price pad dialogue state
  @override
  String? get tempPrice;
  @override
  String? get previousPrice;
  @override
  String? get selectedPrice; // Qty pad dialogue state
  @override
  String? get tempQty;
  @override
  String? get previousQty;
  @override
  String? get selectedQty;

  /// Create a copy of ItemState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemStateImplCopyWith<_$ItemStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
