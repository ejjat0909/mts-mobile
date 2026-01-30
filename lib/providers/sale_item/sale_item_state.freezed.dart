// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale_item_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SaleItemState {
  List<SaleItemModel> get saleItems => throw _privateConstructorUsedError;
  Set<String> get saleItemIds => throw _privateConstructorUsedError;
  List<SaleModel> get selectedOpenOrders => throw _privateConstructorUsedError;
  List<ModifierOptionModel> get listModifierOptionDB =>
      throw _privateConstructorUsedError;
  List<ModifierModel> get listModifiers => throw _privateConstructorUsedError;
  List<ModifierOptionModel> get listSelectedModifierOption =>
      throw _privateConstructorUsedError;
  List<SaleModifierModel> get saleModifiers =>
      throw _privateConstructorUsedError;
  List<SaleModifierOptionModel> get saleModifierOptions =>
      throw _privateConstructorUsedError;
  List<CategoryModel?> get listCategories => throw _privateConstructorUsedError;
  Map<int, CategoryModel?> get selectedCategories =>
      throw _privateConstructorUsedError;
  List<ItemModel?> get listItems => throw _privateConstructorUsedError;
  Map<int, ItemModel?> get selectedItems => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get orderList =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTotalDiscount =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTaxAfterDiscount =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTaxIncludedAfterDiscount =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTotalAfterDiscountAndTax =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listCustomVariant =>
      throw _privateConstructorUsedError;
  double get totalDiscount => throw _privateConstructorUsedError;
  double get taxAfterDiscount => throw _privateConstructorUsedError;
  double get taxIncludedAfterDiscount => throw _privateConstructorUsedError;
  double get totalAfterDiscountAndTax => throw _privateConstructorUsedError;
  double get totalWithAdjustedPrice => throw _privateConstructorUsedError;
  double get adjustedPrice => throw _privateConstructorUsedError;
  double get salesTax => throw _privateConstructorUsedError;
  double get salesDiscount => throw _privateConstructorUsedError;
  double get totalAmountRemaining => throw _privateConstructorUsedError;
  double get totalAmountPaid => throw _privateConstructorUsedError;
  double get totalPriceAllSaleItemAfterDiscountAndTax =>
      throw _privateConstructorUsedError;
  SaleModel? get currSaleModel => throw _privateConstructorUsedError;
  PaymentTypeModel? get paymentTypeModel => throw _privateConstructorUsedError;
  OrderOptionModel? get orderOptionModel => throw _privateConstructorUsedError;
  TableModel? get selectedTable => throw _privateConstructorUsedError;
  VariantOptionModel? get variantOptionModel =>
      throw _privateConstructorUsedError;
  PredefinedOrderModel? get pom => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  bool get isEditMode => throw _privateConstructorUsedError;
  bool get canBackToSalesPage => throw _privateConstructorUsedError;
  bool get isSplitPayment => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of SaleItemState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaleItemStateCopyWith<SaleItemState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaleItemStateCopyWith<$Res> {
  factory $SaleItemStateCopyWith(
          SaleItemState value, $Res Function(SaleItemState) then) =
      _$SaleItemStateCopyWithImpl<$Res, SaleItemState>;
  @useResult
  $Res call(
      {List<SaleItemModel> saleItems,
      Set<String> saleItemIds,
      List<SaleModel> selectedOpenOrders,
      List<ModifierOptionModel> listModifierOptionDB,
      List<ModifierModel> listModifiers,
      List<ModifierOptionModel> listSelectedModifierOption,
      List<SaleModifierModel> saleModifiers,
      List<SaleModifierOptionModel> saleModifierOptions,
      List<CategoryModel?> listCategories,
      Map<int, CategoryModel?> selectedCategories,
      List<ItemModel?> listItems,
      Map<int, ItemModel?> selectedItems,
      List<Map<String, dynamic>> orderList,
      List<Map<String, dynamic>> listTotalDiscount,
      List<Map<String, dynamic>> listTaxAfterDiscount,
      List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
      List<Map<String, dynamic>> listTotalAfterDiscountAndTax,
      List<Map<String, dynamic>> listCustomVariant,
      double totalDiscount,
      double taxAfterDiscount,
      double taxIncludedAfterDiscount,
      double totalAfterDiscountAndTax,
      double totalWithAdjustedPrice,
      double adjustedPrice,
      double salesTax,
      double salesDiscount,
      double totalAmountRemaining,
      double totalAmountPaid,
      double totalPriceAllSaleItemAfterDiscountAndTax,
      SaleModel? currSaleModel,
      PaymentTypeModel? paymentTypeModel,
      OrderOptionModel? orderOptionModel,
      TableModel? selectedTable,
      VariantOptionModel? variantOptionModel,
      PredefinedOrderModel? pom,
      String categoryId,
      bool isEditMode,
      bool canBackToSalesPage,
      bool isSplitPayment,
      String? error,
      bool isLoading});
}

