// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ReceiptState {
  List<ReceiptModel> get items => throw _privateConstructorUsedError;
  List<ReceiptModel> get itemsFromHive => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading =>
      throw _privateConstructorUsedError; // Old notifier UI state fields
  List<ReceiptItemModel> get incomingRefundReceiptItems =>
      throw _privateConstructorUsedError;
  List<ReceiptItemModel> get receiptItemsForRefund =>
      throw _privateConstructorUsedError;
  List<ReceiptItemModel> get initialListReceiptItems =>
      throw _privateConstructorUsedError;
  List<ReceiptModel> get listReceiptModel => throw _privateConstructorUsedError;
  String? get receiptIdTitle => throw _privateConstructorUsedError;
  int get pageIndex => throw _privateConstructorUsedError;
  String get tempReceiptId => throw _privateConstructorUsedError;
  ReceiptModel? get tempReceiptModel =>
      throw _privateConstructorUsedError; // Calculation lists and totals
  List<Map<String, dynamic>> get listTotalDiscount =>
      throw _privateConstructorUsedError;
  double get totalDiscount => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTaxAfterDiscount =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTaxIncludedAfterDiscount =>
      throw _privateConstructorUsedError;
  double get taxAfterDiscount => throw _privateConstructorUsedError;
  double get taxIncludedAfterDiscount => throw _privateConstructorUsedError;
  double get totalAfterDiscountAndTax => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTotalAfterDiscAndTax =>
      throw _privateConstructorUsedError; // Pagination
  PagingController<int, ReceiptModel>? get listReceiptPagingController =>
      throw _privateConstructorUsedError;
  int? get selectedReceiptIndex => throw _privateConstructorUsedError;
  int get receiptDialogueNavigator =>
      throw _privateConstructorUsedError; // Filter state
  DateTimeRange? get selectedDateRange => throw _privateConstructorUsedError;
  DateTimeRange? get lastSelectedDateRange =>
      throw _privateConstructorUsedError;
  String get formattedDateRange =>
      throw _privateConstructorUsedError; // Payment type filter
  String? get tempPaymentType => throw _privateConstructorUsedError;
  String? get previousPaymentType => throw _privateConstructorUsedError;
  String? get selectedPaymentType => throw _privateConstructorUsedError;
  int get tempPaymentTypeIndex => throw _privateConstructorUsedError;
  int get previousPaymentTypeIndex => throw _privateConstructorUsedError;
  int get selectedPaymentTypeIndex =>
      throw _privateConstructorUsedError; // Order option filter
  String? get tempOrderOption => throw _privateConstructorUsedError;
  String? get previousOrderOption => throw _privateConstructorUsedError;
  String? get selectedOrderOption => throw _privateConstructorUsedError;
  int get tempOrderOptionIndex => throw _privateConstructorUsedError;
  int get previousOrderOptionIndex => throw _privateConstructorUsedError;
  int get selectedOrderOptionIndex => throw _privateConstructorUsedError;

  /// Create a copy of ReceiptState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReceiptStateCopyWith<ReceiptState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiptStateCopyWith<$Res> {
  factory $ReceiptStateCopyWith(
          ReceiptState value, $Res Function(ReceiptState) then) =
      _$ReceiptStateCopyWithImpl<$Res, ReceiptState>;
  @useResult
  $Res call(
      {List<ReceiptModel> items,
      List<ReceiptModel> itemsFromHive,
      String? error,
      bool isLoading,
      List<ReceiptItemModel> incomingRefundReceiptItems,
      List<ReceiptItemModel> receiptItemsForRefund,
      List<ReceiptItemModel> initialListReceiptItems,
      List<ReceiptModel> listReceiptModel,
      String? receiptIdTitle,
      int pageIndex,
      String tempReceiptId,
      ReceiptModel? tempReceiptModel,
      List<Map<String, dynamic>> listTotalDiscount,
      double totalDiscount,
      List<Map<String, dynamic>> listTaxAfterDiscount,
      List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
      double taxAfterDiscount,
      double taxIncludedAfterDiscount,
      double totalAfterDiscountAndTax,
      List<Map<String, dynamic>> listTotalAfterDiscAndTax,
      PagingController<int, ReceiptModel>? listReceiptPagingController,
      int? selectedReceiptIndex,
      int receiptDialogueNavigator,
      DateTimeRange? selectedDateRange,
      DateTimeRange? lastSelectedDateRange,
      String formattedDateRange,
      String? tempPaymentType,
      String? previousPaymentType,
      String? selectedPaymentType,
      int tempPaymentTypeIndex,
      int previousPaymentTypeIndex,
      int selectedPaymentTypeIndex,
      String? tempOrderOption,
      String? previousOrderOption,
      String? selectedOrderOption,
      int tempOrderOptionIndex,
      int previousOrderOptionIndex,
      int selectedOrderOptionIndex});
}