/// @nodoc
class _$SaleItemStateCopyWithImpl<$Res, $Val extends SaleItemState>
    implements $SaleItemStateCopyWith<$Res> {
  _$SaleItemStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaleItemState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saleItems = null,
    Object? saleItemIds = null,
    Object? selectedOpenOrders = null,
    Object? listModifierOptionDB = null,
    Object? listModifiers = null,
    Object? listSelectedModifierOption = null,
    Object? saleModifiers = null,
    Object? saleModifierOptions = null,
    Object? listCategories = null,
    Object? selectedCategories = null,
    Object? listItems = null,
    Object? selectedItems = null,
    Object? orderList = null,
    Object? listTotalDiscount = null,
    Object? listTaxAfterDiscount = null,
    Object? listTaxIncludedAfterDiscount = null,
    Object? listTotalAfterDiscountAndTax = null,
    Object? listCustomVariant = null,
    Object? totalDiscount = null,
    Object? taxAfterDiscount = null,
    Object? taxIncludedAfterDiscount = null,
    Object? totalAfterDiscountAndTax = null,
    Object? totalWithAdjustedPrice = null,
    Object? adjustedPrice = null,
    Object? salesTax = null,
    Object? salesDiscount = null,
    Object? totalAmountRemaining = null,
    Object? totalAmountPaid = null,
    Object? totalPriceAllSaleItemAfterDiscountAndTax = null,
    Object? currSaleModel = freezed,
    Object? paymentTypeModel = freezed,
    Object? orderOptionModel = freezed,
    Object? selectedTable = freezed,
    Object? variantOptionModel = freezed,
    Object? pom = freezed,
    Object? categoryId = null,
    Object? isEditMode = null,
    Object? canBackToSalesPage = null,
    Object? isSplitPayment = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      saleItems: null == saleItems
          ? _value.saleItems
          : saleItems // ignore: cast_nullable_to_non_nullable
              as List<SaleItemModel>,
      saleItemIds: null == saleItemIds
          ? _value.saleItemIds
          : saleItemIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedOpenOrders: null == selectedOpenOrders
          ? _value.selectedOpenOrders
          : selectedOpenOrders // ignore: cast_nullable_to_non_nullable
              as List<SaleModel>,
      listModifierOptionDB: null == listModifierOptionDB
          ? _value.listModifierOptionDB
          : listModifierOptionDB // ignore: cast_nullable_to_non_nullable
              as List<ModifierOptionModel>,
      listModifiers: null == listModifiers
          ? _value.listModifiers
          : listModifiers // ignore: cast_nullable_to_non_nullable
              as List<ModifierModel>,
      listSelectedModifierOption: null == listSelectedModifierOption
          ? _value.listSelectedModifierOption
          : listSelectedModifierOption // ignore: cast_nullable_to_non_nullable
              as List<ModifierOptionModel>,
      saleModifiers: null == saleModifiers
          ? _value.saleModifiers
          : saleModifiers // ignore: cast_nullable_to_non_nullable
              as List<SaleModifierModel>,
      saleModifierOptions: null == saleModifierOptions
          ? _value.saleModifierOptions
          : saleModifierOptions // ignore: cast_nullable_to_non_nullable
              as List<SaleModifierOptionModel>,
      listCategories: null == listCategories
          ? _value.listCategories
          : listCategories // ignore: cast_nullable_to_non_nullable
              as List<CategoryModel?>,
      selectedCategories: null == selectedCategories
          ? _value.selectedCategories
          : selectedCategories // ignore: cast_nullable_to_non_nullable
              as Map<int, CategoryModel?>,
      listItems: null == listItems
          ? _value.listItems
          : listItems // ignore: cast_nullable_to_non_nullable
              as List<ItemModel?>,
      selectedItems: null == selectedItems
          ? _value.selectedItems
          : selectedItems // ignore: cast_nullable_to_non_nullable
              as Map<int, ItemModel?>,
      orderList: null == orderList
          ? _value.orderList
          : orderList // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTotalDiscount: null == listTotalDiscount
          ? _value.listTotalDiscount
          : listTotalDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTaxAfterDiscount: null == listTaxAfterDiscount
          ? _value.listTaxAfterDiscount
          : listTaxAfterDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTaxIncludedAfterDiscount: null == listTaxIncludedAfterDiscount
          ? _value.listTaxIncludedAfterDiscount
          : listTaxIncludedAfterDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTotalAfterDiscountAndTax: null == listTotalAfterDiscountAndTax
          ? _value.listTotalAfterDiscountAndTax
          : listTotalAfterDiscountAndTax // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listCustomVariant: null == listCustomVariant
          ? _value.listCustomVariant
          : listCustomVariant // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      totalDiscount: null == totalDiscount
          ? _value.totalDiscount
          : totalDiscount // ignore: cast_nullable_to_non_nullable
              as double,
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
      totalWithAdjustedPrice: null == totalWithAdjustedPrice
          ? _value.totalWithAdjustedPrice
          : totalWithAdjustedPrice // ignore: cast_nullable_to_non_nullable
              as double,
      adjustedPrice: null == adjustedPrice
          ? _value.adjustedPrice
          : adjustedPrice // ignore: cast_nullable_to_non_nullable
              as double,
      salesTax: null == salesTax
          ? _value.salesTax
          : salesTax // ignore: cast_nullable_to_non_nullable
              as double,
      salesDiscount: null == salesDiscount
          ? _value.salesDiscount
          : salesDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmountRemaining: null == totalAmountRemaining
          ? _value.totalAmountRemaining
          : totalAmountRemaining // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmountPaid: null == totalAmountPaid
          ? _value.totalAmountPaid
          : totalAmountPaid // ignore: cast_nullable_to_non_nullable
              as double,
      totalPriceAllSaleItemAfterDiscountAndTax: null ==
              totalPriceAllSaleItemAfterDiscountAndTax
          ? _value.totalPriceAllSaleItemAfterDiscountAndTax
          : totalPriceAllSaleItemAfterDiscountAndTax // ignore: cast_nullable_to_non_nullable
              as double,
      currSaleModel: freezed == currSaleModel
          ? _value.currSaleModel
          : currSaleModel // ignore: cast_nullable_to_non_nullable
              as SaleModel?,
      paymentTypeModel: freezed == paymentTypeModel
          ? _value.paymentTypeModel
          : paymentTypeModel // ignore: cast_nullable_to_non_nullable
              as PaymentTypeModel?,
      orderOptionModel: freezed == orderOptionModel
          ? _value.orderOptionModel
          : orderOptionModel // ignore: cast_nullable_to_non_nullable
              as OrderOptionModel?,
      selectedTable: freezed == selectedTable
          ? _value.selectedTable
          : selectedTable // ignore: cast_nullable_to_non_nullable
              as TableModel?,
      variantOptionModel: freezed == variantOptionModel
          ? _value.variantOptionModel
          : variantOptionModel // ignore: cast_nullable_to_non_nullable
              as VariantOptionModel?,
      pom: freezed == pom
          ? _value.pom
          : pom // ignore: cast_nullable_to_non_nullable
              as PredefinedOrderModel?,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      isEditMode: null == isEditMode
          ? _value.isEditMode
          : isEditMode // ignore: cast_nullable_to_non_nullable
              as bool,
      canBackToSalesPage: null == canBackToSalesPage
          ? _value.canBackToSalesPage
          : canBackToSalesPage // ignore: cast_nullable_to_non_nullable
              as bool,
      isSplitPayment: null == isSplitPayment
          ? _value.isSplitPayment
          : isSplitPayment // ignore: cast_nullable_to_non_nullable
              as bool,
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
abstract class _$$SaleItemStateImplCopyWith<$Res>
    implements $SaleItemStateCopyWith<$Res> {
  factory _$$SaleItemStateImplCopyWith(
          _$SaleItemStateImpl value, $Res Function(_$SaleItemStateImpl) then) =
      __$$SaleItemStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<SaleItemModel> saleItems,
      Set<String> saleItemIds,
      List<SaleModel> selectedOpenOrders,
      List<ModifierOptionModel> listModifierOptionDB,
      List<ModifierModel> listModifiers,
      List<ModifierOptionModel> listSelectedModifierOption,
      List<SaleModifierModel> saleModifiers,
      List<SaleModifierOptionModel> saleModifierOptions,
      List<CategoryModel?> listCategories,
      Map<int, CategoryModel?> selectedCategories,
      List<ItemModel?> listItems,
      Map<int, ItemModel?> selectedItems,
      List<Map<String, dynamic>> orderList,
      List<Map<String, dynamic>> listTotalDiscount,
      List<Map<String, dynamic>> listTaxAfterDiscount,
      List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
      List<Map<String, dynamic>> listTotalAfterDiscountAndTax,
      List<Map<String, dynamic>> listCustomVariant,
      double totalDiscount,
      double taxAfterDiscount,
      double taxIncludedAfterDiscount,
      double totalAfterDiscountAndTax,
      double totalWithAdjustedPrice,
      double adjustedPrice,
      double salesTax,
      double salesDiscount,
      double totalAmountRemaining,
      double totalAmountPaid,
      double totalPriceAllSaleItemAfterDiscountAndTax,
      SaleModel? currSaleModel,
      PaymentTypeModel? paymentTypeModel,
      OrderOptionModel? orderOptionModel,
      TableModel? selectedTable,
      VariantOptionModel? variantOptionModel,
      PredefinedOrderModel? pom,
      String categoryId,
      bool isEditMode,
      bool canBackToSalesPage,
      bool isSplitPayment,
      String? error,
      bool isLoading});
}