/// @nodoc
class _$ReceiptStateCopyWithImpl<$Res, $Val extends ReceiptState>
    implements $ReceiptStateCopyWith<$Res> {
  _$ReceiptStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReceiptState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemsFromHive = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? incomingRefundReceiptItems = null,
    Object? receiptItemsForRefund = null,
    Object? initialListReceiptItems = null,
    Object? listReceiptModel = null,
    Object? receiptIdTitle = freezed,
    Object? pageIndex = null,
    Object? tempReceiptId = null,
    Object? tempReceiptModel = freezed,
    Object? listTotalDiscount = null,
    Object? totalDiscount = null,
    Object? listTaxAfterDiscount = null,
    Object? listTaxIncludedAfterDiscount = null,
    Object? taxAfterDiscount = null,
    Object? taxIncludedAfterDiscount = null,
    Object? totalAfterDiscountAndTax = null,
    Object? listTotalAfterDiscAndTax = null,
    Object? listReceiptPagingController = freezed,
    Object? selectedReceiptIndex = freezed,
    Object? receiptDialogueNavigator = null,
    Object? selectedDateRange = freezed,
    Object? lastSelectedDateRange = freezed,
    Object? formattedDateRange = null,
    Object? tempPaymentType = freezed,
    Object? previousPaymentType = freezed,
    Object? selectedPaymentType = freezed,
    Object? tempPaymentTypeIndex = null,
    Object? previousPaymentTypeIndex = null,
    Object? selectedPaymentTypeIndex = null,
    Object? tempOrderOption = freezed,
    Object? previousOrderOption = freezed,
    Object? selectedOrderOption = freezed,
    Object? tempOrderOptionIndex = null,
    Object? previousOrderOptionIndex = null,
    Object? selectedOrderOptionIndex = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ReceiptModel>,
      itemsFromHive: null == itemsFromHive
          ? _value.itemsFromHive
          : itemsFromHive // ignore: cast_nullable_to_non_nullable
              as List<ReceiptModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      incomingRefundReceiptItems: null == incomingRefundReceiptItems
          ? _value.incomingRefundReceiptItems
          : incomingRefundReceiptItems // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
      receiptItemsForRefund: null == receiptItemsForRefund
          ? _value.receiptItemsForRefund
          : receiptItemsForRefund // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
      initialListReceiptItems: null == initialListReceiptItems
          ? _value.initialListReceiptItems
          : initialListReceiptItems // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
      listReceiptModel: null == listReceiptModel
          ? _value.listReceiptModel
          : listReceiptModel // ignore: cast_nullable_to_non_nullable
              as List<ReceiptModel>,
      receiptIdTitle: freezed == receiptIdTitle
          ? _value.receiptIdTitle
          : receiptIdTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      pageIndex: null == pageIndex
          ? _value.pageIndex
          : pageIndex // ignore: cast_nullable_to_non_nullable
              as int,
      tempReceiptId: null == tempReceiptId
          ? _value.tempReceiptId
          : tempReceiptId // ignore: cast_nullable_to_non_nullable
              as String,
      tempReceiptModel: freezed == tempReceiptModel
          ? _value.tempReceiptModel
          : tempReceiptModel // ignore: cast_nullable_to_non_nullable
              as ReceiptModel?,
      listTotalDiscount: null == listTotalDiscount
          ? _value.listTotalDiscount
          : listTotalDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      totalDiscount: null == totalDiscount
          ? _value.totalDiscount
          : totalDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      listTaxAfterDiscount: null == listTaxAfterDiscount
          ? _value.listTaxAfterDiscount
          : listTaxAfterDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTaxIncludedAfterDiscount: null == listTaxIncludedAfterDiscount
          ? _value.listTaxIncludedAfterDiscount
          : listTaxIncludedAfterDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      taxAfterDiscount: null == taxAfterDiscount
          ? _value.taxAfterDiscount
          : taxAfterDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      taxIncludedAfterDiscount: null == taxIncludedAfterDiscount
          ? _value.taxIncludedAfterDiscount
          : taxIncludedAfterDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      totalAfterDiscountAndTax: null == totalAfterDiscountAndTax
          ? _value.totalAfterDiscountAndTax
          : totalAfterDiscountAndTax // ignore: cast_nullable_to_non_nullable
              as double,
      listTotalAfterDiscAndTax: null == listTotalAfterDiscAndTax
          ? _value.listTotalAfterDiscAndTax
          : listTotalAfterDiscAndTax // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listReceiptPagingController: freezed == listReceiptPagingController
          ? _value.listReceiptPagingController
          : listReceiptPagingController // ignore: cast_nullable_to_non_nullable
              as PagingController<int, ReceiptModel>?,
      selectedReceiptIndex: freezed == selectedReceiptIndex
          ? _value.selectedReceiptIndex
          : selectedReceiptIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      receiptDialogueNavigator: null == receiptDialogueNavigator
          ? _value.receiptDialogueNavigator
          : receiptDialogueNavigator // ignore: cast_nullable_to_non_nullable
              as int,
      selectedDateRange: freezed == selectedDateRange
          ? _value.selectedDateRange
          : selectedDateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      lastSelectedDateRange: freezed == lastSelectedDateRange
          ? _value.lastSelectedDateRange
          : lastSelectedDateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      formattedDateRange: null == formattedDateRange
          ? _value.formattedDateRange
          : formattedDateRange // ignore: cast_nullable_to_non_nullable
              as String,
      tempPaymentType: freezed == tempPaymentType
          ? _value.tempPaymentType
          : tempPaymentType // ignore: cast_nullable_to_non_nullable
              as String?,
      previousPaymentType: freezed == previousPaymentType
          ? _value.previousPaymentType
          : previousPaymentType // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedPaymentType: freezed == selectedPaymentType
          ? _value.selectedPaymentType
          : selectedPaymentType // ignore: cast_nullable_to_non_nullable
              as String?,
      tempPaymentTypeIndex: null == tempPaymentTypeIndex
          ? _value.tempPaymentTypeIndex
          : tempPaymentTypeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      previousPaymentTypeIndex: null == previousPaymentTypeIndex
          ? _value.previousPaymentTypeIndex
          : previousPaymentTypeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      selectedPaymentTypeIndex: null == selectedPaymentTypeIndex
          ? _value.selectedPaymentTypeIndex
          : selectedPaymentTypeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      tempOrderOption: freezed == tempOrderOption
          ? _value.tempOrderOption
          : tempOrderOption // ignore: cast_nullable_to_non_nullable
              as String?,
      previousOrderOption: freezed == previousOrderOption
          ? _value.previousOrderOption
          : previousOrderOption // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedOrderOption: freezed == selectedOrderOption
          ? _value.selectedOrderOption
          : selectedOrderOption // ignore: cast_nullable_to_non_nullable
              as String?,
      tempOrderOptionIndex: null == tempOrderOptionIndex
          ? _value.tempOrderOptionIndex
          : tempOrderOptionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      previousOrderOptionIndex: null == previousOrderOptionIndex
          ? _value.previousOrderOptionIndex
          : previousOrderOptionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      selectedOrderOptionIndex: null == selectedOrderOptionIndex
          ? _value.selectedOrderOptionIndex
          : selectedOrderOptionIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReceiptStateImplCopyWith<$Res>
    implements $ReceiptStateCopyWith<$Res> {
  factory _$$ReceiptStateImplCopyWith(
          _$ReceiptStateImpl value, $Res Function(_$ReceiptStateImpl) then) =
      __$$ReceiptStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ReceiptModel> items,
      List<ReceiptModel> itemsFromHive,
      String? error,
      bool isLoading,
      List<ReceiptItemModel> incomingRefundReceiptItems,
      List<ReceiptItemModel> receiptItemsForRefund,
      List<ReceiptItemModel> initialListReceiptItems,
      List<ReceiptModel> listReceiptModel,
      String? receiptIdTitle,
      int pageIndex,
      String tempReceiptId,
      ReceiptModel? tempReceiptModel,
      List<Map<String, dynamic>> listTotalDiscount,
      double totalDiscount,
      List<Map<String, dynamic>> listTaxAfterDiscount,
      List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
      double taxAfterDiscount,
      double taxIncludedAfterDiscount,
      double totalAfterDiscountAndTax,
      List<Map<String, dynamic>> listTotalAfterDiscAndTax,
      PagingController<int, ReceiptModel>? listReceiptPagingController,
      int? selectedReceiptIndex,
      int receiptDialogueNavigator,
      DateTimeRange? selectedDateRange,
      DateTimeRange? lastSelectedDateRange,
      String formattedDateRange,
      String? tempPaymentType,
      String? previousPaymentType,
      String? selectedPaymentType,
      int tempPaymentTypeIndex,
      int previousPaymentTypeIndex,
      int selectedPaymentTypeIndex,
      String? tempOrderOption,
      String? previousOrderOption,
      String? selectedOrderOption,
      int tempOrderOptionIndex,
      int previousOrderOptionIndex,
      int selectedOrderOptionIndex});
}

/// @nodoc
class __$$ReceiptStateImplCopyWithImpl<$Res>
    extends _$ReceiptStateCopyWithImpl<$Res, _$ReceiptStateImpl>
    implements _$$ReceiptStateImplCopyWith<$Res> {
  __$$ReceiptStateImplCopyWithImpl(
      _$ReceiptStateImpl _value, $Res Function(_$ReceiptStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReceiptState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? itemsFromHive = null,
    Object? error = freezed,
    Object? isLoading = null,
    Object? incomingRefundReceiptItems = null,
    Object? receiptItemsForRefund = null,
    Object? initialListReceiptItems = null,
    Object? listReceiptModel = null,
    Object? receiptIdTitle = freezed,
    Object? pageIndex = null,
    Object? tempReceiptId = null,
    Object? tempReceiptModel = freezed,
    Object? listTotalDiscount = null,
    Object? totalDiscount = null,
    Object? listTaxAfterDiscount = null,
    Object? listTaxIncludedAfterDiscount = null,
    Object? taxAfterDiscount = null,
    Object? taxIncludedAfterDiscount = null,
    Object? totalAfterDiscountAndTax = null,
    Object? listTotalAfterDiscAndTax = null,
    Object? listReceiptPagingController = freezed,
    Object? selectedReceiptIndex = freezed,
    Object? receiptDialogueNavigator = null,
    Object? selectedDateRange = freezed,
    Object? lastSelectedDateRange = freezed,
    Object? formattedDateRange = null,
    Object? tempPaymentType = freezed,
    Object? previousPaymentType = freezed,
    Object? selectedPaymentType = freezed,
    Object? tempPaymentTypeIndex = null,
    Object? previousPaymentTypeIndex = null,
    Object? selectedPaymentTypeIndex = null,
    Object? tempOrderOption = freezed,
    Object? previousOrderOption = freezed,
    Object? selectedOrderOption = freezed,
    Object? tempOrderOptionIndex = null,
    Object? previousOrderOptionIndex = null,
    Object? selectedOrderOptionIndex = null,
  }) {
    return _then(_$ReceiptStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ReceiptModel>,
      itemsFromHive: null == itemsFromHive
          ? _value._itemsFromHive
          : itemsFromHive // ignore: cast_nullable_to_non_nullable
              as List<ReceiptModel>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      incomingRefundReceiptItems: null == incomingRefundReceiptItems
          ? _value._incomingRefundReceiptItems
          : incomingRefundReceiptItems // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
      receiptItemsForRefund: null == receiptItemsForRefund
          ? _value._receiptItemsForRefund
          : receiptItemsForRefund // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
      initialListReceiptItems: null == initialListReceiptItems
          ? _value._initialListReceiptItems
          : initialListReceiptItems // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
      listReceiptModel: null == listReceiptModel
          ? _value._listReceiptModel
          : listReceiptModel // ignore: cast_nullable_to_non_nullable
              as List<ReceiptModel>,
      receiptIdTitle: freezed == receiptIdTitle
          ? _value.receiptIdTitle
          : receiptIdTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      pageIndex: null == pageIndex
          ? _value.pageIndex
          : pageIndex // ignore: cast_nullable_to_non_nullable
              as int,
      tempReceiptId: null == tempReceiptId
          ? _value.tempReceiptId
          : tempReceiptId // ignore: cast_nullable_to_non_nullable
              as String,
      tempReceiptModel: freezed == tempReceiptModel
          ? _value.tempReceiptModel
          : tempReceiptModel // ignore: cast_nullable_to_non_nullable
              as ReceiptModel?,
      listTotalDiscount: null == listTotalDiscount
          ? _value._listTotalDiscount
          : listTotalDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      totalDiscount: null == totalDiscount
          ? _value.totalDiscount
          : totalDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      listTaxAfterDiscount: null == listTaxAfterDiscount
          ? _value._listTaxAfterDiscount
          : listTaxAfterDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTaxIncludedAfterDiscount: null == listTaxIncludedAfterDiscount
          ? _value._listTaxIncludedAfterDiscount
          : listTaxIncludedAfterDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      taxAfterDiscount: null == taxAfterDiscount
          ? _value.taxAfterDiscount
          : taxAfterDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      taxIncludedAfterDiscount: null == taxIncludedAfterDiscount
          ? _value.taxIncludedAfterDiscount
          : taxIncludedAfterDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      totalAfterDiscountAndTax: null == totalAfterDiscountAndTax
          ? _value.totalAfterDiscountAndTax
          : totalAfterDiscountAndTax // ignore: cast_nullable_to_non_nullable
              as double,
      listTotalAfterDiscAndTax: null == listTotalAfterDiscAndTax
          ? _value._listTotalAfterDiscAndTax
          : listTotalAfterDiscAndTax // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listReceiptPagingController: freezed == listReceiptPagingController
          ? _value.listReceiptPagingController
          : listReceiptPagingController // ignore: cast_nullable_to_non_nullable
              as PagingController<int, ReceiptModel>?,
      selectedReceiptIndex: freezed == selectedReceiptIndex
          ? _value.selectedReceiptIndex
          : selectedReceiptIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      receiptDialogueNavigator: null == receiptDialogueNavigator
          ? _value.receiptDialogueNavigator
          : receiptDialogueNavigator // ignore: cast_nullable_to_non_nullable
              as int,
      selectedDateRange: freezed == selectedDateRange
          ? _value.selectedDateRange
          : selectedDateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      lastSelectedDateRange: freezed == lastSelectedDateRange
          ? _value.lastSelectedDateRange
          : lastSelectedDateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      formattedDateRange: null == formattedDateRange
          ? _value.formattedDateRange
          : formattedDateRange // ignore: cast_nullable_to_non_nullable
              as String,
      tempPaymentType: freezed == tempPaymentType
          ? _value.tempPaymentType
          : tempPaymentType // ignore: cast_nullable_to_non_nullable
              as String?,
      previousPaymentType: freezed == previousPaymentType
          ? _value.previousPaymentType
          : previousPaymentType // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedPaymentType: freezed == selectedPaymentType
          ? _value.selectedPaymentType
          : selectedPaymentType // ignore: cast_nullable_to_non_nullable
              as String?,
      tempPaymentTypeIndex: null == tempPaymentTypeIndex
          ? _value.tempPaymentTypeIndex
          : tempPaymentTypeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      previousPaymentTypeIndex: null == previousPaymentTypeIndex
          ? _value.previousPaymentTypeIndex
          : previousPaymentTypeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      selectedPaymentTypeIndex: null == selectedPaymentTypeIndex
          ? _value.selectedPaymentTypeIndex
          : selectedPaymentTypeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      tempOrderOption: freezed == tempOrderOption
          ? _value.tempOrderOption
          : tempOrderOption // ignore: cast_nullable_to_non_nullable
              as String?,
      previousOrderOption: freezed == previousOrderOption
          ? _value.previousOrderOption
          : previousOrderOption // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedOrderOption: freezed == selectedOrderOption
          ? _value.selectedOrderOption
          : selectedOrderOption // ignore: cast_nullable_to_non_nullable
              as String?,
      tempOrderOptionIndex: null == tempOrderOptionIndex
          ? _value.tempOrderOptionIndex
          : tempOrderOptionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      previousOrderOptionIndex: null == previousOrderOptionIndex
          ? _value.previousOrderOptionIndex
          : previousOrderOptionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      selectedOrderOptionIndex: null == selectedOrderOptionIndex
          ? _value.selectedOrderOptionIndex
          : selectedOrderOptionIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$ReceiptStateImpl implements _ReceiptState {
  const _$ReceiptStateImpl(
      {final List<ReceiptModel> items = const [],
      final List<ReceiptModel> itemsFromHive = const [],
      this.error,
      this.isLoading = false,
      final List<ReceiptItemModel> incomingRefundReceiptItems = const [],
      final List<ReceiptItemModel> receiptItemsForRefund = const [],
      final List<ReceiptItemModel> initialListReceiptItems = const [],
      final List<ReceiptModel> listReceiptModel = const [],
      this.receiptIdTitle,
      this.pageIndex = 0,
      this.tempReceiptId = '-1',
      this.tempReceiptModel,
      final List<Map<String, dynamic>> listTotalDiscount = const [],
      this.totalDiscount = 0.0,
      final List<Map<String, dynamic>> listTaxAfterDiscount = const [],
      final List<Map<String, dynamic>> listTaxIncludedAfterDiscount = const [],
      this.taxAfterDiscount = 0.0,
      this.taxIncludedAfterDiscount = 0.0,
      this.totalAfterDiscountAndTax = 0.0,
      final List<Map<String, dynamic>> listTotalAfterDiscAndTax = const [],
      this.listReceiptPagingController,
      this.selectedReceiptIndex,
      this.receiptDialogueNavigator = 0,
      this.selectedDateRange,
      this.lastSelectedDateRange,
      this.formattedDateRange = '',
      this.tempPaymentType,
      this.previousPaymentType,
      this.selectedPaymentType,
      this.tempPaymentTypeIndex = -1,
      this.previousPaymentTypeIndex = -1,
      this.selectedPaymentTypeIndex = -1,
      this.tempOrderOption,
      this.previousOrderOption,
      this.selectedOrderOption,
      this.tempOrderOptionIndex = -1,
      this.previousOrderOptionIndex = -1,
      this.selectedOrderOptionIndex = -1})
      : _items = items,
        _itemsFromHive = itemsFromHive,
        _incomingRefundReceiptItems = incomingRefundReceiptItems,
        _receiptItemsForRefund = receiptItemsForRefund,
        _initialListReceiptItems = initialListReceiptItems,
        _listReceiptModel = listReceiptModel,
        _listTotalDiscount = listTotalDiscount,
        _listTaxAfterDiscount = listTaxAfterDiscount,
        _listTaxIncludedAfterDiscount = listTaxIncludedAfterDiscount,
        _listTotalAfterDiscAndTax = listTotalAfterDiscAndTax;

  final List<ReceiptModel> _items;
  @override
  @JsonKey()
  List<ReceiptModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<ReceiptModel> _itemsFromHive;
  @override
  @JsonKey()
  List<ReceiptModel> get itemsFromHive {
    if (_itemsFromHive is EqualUnmodifiableListView) return _itemsFromHive;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_itemsFromHive);
  }

  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;
// Old notifier UI state fields
  final List<ReceiptItemModel> _incomingRefundReceiptItems;
// Old notifier UI state fields
  @override
  @JsonKey()
  List<ReceiptItemModel> get incomingRefundReceiptItems {
    if (_incomingRefundReceiptItems is EqualUnmodifiableListView)
      return _incomingRefundReceiptItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_incomingRefundReceiptItems);
  }

  final List<ReceiptItemModel> _receiptItemsForRefund;
  @override
  @JsonKey()
  List<ReceiptItemModel> get receiptItemsForRefund {
    if (_receiptItemsForRefund is EqualUnmodifiableListView)
      return _receiptItemsForRefund;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_receiptItemsForRefund);
  }

  final List<ReceiptItemModel> _initialListReceiptItems;
  @override
  @JsonKey()
  List<ReceiptItemModel> get initialListReceiptItems {
    if (_initialListReceiptItems is EqualUnmodifiableListView)
      return _initialListReceiptItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_initialListReceiptItems);
  }

  final List<ReceiptModel> _listReceiptModel;
  @override
  @JsonKey()
  List<ReceiptModel> get listReceiptModel {
    if (_listReceiptModel is EqualUnmodifiableListView)
      return _listReceiptModel;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listReceiptModel);
  }

  @override
  final String? receiptIdTitle;
  @override
  @JsonKey()
  final int pageIndex;
  @override
  @JsonKey()
  final String tempReceiptId;
  @override
  final ReceiptModel? tempReceiptModel;