/// @nodoc
class __$$SaleItemStateImplCopyWithImpl<$Res>
    extends _$SaleItemStateCopyWithImpl<$Res, _$SaleItemStateImpl>
    implements _$$SaleItemStateImplCopyWith<$Res> {
  __$$SaleItemStateImplCopyWithImpl(
      _$SaleItemStateImpl _value, $Res Function(_$SaleItemStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SaleItemState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saleItems = null,
    Object? saleItemIds = null,
    Object? selectedOpenOrders = null,
    Object? listModifierOptionDB = null,
    Object? listModifiers = null,
    Object? listSelectedModifierOption = null,
    Object? saleModifiers = null,
    Object? saleModifierOptions = null,
    Object? listCategories = null,
    Object? selectedCategories = null,
    Object? listItems = null,
    Object? selectedItems = null,
    Object? orderList = null,
    Object? listTotalDiscount = null,
    Object? listTaxAfterDiscount = null,
    Object? listTaxIncludedAfterDiscount = null,
    Object? listTotalAfterDiscountAndTax = null,
    Object? listCustomVariant = null,
    Object? totalDiscount = null,
    Object? taxAfterDiscount = null,
    Object? taxIncludedAfterDiscount = null,
    Object? totalAfterDiscountAndTax = null,
    Object? totalWithAdjustedPrice = null,
    Object? adjustedPrice = null,
    Object? salesTax = null,
    Object? salesDiscount = null,
    Object? totalAmountRemaining = null,
    Object? totalAmountPaid = null,
    Object? totalPriceAllSaleItemAfterDiscountAndTax = null,
    Object? currSaleModel = freezed,
    Object? paymentTypeModel = freezed,
    Object? orderOptionModel = freezed,
    Object? selectedTable = freezed,
    Object? variantOptionModel = freezed,
    Object? pom = freezed,
    Object? categoryId = null,
    Object? isEditMode = null,
    Object? canBackToSalesPage = null,
    Object? isSplitPayment = null,
    Object? error = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$SaleItemStateImpl(
      saleItems: null == saleItems
          ? _value._saleItems
          : saleItems // ignore: cast_nullable_to_non_nullable
              as List<SaleItemModel>,
      saleItemIds: null == saleItemIds
          ? _value._saleItemIds
          : saleItemIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedOpenOrders: null == selectedOpenOrders
          ? _value._selectedOpenOrders
          : selectedOpenOrders // ignore: cast_nullable_to_non_nullable
              as List<SaleModel>,
      listModifierOptionDB: null == listModifierOptionDB
          ? _value._listModifierOptionDB
          : listModifierOptionDB // ignore: cast_nullable_to_non_nullable
              as List<ModifierOptionModel>,
      listModifiers: null == listModifiers
          ? _value._listModifiers
          : listModifiers // ignore: cast_nullable_to_non_nullable
              as List<ModifierModel>,
      listSelectedModifierOption: null == listSelectedModifierOption
          ? _value._listSelectedModifierOption
          : listSelectedModifierOption // ignore: cast_nullable_to_non_nullable
              as List<ModifierOptionModel>,
      saleModifiers: null == saleModifiers
          ? _value._saleModifiers
          : saleModifiers // ignore: cast_nullable_to_non_nullable
              as List<SaleModifierModel>,
      saleModifierOptions: null == saleModifierOptions
          ? _value._saleModifierOptions
          : saleModifierOptions // ignore: cast_nullable_to_non_nullable
              as List<SaleModifierOptionModel>,
      listCategories: null == listCategories
          ? _value._listCategories
          : listCategories // ignore: cast_nullable_to_non_nullable
              as List<CategoryModel?>,
      selectedCategories: null == selectedCategories
          ? _value._selectedCategories
          : selectedCategories // ignore: cast_nullable_to_non_nullable
              as Map<int, CategoryModel?>,
      listItems: null == listItems
          ? _value._listItems
          : listItems // ignore: cast_nullable_to_non_nullable
              as List<ItemModel?>,
      selectedItems: null == selectedItems
          ? _value._selectedItems
          : selectedItems // ignore: cast_nullable_to_non_nullable
              as Map<int, ItemModel?>,
      orderList: null == orderList
          ? _value._orderList
          : orderList // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTotalDiscount: null == listTotalDiscount
          ? _value._listTotalDiscount
          : listTotalDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTaxAfterDiscount: null == listTaxAfterDiscount
          ? _value._listTaxAfterDiscount
          : listTaxAfterDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTaxIncludedAfterDiscount: null == listTaxIncludedAfterDiscount
          ? _value._listTaxIncludedAfterDiscount
          : listTaxIncludedAfterDiscount // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listTotalAfterDiscountAndTax: null == listTotalAfterDiscountAndTax
          ? _value._listTotalAfterDiscountAndTax
          : listTotalAfterDiscountAndTax // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      listCustomVariant: null == listCustomVariant
          ? _value._listCustomVariant
          : listCustomVariant // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      totalDiscount: null == totalDiscount
          ? _value.totalDiscount
          : totalDiscount // ignore: cast_nullable_to_non_nullable
              as double,
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
      totalWithAdjustedPrice: null == totalWithAdjustedPrice
          ? _value.totalWithAdjustedPrice
          : totalWithAdjustedPrice // ignore: cast_nullable_to_non_nullable
              as double,
      adjustedPrice: null == adjustedPrice
          ? _value.adjustedPrice
          : adjustedPrice // ignore: cast_nullable_to_non_nullable
              as double,
      salesTax: null == salesTax
          ? _value.salesTax
          : salesTax // ignore: cast_nullable_to_non_nullable
              as double,
      salesDiscount: null == salesDiscount
          ? _value.salesDiscount
          : salesDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmountRemaining: null == totalAmountRemaining
          ? _value.totalAmountRemaining
          : totalAmountRemaining // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmountPaid: null == totalAmountPaid
          ? _value.totalAmountPaid
          : totalAmountPaid // ignore: cast_nullable_to_non_nullable
              as double,
      totalPriceAllSaleItemAfterDiscountAndTax: null ==
              totalPriceAllSaleItemAfterDiscountAndTax
          ? _value.totalPriceAllSaleItemAfterDiscountAndTax
          : totalPriceAllSaleItemAfterDiscountAndTax // ignore: cast_nullable_to_non_nullable
              as double,
      currSaleModel: freezed == currSaleModel
          ? _value.currSaleModel
          : currSaleModel // ignore: cast_nullable_to_non_nullable
              as SaleModel?,
      paymentTypeModel: freezed == paymentTypeModel
          ? _value.paymentTypeModel
          : paymentTypeModel // ignore: cast_nullable_to_non_nullable
              as PaymentTypeModel?,
      orderOptionModel: freezed == orderOptionModel
          ? _value.orderOptionModel
          : orderOptionModel // ignore: cast_nullable_to_non_nullable
              as OrderOptionModel?,
      selectedTable: freezed == selectedTable
          ? _value.selectedTable
          : selectedTable // ignore: cast_nullable_to_non_nullable
              as TableModel?,
      variantOptionModel: freezed == variantOptionModel
          ? _value.variantOptionModel
          : variantOptionModel // ignore: cast_nullable_to_non_nullable
              as VariantOptionModel?,
      pom: freezed == pom
          ? _value.pom
          : pom // ignore: cast_nullable_to_non_nullable
              as PredefinedOrderModel?,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      isEditMode: null == isEditMode
          ? _value.isEditMode
          : isEditMode // ignore: cast_nullable_to_non_nullable
              as bool,
      canBackToSalesPage: null == canBackToSalesPage
          ? _value.canBackToSalesPage
          : canBackToSalesPage // ignore: cast_nullable_to_non_nullable
              as bool,
      isSplitPayment: null == isSplitPayment
          ? _value.isSplitPayment
          : isSplitPayment // ignore: cast_nullable_to_non_nullable
              as bool,
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

class _$SaleItemStateImpl implements _SaleItemState {
  _$SaleItemStateImpl(
      {required final List<SaleItemModel> saleItems,
      final Set<String> saleItemIds = const {},
      final List<SaleModel> selectedOpenOrders = const [],
      final List<ModifierOptionModel> listModifierOptionDB = const [],
      final List<ModifierModel> listModifiers = const [],
      final List<ModifierOptionModel> listSelectedModifierOption = const [],
      final List<SaleModifierModel> saleModifiers = const [],
      final List<SaleModifierOptionModel> saleModifierOptions = const [],
      final List<CategoryModel?> listCategories = const [],
      final Map<int, CategoryModel?> selectedCategories = const {},
      final List<ItemModel?> listItems = const [],
      final Map<int, ItemModel?> selectedItems = const {},
      final List<Map<String, dynamic>> orderList = const [],
      final List<Map<String, dynamic>> listTotalDiscount = const [],
      final List<Map<String, dynamic>> listTaxAfterDiscount = const [],
      final List<Map<String, dynamic>> listTaxIncludedAfterDiscount = const [],
      final List<Map<String, dynamic>> listTotalAfterDiscountAndTax = const [],
      final List<Map<String, dynamic>> listCustomVariant = const [],
      this.totalDiscount = 0.0,
      this.taxAfterDiscount = 0.0,
      this.taxIncludedAfterDiscount = 0.0,
      this.totalAfterDiscountAndTax = 0.0,
      this.totalWithAdjustedPrice = 0.0,
      this.adjustedPrice = 0.0,
      this.salesTax = 0.0,
      this.salesDiscount = 0.0,
      this.totalAmountRemaining = 0.0,
      this.totalAmountPaid = 0.0,
      this.totalPriceAllSaleItemAfterDiscountAndTax = 0.0,
      this.currSaleModel,
      this.paymentTypeModel,
      this.orderOptionModel,
      this.selectedTable,
      this.variantOptionModel,
      this.pom,
      this.categoryId = '',
      this.isEditMode = false,
      this.canBackToSalesPage = true,
      this.isSplitPayment = false,
      this.error,
      this.isLoading = false})
      : _saleItems = saleItems,
        _saleItemIds = saleItemIds,
        _selectedOpenOrders = selectedOpenOrders,
        _listModifierOptionDB = listModifierOptionDB,
        _listModifiers = listModifiers,
        _listSelectedModifierOption = listSelectedModifierOption,
        _saleModifiers = saleModifiers,
        _saleModifierOptions = saleModifierOptions,
        _listCategories = listCategories,
        _selectedCategories = selectedCategories,
        _listItems = listItems,
        _selectedItems = selectedItems,
        _orderList = orderList,
        _listTotalDiscount = listTotalDiscount,
        _listTaxAfterDiscount = listTaxAfterDiscount,
        _listTaxIncludedAfterDiscount = listTaxIncludedAfterDiscount,
        _listTotalAfterDiscountAndTax = listTotalAfterDiscountAndTax,
        _listCustomVariant = listCustomVariant;

  final List<SaleItemModel> _saleItems;
  @override
  List<SaleItemModel> get saleItems {
    if (_saleItems is EqualUnmodifiableListView) return _saleItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_saleItems);
  }

  final Set<String> _saleItemIds;
  @override
  @JsonKey()
  Set<String> get saleItemIds {
    if (_saleItemIds is EqualUnmodifiableSetView) return _saleItemIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_saleItemIds);
  }

  final List<SaleModel> _selectedOpenOrders;
  @override
  @JsonKey()
  List<SaleModel> get selectedOpenOrders {
    if (_selectedOpenOrders is EqualUnmodifiableListView)
      return _selectedOpenOrders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedOpenOrders);
  }

  final List<ModifierOptionModel> _listModifierOptionDB;
  @override
  @JsonKey()
  List<ModifierOptionModel> get listModifierOptionDB {
    if (_listModifierOptionDB is EqualUnmodifiableListView)
      return _listModifierOptionDB;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listModifierOptionDB);
  }

  final List<ModifierModel> _listModifiers;
  @override
  @JsonKey()
  List<ModifierModel> get listModifiers {
    if (_listModifiers is EqualUnmodifiableListView) return _listModifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listModifiers);
  }

  final List<ModifierOptionModel> _listSelectedModifierOption;
  @override
  @JsonKey()
  List<ModifierOptionModel> get listSelectedModifierOption {
    if (_listSelectedModifierOption is EqualUnmodifiableListView)
      return _listSelectedModifierOption;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listSelectedModifierOption);
  }

  final List<SaleModifierModel> _saleModifiers;
  @override
  @JsonKey()
  List<SaleModifierModel> get saleModifiers {
    if (_saleModifiers is EqualUnmodifiableListView) return _saleModifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_saleModifiers);
  }

  final List<SaleModifierOptionModel> _saleModifierOptions;
  @override
  @JsonKey()
  List<SaleModifierOptionModel> get saleModifierOptions {
    if (_saleModifierOptions is EqualUnmodifiableListView)
      return _saleModifierOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_saleModifierOptions);
  }

  final List<CategoryModel?> _listCategories;
  @override
  @JsonKey()
  List<CategoryModel?> get listCategories {
    if (_listCategories is EqualUnmodifiableListView) return _listCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listCategories);
  }

  final Map<int, CategoryModel?> _selectedCategories;
  @override
  @JsonKey()
  Map<int, CategoryModel?> get selectedCategories {
    if (_selectedCategories is EqualUnmodifiableMapView)
      return _selectedCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_selectedCategories);
  }

  final List<ItemModel?> _listItems;
  @override
  @JsonKey()
  List<ItemModel?> get listItems {
    if (_listItems is EqualUnmodifiableListView) return _listItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listItems);
  }

  final Map<int, ItemModel?> _selectedItems;
  @override
  @JsonKey()
  Map<int, ItemModel?> get selectedItems {
    if (_selectedItems is EqualUnmodifiableMapView) return _selectedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_selectedItems);
  }

  final List<Map<String, dynamic>> _orderList;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get orderList {
    if (_orderList is EqualUnmodifiableListView) return _orderList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_orderList);
  }

  final List<Map<String, dynamic>> _listTotalDiscount;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get listTotalDiscount {
    if (_listTotalDiscount is EqualUnmodifiableListView)
      return _listTotalDiscount;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listTotalDiscount);
  }

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

  final List<Map<String, dynamic>> _listTotalAfterDiscountAndTax;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get listTotalAfterDiscountAndTax {
    if (_listTotalAfterDiscountAndTax is EqualUnmodifiableListView)
      return _listTotalAfterDiscountAndTax;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listTotalAfterDiscountAndTax);
  }

  final List<Map<String, dynamic>> _listCustomVariant;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get listCustomVariant {
    if (_listCustomVariant is EqualUnmodifiableListView)
      return _listCustomVariant;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listCustomVariant);
  }

  @override
  @JsonKey()
  final double totalDiscount;
  @override
  @JsonKey()
  final double taxAfterDiscount;
  @override
  @JsonKey()
  final double taxIncludedAfterDiscount;
  @override
  @JsonKey()
  final double totalAfterDiscountAndTax;
  @override
  @JsonKey()
  final double totalWithAdjustedPrice;
  @override
  @JsonKey()
  final double adjustedPrice;
  @override
  @JsonKey()
  final double salesTax;
  @override
  @JsonKey()
  final double salesDiscount;
  @override
  @JsonKey()
  final double totalAmountRemaining;
  @override
  @JsonKey()
  final double totalAmountPaid;
  @override
  @JsonKey()
  final double totalPriceAllSaleItemAfterDiscountAndTax;
  @override
  final SaleModel? currSaleModel;
  @override
  final PaymentTypeModel? paymentTypeModel;
  @override
  final OrderOptionModel? orderOptionModel;
  @override
  final TableModel? selectedTable;
  @override
  final VariantOptionModel? variantOptionModel;
  @override
  final PredefinedOrderModel? pom;
  @override
  @JsonKey()
  final String categoryId;
  @override
  @JsonKey()
  final bool isEditMode;
  @override
  @JsonKey()
  final bool canBackToSalesPage;
  @override
  @JsonKey()
  final bool isSplitPayment;
  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'SaleItemState(saleItems: $saleItems, saleItemIds: $saleItemIds, selectedOpenOrders: $selectedOpenOrders, listModifierOptionDB: $listModifierOptionDB, listModifiers: $listModifiers, listSelectedModifierOption: $listSelectedModifierOption, saleModifiers: $saleModifiers, saleModifierOptions: $saleModifierOptions, listCategories: $listCategories, selectedCategories: $selectedCategories, listItems: $listItems, selectedItems: $selectedItems, orderList: $orderList, listTotalDiscount: $listTotalDiscount, listTaxAfterDiscount: $listTaxAfterDiscount, listTaxIncludedAfterDiscount: $listTaxIncludedAfterDiscount, listTotalAfterDiscountAndTax: $listTotalAfterDiscountAndTax, listCustomVariant: $listCustomVariant, totalDiscount: $totalDiscount, taxAfterDiscount: $taxAfterDiscount, taxIncludedAfterDiscount: $taxIncludedAfterDiscount, totalAfterDiscountAndTax: $totalAfterDiscountAndTax, totalWithAdjustedPrice: $totalWithAdjustedPrice, adjustedPrice: $adjustedPrice, salesTax: $salesTax, salesDiscount: $salesDiscount, totalAmountRemaining: $totalAmountRemaining, totalAmountPaid: $totalAmountPaid, totalPriceAllSaleItemAfterDiscountAndTax: $totalPriceAllSaleItemAfterDiscountAndTax, currSaleModel: $currSaleModel, paymentTypeModel: $paymentTypeModel, orderOptionModel: $orderOptionModel, selectedTable: $selectedTable, variantOptionModel: $variantOptionModel, pom: $pom, categoryId: $categoryId, isEditMode: $isEditMode, canBackToSalesPage: $canBackToSalesPage, isSplitPayment: $isSplitPayment, error: $error, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaleItemStateImpl &&
            const DeepCollectionEquality()
                .equals(other._saleItems, _saleItems) &&
            const DeepCollectionEquality()
                .equals(other._saleItemIds, _saleItemIds) &&
            const DeepCollectionEquality()
                .equals(other._selectedOpenOrders, _selectedOpenOrders) &&
            const DeepCollectionEquality()
                .equals(other._listModifierOptionDB, _listModifierOptionDB) &&
            const DeepCollectionEquality()
                .equals(other._listModifiers, _listModifiers) &&
            const DeepCollectionEquality().equals(
                other._listSelectedModifierOption,
                _listSelectedModifierOption) &&
            const DeepCollectionEquality()
                .equals(other._saleModifiers, _saleModifiers) &&
            const DeepCollectionEquality()
                .equals(other._saleModifierOptions, _saleModifierOptions) &&
            const DeepCollectionEquality()
                .equals(other._listCategories, _listCategories) &&
            const DeepCollectionEquality()
                .equals(other._selectedCategories, _selectedCategories) &&
            const DeepCollectionEquality()
                .equals(other._listItems, _listItems) &&
            const DeepCollectionEquality()
                .equals(other._selectedItems, _selectedItems) &&
            const DeepCollectionEquality()
                .equals(other._orderList, _orderList) &&
            const DeepCollectionEquality()
                .equals(other._listTotalDiscount, _listTotalDiscount) &&
            const DeepCollectionEquality()
                .equals(other._listTaxAfterDiscount, _listTaxAfterDiscount) &&
            const DeepCollectionEquality().equals(
                other._listTaxIncludedAfterDiscount,
                _listTaxIncludedAfterDiscount) &&
            const DeepCollectionEquality().equals(
                other._listTotalAfterDiscountAndTax,
                _listTotalAfterDiscountAndTax) &&
            const DeepCollectionEquality()
                .equals(other._listCustomVariant, _listCustomVariant) &&
            (identical(other.totalDiscount, totalDiscount) ||
                other.totalDiscount == totalDiscount) &&
            (identical(other.taxAfterDiscount, taxAfterDiscount) ||
                other.taxAfterDiscount == taxAfterDiscount) &&
            (identical(other.taxIncludedAfterDiscount, taxIncludedAfterDiscount) ||
                other.taxIncludedAfterDiscount == taxIncludedAfterDiscount) &&
            (identical(other.totalAfterDiscountAndTax, totalAfterDiscountAndTax) ||
                other.totalAfterDiscountAndTax == totalAfterDiscountAndTax) &&
            (identical(other.totalWithAdjustedPrice, totalWithAdjustedPrice) ||
                other.totalWithAdjustedPrice == totalWithAdjustedPrice) &&
            (identical(other.adjustedPrice, adjustedPrice) ||
                other.adjustedPrice == adjustedPrice) &&
            (identical(other.salesTax, salesTax) ||
                other.salesTax == salesTax) &&
            (identical(other.salesDiscount, salesDiscount) ||
                other.salesDiscount == salesDiscount) &&
            (identical(other.totalAmountRemaining, totalAmountRemaining) ||
                other.totalAmountRemaining == totalAmountRemaining) &&
            (identical(other.totalAmountPaid, totalAmountPaid) ||
                other.totalAmountPaid == totalAmountPaid) &&
            (identical(other.totalPriceAllSaleItemAfterDiscountAndTax,
                    totalPriceAllSaleItemAfterDiscountAndTax) ||
                other.totalPriceAllSaleItemAfterDiscountAndTax ==
                    totalPriceAllSaleItemAfterDiscountAndTax) &&
            (identical(other.currSaleModel, currSaleModel) ||
                other.currSaleModel == currSaleModel) &&
            (identical(other.paymentTypeModel, paymentTypeModel) ||
                other.paymentTypeModel == paymentTypeModel) &&
            (identical(other.orderOptionModel, orderOptionModel) ||
                other.orderOptionModel == orderOptionModel) &&
            (identical(other.selectedTable, selectedTable) ||
                other.selectedTable == selectedTable) &&
            (identical(other.variantOptionModel, variantOptionModel) ||
                other.variantOptionModel == variantOptionModel) &&
            (identical(other.pom, pom) || other.pom == pom) &&
            (identical(other.categoryId, categoryId) || other.categoryId == categoryId) &&
            (identical(other.isEditMode, isEditMode) || other.isEditMode == isEditMode) &&
            (identical(other.canBackToSalesPage, canBackToSalesPage) || other.canBackToSalesPage == canBackToSalesPage) &&
            (identical(other.isSplitPayment, isSplitPayment) || other.isSplitPayment == isSplitPayment) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) || other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        const DeepCollectionEquality().hash(_saleItems),
        const DeepCollectionEquality().hash(_saleItemIds),
        const DeepCollectionEquality().hash(_selectedOpenOrders),
        const DeepCollectionEquality().hash(_listModifierOptionDB),
        const DeepCollectionEquality().hash(_listModifiers),
        const DeepCollectionEquality().hash(_listSelectedModifierOption),
        const DeepCollectionEquality().hash(_saleModifiers),
        const DeepCollectionEquality().hash(_saleModifierOptions),
        const DeepCollectionEquality().hash(_listCategories),
        const DeepCollectionEquality().hash(_selectedCategories),
        const DeepCollectionEquality().hash(_listItems),
        const DeepCollectionEquality().hash(_selectedItems),
        const DeepCollectionEquality().hash(_orderList),
        const DeepCollectionEquality().hash(_listTotalDiscount),
        const DeepCollectionEquality().hash(_listTaxAfterDiscount),
        const DeepCollectionEquality().hash(_listTaxIncludedAfterDiscount),
        const DeepCollectionEquality().hash(_listTotalAfterDiscountAndTax),
        const DeepCollectionEquality().hash(_listCustomVariant),
        totalDiscount,
        taxAfterDiscount,
        taxIncludedAfterDiscount,
        totalAfterDiscountAndTax,
        totalWithAdjustedPrice,
        adjustedPrice,
        salesTax,
        salesDiscount,
        totalAmountRemaining,
        totalAmountPaid,
        totalPriceAllSaleItemAfterDiscountAndTax,
        currSaleModel,
        paymentTypeModel,
        orderOptionModel,
        selectedTable,
        variantOptionModel,
        pom,
        categoryId,
        isEditMode,
        canBackToSalesPage,
        isSplitPayment,
        error,
        isLoading
      ]);

  /// Create a copy of SaleItemState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaleItemStateImplCopyWith<_$SaleItemStateImpl> get copyWith =>
      __$$SaleItemStateImplCopyWithImpl<_$SaleItemStateImpl>(this, _$identity);
}