// Calculation lists and totals
  final List<Map<String, dynamic>> _listTotalDiscount;
// Calculation lists and totals
  @override
  @JsonKey()
  List<Map<String, dynamic>> get listTotalDiscount {
    if (_listTotalDiscount is EqualUnmodifiableListView)
      return _listTotalDiscount;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listTotalDiscount);
  }

  @override
  @JsonKey()
  final double totalDiscount;
  final List<Map<String, dynamic>> _listTaxAfterDiscount;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get listTaxAfterDiscount {
    if (_listTaxAfterDiscount is EqualUnmodifiableListView)
      return _listTaxAfterDiscount;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listTaxAfterDiscount);
  }

  final List<Map<String, dynamic>> _listTaxIncludedAfterDiscount;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get listTaxIncludedAfterDiscount {
    if (_listTaxIncludedAfterDiscount is EqualUnmodifiableListView)
      return _listTaxIncludedAfterDiscount;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listTaxIncludedAfterDiscount);
  }

  @override
  @JsonKey()
  final double taxAfterDiscount;
  @override
  @JsonKey()
  final double taxIncludedAfterDiscount;
  @override
  @JsonKey()
  final double totalAfterDiscountAndTax;
  final List<Map<String, dynamic>> _listTotalAfterDiscAndTax;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get listTotalAfterDiscAndTax {
    if (_listTotalAfterDiscAndTax is EqualUnmodifiableListView)
      return _listTotalAfterDiscAndTax;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listTotalAfterDiscAndTax);
  }

// Pagination
  @override
  final PagingController<int, ReceiptModel>? listReceiptPagingController;
  @override
  final int? selectedReceiptIndex;
  @override
  @JsonKey()
  final int receiptDialogueNavigator;
// Filter state
  @override
  final DateTimeRange? selectedDateRange;
  @override
  final DateTimeRange? lastSelectedDateRange;
  @override
  @JsonKey()
  final String formattedDateRange;
// Payment type filter
  @override
  final String? tempPaymentType;
  @override
  final String? previousPaymentType;
  @override
  final String? selectedPaymentType;
  @override
  @JsonKey()
  final int tempPaymentTypeIndex;
  @override
  @JsonKey()
  final int previousPaymentTypeIndex;
  @override
  @JsonKey()
  final int selectedPaymentTypeIndex;
// Order option filter
  @override
  final String? tempOrderOption;
  @override
  final String? previousOrderOption;
  @override
  final String? selectedOrderOption;
  @override
  @JsonKey()
  final int tempOrderOptionIndex;
  @override
  @JsonKey()
  final int previousOrderOptionIndex;
  @override
  @JsonKey()
  final int selectedOrderOptionIndex;

  @override
  String toString() {
    return 'ReceiptState(items: $items, itemsFromHive: $itemsFromHive, error: $error, isLoading: $isLoading, incomingRefundReceiptItems: $incomingRefundReceiptItems, receiptItemsForRefund: $receiptItemsForRefund, initialListReceiptItems: $initialListReceiptItems, listReceiptModel: $listReceiptModel, receiptIdTitle: $receiptIdTitle, pageIndex: $pageIndex, tempReceiptId: $tempReceiptId, tempReceiptModel: $tempReceiptModel, listTotalDiscount: $listTotalDiscount, totalDiscount: $totalDiscount, listTaxAfterDiscount: $listTaxAfterDiscount, listTaxIncludedAfterDiscount: $listTaxIncludedAfterDiscount, taxAfterDiscount: $taxAfterDiscount, taxIncludedAfterDiscount: $taxIncludedAfterDiscount, totalAfterDiscountAndTax: $totalAfterDiscountAndTax, listTotalAfterDiscAndTax: $listTotalAfterDiscAndTax, listReceiptPagingController: $listReceiptPagingController, selectedReceiptIndex: $selectedReceiptIndex, receiptDialogueNavigator: $receiptDialogueNavigator, selectedDateRange: $selectedDateRange, lastSelectedDateRange: $lastSelectedDateRange, formattedDateRange: $formattedDateRange, tempPaymentType: $tempPaymentType, previousPaymentType: $previousPaymentType, selectedPaymentType: $selectedPaymentType, tempPaymentTypeIndex: $tempPaymentTypeIndex, previousPaymentTypeIndex: $previousPaymentTypeIndex, selectedPaymentTypeIndex: $selectedPaymentTypeIndex, tempOrderOption: $tempOrderOption, previousOrderOption: $previousOrderOption, selectedOrderOption: $selectedOrderOption, tempOrderOptionIndex: $tempOrderOptionIndex, previousOrderOptionIndex: $previousOrderOptionIndex, selectedOrderOptionIndex: $selectedOrderOptionIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceiptStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality()
                .equals(other._itemsFromHive, _itemsFromHive) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(
                other._incomingRefundReceiptItems,
                _incomingRefundReceiptItems) &&
            const DeepCollectionEquality()
                .equals(other._receiptItemsForRefund, _receiptItemsForRefund) &&
            const DeepCollectionEquality().equals(
                other._initialListReceiptItems, _initialListReceiptItems) &&
            const DeepCollectionEquality()
                .equals(other._listReceiptModel, _listReceiptModel) &&
            (identical(other.receiptIdTitle, receiptIdTitle) ||
                other.receiptIdTitle == receiptIdTitle) &&
            (identical(other.pageIndex, pageIndex) ||
                other.pageIndex == pageIndex) &&
            (identical(other.tempReceiptId, tempReceiptId) ||
                other.tempReceiptId == tempReceiptId) &&
            (identical(other.tempReceiptModel, tempReceiptModel) ||
                other.tempReceiptModel == tempReceiptModel) &&
            const DeepCollectionEquality()
                .equals(other._listTotalDiscount, _listTotalDiscount) &&
            (identical(other.totalDiscount, totalDiscount) ||
                other.totalDiscount == totalDiscount) &&
            const DeepCollectionEquality()
                .equals(other._listTaxAfterDiscount, _listTaxAfterDiscount) &&
            const DeepCollectionEquality().equals(
                other._listTaxIncludedAfterDiscount,
                _listTaxIncludedAfterDiscount) &&
            (identical(other.taxAfterDiscount, taxAfterDiscount) ||
                other.taxAfterDiscount == taxAfterDiscount) &&
            (identical(other.taxIncludedAfterDiscount, taxIncludedAfterDiscount) ||
                other.taxIncludedAfterDiscount == taxIncludedAfterDiscount) &&
            (identical(other.totalAfterDiscountAndTax, totalAfterDiscountAndTax) ||
                other.totalAfterDiscountAndTax == totalAfterDiscountAndTax) &&
            const DeepCollectionEquality().equals(
                other._listTotalAfterDiscAndTax, _listTotalAfterDiscAndTax) &&
            (identical(other.listReceiptPagingController, listReceiptPagingController) ||
                other.listReceiptPagingController ==
                    listReceiptPagingController) &&
            (identical(other.selectedReceiptIndex, selectedReceiptIndex) ||
                other.selectedReceiptIndex == selectedReceiptIndex) &&
            (identical(other.receiptDialogueNavigator, receiptDialogueNavigator) ||
                other.receiptDialogueNavigator == receiptDialogueNavigator) &&
            (identical(other.selectedDateRange, selectedDateRange) ||
                other.selectedDateRange == selectedDateRange) &&
            (identical(other.lastSelectedDateRange, lastSelectedDateRange) ||
                other.lastSelectedDateRange == lastSelectedDateRange) &&
            (identical(other.formattedDateRange, formattedDateRange) ||
                other.formattedDateRange == formattedDateRange) &&
            (identical(other.tempPaymentType, tempPaymentType) ||
                other.tempPaymentType == tempPaymentType) &&
            (identical(other.previousPaymentType, previousPaymentType) ||
                other.previousPaymentType == previousPaymentType) &&
            (identical(other.selectedPaymentType, selectedPaymentType) ||
                other.selectedPaymentType == selectedPaymentType) &&
            (identical(other.tempPaymentTypeIndex, tempPaymentTypeIndex) ||
                other.tempPaymentTypeIndex == tempPaymentTypeIndex) &&
            (identical(other.previousPaymentTypeIndex, previousPaymentTypeIndex) ||
                other.previousPaymentTypeIndex == previousPaymentTypeIndex) &&
            (identical(other.selectedPaymentTypeIndex, selectedPaymentTypeIndex) ||
                other.selectedPaymentTypeIndex == selectedPaymentTypeIndex) &&
            (identical(other.tempOrderOption, tempOrderOption) ||
                other.tempOrderOption == tempOrderOption) &&
            (identical(other.previousOrderOption, previousOrderOption) ||
                other.previousOrderOption == previousOrderOption) &&
            (identical(other.selectedOrderOption, selectedOrderOption) || other.selectedOrderOption == selectedOrderOption) &&
            (identical(other.tempOrderOptionIndex, tempOrderOptionIndex) || other.tempOrderOptionIndex == tempOrderOptionIndex) &&
            (identical(other.previousOrderOptionIndex, previousOrderOptionIndex) || other.previousOrderOptionIndex == previousOrderOptionIndex) &&
            (identical(other.selectedOrderOptionIndex, selectedOrderOptionIndex) || other.selectedOrderOptionIndex == selectedOrderOptionIndex));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        const DeepCollectionEquality().hash(_items),
        const DeepCollectionEquality().hash(_itemsFromHive),
        error,
        isLoading,
        const DeepCollectionEquality().hash(_incomingRefundReceiptItems),
        const DeepCollectionEquality().hash(_receiptItemsForRefund),
        const DeepCollectionEquality().hash(_initialListReceiptItems),
        const DeepCollectionEquality().hash(_listReceiptModel),
        receiptIdTitle,
        pageIndex,
        tempReceiptId,
        tempReceiptModel,
        const DeepCollectionEquality().hash(_listTotalDiscount),
        totalDiscount,
        const DeepCollectionEquality().hash(_listTaxAfterDiscount),
        const DeepCollectionEquality().hash(_listTaxIncludedAfterDiscount),
        taxAfterDiscount,
        taxIncludedAfterDiscount,
        totalAfterDiscountAndTax,
        const DeepCollectionEquality().hash(_listTotalAfterDiscAndTax),
        listReceiptPagingController,
        selectedReceiptIndex,
        receiptDialogueNavigator,
        selectedDateRange,
        lastSelectedDateRange,
        formattedDateRange,
        tempPaymentType,
        previousPaymentType,
        selectedPaymentType,
        tempPaymentTypeIndex,
        previousPaymentTypeIndex,
        selectedPaymentTypeIndex,
        tempOrderOption,
        previousOrderOption,
        selectedOrderOption,
        tempOrderOptionIndex,
        previousOrderOptionIndex,
        selectedOrderOptionIndex
      ]);

  /// Create a copy of ReceiptState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceiptStateImplCopyWith<_$ReceiptStateImpl> get copyWith =>
      __$$ReceiptStateImplCopyWithImpl<_$ReceiptStateImpl>(this, _$identity);
}