abstract class _SaleItemState implements SaleItemState {
  factory _SaleItemState(
      {required final List<SaleItemModel> saleItems,
      final Set<String> saleItemIds,
      final List<SaleModel> selectedOpenOrders,
      final List<ModifierOptionModel> listModifierOptionDB,
      final List<ModifierModel> listModifiers,
      final List<ModifierOptionModel> listSelectedModifierOption,
      final List<SaleModifierModel> saleModifiers,
      final List<SaleModifierOptionModel> saleModifierOptions,
      final List<CategoryModel?> listCategories,
      final Map<int, CategoryModel?> selectedCategories,
      final List<ItemModel?> listItems,
      final Map<int, ItemModel?> selectedItems,
      final List<Map<String, dynamic>> orderList,
      final List<Map<String, dynamic>> listTotalDiscount,
      final List<Map<String, dynamic>> listTaxAfterDiscount,
      final List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
      final List<Map<String, dynamic>> listTotalAfterDiscountAndTax,
      final List<Map<String, dynamic>> listCustomVariant,
      final double totalDiscount,
      final double taxAfterDiscount,
      final double taxIncludedAfterDiscount,
      final double totalAfterDiscountAndTax,
      final double totalWithAdjustedPrice,
      final double adjustedPrice,
      final double salesTax,
      final double salesDiscount,
      final double totalAmountRemaining,
      final double totalAmountPaid,
      final double totalPriceAllSaleItemAfterDiscountAndTax,
      final SaleModel? currSaleModel,
      final PaymentTypeModel? paymentTypeModel,
      final OrderOptionModel? orderOptionModel,
      final TableModel? selectedTable,
      final VariantOptionModel? variantOptionModel,
      final PredefinedOrderModel? pom,
      final String categoryId,
      final bool isEditMode,
      final bool canBackToSalesPage,
      final bool isSplitPayment,
      final String? error,
      final bool isLoading}) = _$SaleItemStateImpl;