abstract class _ReceiptState implements ReceiptState {
  const factory _ReceiptState(
      {final List<ReceiptModel> items,
      final List<ReceiptModel> itemsFromHive,
      final String? error,
      final bool isLoading,
      final List<ReceiptItemModel> incomingRefundReceiptItems,
      final List<ReceiptItemModel> receiptItemsForRefund,
      final List<ReceiptItemModel> initialListReceiptItems,
      final List<ReceiptModel> listReceiptModel,
      final String? receiptIdTitle,
      final int pageIndex,
      final String tempReceiptId,
      final ReceiptModel? tempReceiptModel,
      final List<Map<String, dynamic>> listTotalDiscount,
      final double totalDiscount,
      final List<Map<String, dynamic>> listTaxAfterDiscount,
      final List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
      final double taxAfterDiscount,
      final double taxIncludedAfterDiscount,
      final double totalAfterDiscountAndTax,
      final List<Map<String, dynamic>> listTotalAfterDiscAndTax,
      final PagingController<int, ReceiptModel>? listReceiptPagingController,
      final int? selectedReceiptIndex,
      final int receiptDialogueNavigator,
      final DateTimeRange? selectedDateRange,
      final DateTimeRange? lastSelectedDateRange,
      final String formattedDateRange,
      final String? tempPaymentType,
      final String? previousPaymentType,
      final String? selectedPaymentType,
      final int tempPaymentTypeIndex,
      final int previousPaymentTypeIndex,
      final int selectedPaymentTypeIndex,
      final String? tempOrderOption,
      final String? previousOrderOption,
      final String? selectedOrderOption,
      final int tempOrderOptionIndex,
      final int previousOrderOptionIndex,
      final int selectedOrderOptionIndex}) = _$ReceiptStateImpl;

  @override
  List<ReceiptModel> get items;
  @override
  List<ReceiptModel> get itemsFromHive;
  @override
  String? get error;
  @override
  bool get isLoading; // Old notifier UI state fields
  @override
  List<ReceiptItemModel> get incomingRefundReceiptItems;
  @override
  List<ReceiptItemModel> get receiptItemsForRefund;
  @override
  List<ReceiptItemModel> get initialListReceiptItems;
  @override
  List<ReceiptModel> get listReceiptModel;
  @override
  String? get receiptIdTitle;
  @override
  int get pageIndex;
  @override
  String get tempReceiptId;
  @override
  ReceiptModel? get tempReceiptModel; // Calculation lists and totals
  @override
  List<Map<String, dynamic>> get listTotalDiscount;
  @override
  double get totalDiscount;
  @override
  List<Map<String, dynamic>> get listTaxAfterDiscount;
  @override
  List<Map<String, dynamic>> get listTaxIncludedAfterDiscount;
  @override
  double get taxAfterDiscount;
  @override
  double get taxIncludedAfterDiscount;
  @override
  double get totalAfterDiscountAndTax;
  @override
  List<Map<String, dynamic>> get listTotalAfterDiscAndTax; // Pagination
  @override
  PagingController<int, ReceiptModel>? get listReceiptPagingController;
  @override
  int? get selectedReceiptIndex;
  @override
  int get receiptDialogueNavigator; // Filter state
  @override
  DateTimeRange? get selectedDateRange;
  @override
  DateTimeRange? get lastSelectedDateRange;
  @override
  String get formattedDateRange; // Payment type filter
  @override
  String? get tempPaymentType;
  @override
  String? get previousPaymentType;
  @override
  String? get selectedPaymentType;
  @override
  int get tempPaymentTypeIndex;
  @override
  int get previousPaymentTypeIndex;
  @override
  int get selectedPaymentTypeIndex; // Order option filter
  @override
  String? get tempOrderOption;
  @override
  String? get previousOrderOption;
  @override
  String? get selectedOrderOption;
  @override
  int get tempOrderOptionIndex;
  @override
  int get previousOrderOptionIndex;
  @override
  int get selectedOrderOptionIndex;

  /// Create a copy of ReceiptState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceiptStateImplCopyWith<_$ReceiptStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