  @override
  List<SaleItemModel> get saleItems;
  @override
  Set<String> get saleItemIds;
  @override
  List<SaleModel> get selectedOpenOrders;
  @override
  List<ModifierOptionModel> get listModifierOptionDB;
  @override
  List<ModifierModel> get listModifiers;
  @override
  List<ModifierOptionModel> get listSelectedModifierOption;
  @override
  List<SaleModifierModel> get saleModifiers;
  @override
  List<SaleModifierOptionModel> get saleModifierOptions;
  @override
  List<CategoryModel?> get listCategories;
  @override
  Map<int, CategoryModel?> get selectedCategories;
  @override
  List<ItemModel?> get listItems;
  @override
  Map<int, ItemModel?> get selectedItems;
  @override
  List<Map<String, dynamic>> get orderList;
  @override
  List<Map<String, dynamic>> get listTotalDiscount;
  @override
  List<Map<String, dynamic>> get listTaxAfterDiscount;
  @override
  List<Map<String, dynamic>> get listTaxIncludedAfterDiscount;
  @override
  List<Map<String, dynamic>> get listTotalAfterDiscountAndTax;
  @override
  List<Map<String, dynamic>> get listCustomVariant;
  @override
  double get totalDiscount;
  @override
  double get taxAfterDiscount;
  @override
  double get taxIncludedAfterDiscount;
  @override
  double get totalAfterDiscountAndTax;
  @override
  double get totalWithAdjustedPrice;
  @override
  double get adjustedPrice;
  @override
  double get salesTax;
  @override
  double get salesDiscount;
  @override
  double get totalAmountRemaining;
  @override
  double get totalAmountPaid;
  @override
  double get totalPriceAllSaleItemAfterDiscountAndTax;
  @override
  SaleModel? get currSaleModel;
  @override
  PaymentTypeModel? get paymentTypeModel;
  @override
  OrderOptionModel? get orderOptionModel;
  @override
  TableModel? get selectedTable;
  @override
  VariantOptionModel? get variantOptionModel;
  @override
  PredefinedOrderModel? get pom;
  @override
  String get categoryId;
  @override
  bool get isEditMode;
  @override
  bool get canBackToSalesPage;
  @override
  bool get isSplitPayment;
  @override
  String? get error;
  @override
  bool get isLoading;

  /// Create a copy of SaleItemState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaleItemStateImplCopyWith<_$SaleItemStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
