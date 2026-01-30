// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'refund_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RefundState {
  String? get error => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isPrinting => throw _privateConstructorUsedError;
  String? get currentReceiptId => throw _privateConstructorUsedError;
  int get refundItemsCount => throw _privateConstructorUsedError;
  List<String> get printErrors => throw _privateConstructorUsedError;
  int get printersCompleted => throw _privateConstructorUsedError;
  int get printersTotal =>
      throw _privateConstructorUsedError; // Refund item selection and calculations
  List<ReceiptItemModel> get refundItems => throw _privateConstructorUsedError;
  List<ReceiptItemModel> get originRefundItems =>
      throw _privateConstructorUsedError;
  double get totalDiscount => throw _privateConstructorUsedError;
  double get taxAfterDiscount => throw _privateConstructorUsedError;
  double get taxIncludedAfterDiscount => throw _privateConstructorUsedError;
  double get totalAfterDiscountAndTax =>
      throw _privateConstructorUsedError; // Old notifier internal calculation lists
  List<Map<String, dynamic>> get listTotalDiscount =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTaxAfterDiscount =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTaxIncludedAfterDiscount =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get listTotalAfterDiscAndTax =>
      throw _privateConstructorUsedError;

  /// Create a copy of RefundState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RefundStateCopyWith<RefundState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RefundStateCopyWith<$Res> {
  factory $RefundStateCopyWith(
          RefundState value, $Res Function(RefundState) then) =
      _$RefundStateCopyWithImpl<$Res, RefundState>;
  @useResult
  $Res call(
      {String? error,
      bool isLoading,
      bool isPrinting,
      String? currentReceiptId,
      int refundItemsCount,
      List<String> printErrors,
      int printersCompleted,
      int printersTotal,
      List<ReceiptItemModel> refundItems,
      List<ReceiptItemModel> originRefundItems,
      double totalDiscount,
      double taxAfterDiscount,
      double taxIncludedAfterDiscount,
      double totalAfterDiscountAndTax,
      List<Map<String, dynamic>> listTotalDiscount,
      List<Map<String, dynamic>> listTaxAfterDiscount,
      List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
      List<Map<String, dynamic>> listTotalAfterDiscAndTax});
}

/// @nodoc
class _$RefundStateCopyWithImpl<$Res, $Val extends RefundState>
    implements $RefundStateCopyWith<$Res> {
  _$RefundStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RefundState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = freezed,
    Object? isLoading = null,
    Object? isPrinting = null,
    Object? currentReceiptId = freezed,
    Object? refundItemsCount = null,
    Object? printErrors = null,
    Object? printersCompleted = null,
    Object? printersTotal = null,
    Object? refundItems = null,
    Object? originRefundItems = null,
    Object? totalDiscount = null,
    Object? taxAfterDiscount = null,
    Object? taxIncludedAfterDiscount = null,
    Object? totalAfterDiscountAndTax = null,
    Object? listTotalDiscount = null,
    Object? listTaxAfterDiscount = null,
    Object? listTaxIncludedAfterDiscount = null,
    Object? listTotalAfterDiscAndTax = null,
  }) {
    return _then(_value.copyWith(
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isPrinting: null == isPrinting
          ? _value.isPrinting
          : isPrinting // ignore: cast_nullable_to_non_nullable
              as bool,
      currentReceiptId: freezed == currentReceiptId
          ? _value.currentReceiptId
          : currentReceiptId // ignore: cast_nullable_to_non_nullable
              as String?,
      refundItemsCount: null == refundItemsCount
          ? _value.refundItemsCount
          : refundItemsCount // ignore: cast_nullable_to_non_nullable
              as int,
      printErrors: null == printErrors
          ? _value.printErrors
          : printErrors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      printersCompleted: null == printersCompleted
          ? _value.printersCompleted
          : printersCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      printersTotal: null == printersTotal
          ? _value.printersTotal
          : printersTotal // ignore: cast_nullable_to_non_nullable
              as int,
      refundItems: null == refundItems
          ? _value.refundItems
          : refundItems // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
      originRefundItems: null == originRefundItems
          ? _value.originRefundItems
          : originRefundItems // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
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
      listTotalAfterDiscAndTax: null == listTotalAfterDiscAndTax
          ? _value.listTotalAfterDiscAndTax
          : listTotalAfterDiscAndTax // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RefundStateImplCopyWith<$Res>
    implements $RefundStateCopyWith<$Res> {
  factory _$$RefundStateImplCopyWith(
          _$RefundStateImpl value, $Res Function(_$RefundStateImpl) then) =
      __$$RefundStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? error,
      bool isLoading,
      bool isPrinting,
      String? currentReceiptId,
      int refundItemsCount,
      List<String> printErrors,
      int printersCompleted,
      int printersTotal,
      List<ReceiptItemModel> refundItems,
      List<ReceiptItemModel> originRefundItems,
      double totalDiscount,
      double taxAfterDiscount,
      double taxIncludedAfterDiscount,
      double totalAfterDiscountAndTax,
      List<Map<String, dynamic>> listTotalDiscount,
      List<Map<String, dynamic>> listTaxAfterDiscount,
      List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
      List<Map<String, dynamic>> listTotalAfterDiscAndTax});
}

/// @nodoc
class __$$RefundStateImplCopyWithImpl<$Res>
    extends _$RefundStateCopyWithImpl<$Res, _$RefundStateImpl>
    implements _$$RefundStateImplCopyWith<$Res> {
  __$$RefundStateImplCopyWithImpl(
      _$RefundStateImpl _value, $Res Function(_$RefundStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of RefundState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = freezed,
    Object? isLoading = null,
    Object? isPrinting = null,
    Object? currentReceiptId = freezed,
    Object? refundItemsCount = null,
    Object? printErrors = null,
    Object? printersCompleted = null,
    Object? printersTotal = null,
    Object? refundItems = null,
    Object? originRefundItems = null,
    Object? totalDiscount = null,
    Object? taxAfterDiscount = null,
    Object? taxIncludedAfterDiscount = null,
    Object? totalAfterDiscountAndTax = null,
    Object? listTotalDiscount = null,
    Object? listTaxAfterDiscount = null,
    Object? listTaxIncludedAfterDiscount = null,
    Object? listTotalAfterDiscAndTax = null,
  }) {
    return _then(_$RefundStateImpl(
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isPrinting: null == isPrinting
          ? _value.isPrinting
          : isPrinting // ignore: cast_nullable_to_non_nullable
              as bool,
      currentReceiptId: freezed == currentReceiptId
          ? _value.currentReceiptId
          : currentReceiptId // ignore: cast_nullable_to_non_nullable
              as String?,
      refundItemsCount: null == refundItemsCount
          ? _value.refundItemsCount
          : refundItemsCount // ignore: cast_nullable_to_non_nullable
              as int,
      printErrors: null == printErrors
          ? _value._printErrors
          : printErrors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      printersCompleted: null == printersCompleted
          ? _value.printersCompleted
          : printersCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      printersTotal: null == printersTotal
          ? _value.printersTotal
          : printersTotal // ignore: cast_nullable_to_non_nullable
              as int,
      refundItems: null == refundItems
          ? _value._refundItems
          : refundItems // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
      originRefundItems: null == originRefundItems
          ? _value._originRefundItems
          : originRefundItems // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItemModel>,
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
      listTotalAfterDiscAndTax: null == listTotalAfterDiscAndTax
          ? _value._listTotalAfterDiscAndTax
          : listTotalAfterDiscAndTax // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// @nodoc

class _$RefundStateImpl implements _RefundState {
  const _$RefundStateImpl(
      {this.error,
      this.isLoading = false,
      this.isPrinting = false,
      this.currentReceiptId,
      this.refundItemsCount = 0,
      final List<String> printErrors = const [],
      this.printersCompleted = 0,
      this.printersTotal = 0,
      final List<ReceiptItemModel> refundItems = const [],
      final List<ReceiptItemModel> originRefundItems = const [],
      this.totalDiscount = 0.0,
      this.taxAfterDiscount = 0.0,
      this.taxIncludedAfterDiscount = 0.0,
      this.totalAfterDiscountAndTax = 0.0,
      final List<Map<String, dynamic>> listTotalDiscount = const [],
      final List<Map<String, dynamic>> listTaxAfterDiscount = const [],
      final List<Map<String, dynamic>> listTaxIncludedAfterDiscount = const [],
      final List<Map<String, dynamic>> listTotalAfterDiscAndTax = const []})
      : _printErrors = printErrors,
        _refundItems = refundItems,
        _originRefundItems = originRefundItems,
        _listTotalDiscount = listTotalDiscount,
        _listTaxAfterDiscount = listTaxAfterDiscount,
        _listTaxIncludedAfterDiscount = listTaxIncludedAfterDiscount,
        _listTotalAfterDiscAndTax = listTotalAfterDiscAndTax;

  @override
  final String? error;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isPrinting;
  @override
  final String? currentReceiptId;
  @override
  @JsonKey()
  final int refundItemsCount;
  final List<String> _printErrors;
  @override
  @JsonKey()
  List<String> get printErrors {
    if (_printErrors is EqualUnmodifiableListView) return _printErrors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_printErrors);
  }

  @override
  @JsonKey()
  final int printersCompleted;
  @override
  @JsonKey()
  final int printersTotal;
// Refund item selection and calculations
  final List<ReceiptItemModel> _refundItems;
// Refund item selection and calculations
  @override
  @JsonKey()
  List<ReceiptItemModel> get refundItems {
    if (_refundItems is EqualUnmodifiableListView) return _refundItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_refundItems);
  }

  final List<ReceiptItemModel> _originRefundItems;
  @override
  @JsonKey()
  List<ReceiptItemModel> get originRefundItems {
    if (_originRefundItems is EqualUnmodifiableListView)
      return _originRefundItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_originRefundItems);
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
// Old notifier internal calculation lists
  final List<Map<String, dynamic>> _listTotalDiscount;
// Old notifier internal calculation lists
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

  final List<Map<String, dynamic>> _listTotalAfterDiscAndTax;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get listTotalAfterDiscAndTax {
    if (_listTotalAfterDiscAndTax is EqualUnmodifiableListView)
      return _listTotalAfterDiscAndTax;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listTotalAfterDiscAndTax);
  }

  @override
  String toString() {
    return 'RefundState(error: $error, isLoading: $isLoading, isPrinting: $isPrinting, currentReceiptId: $currentReceiptId, refundItemsCount: $refundItemsCount, printErrors: $printErrors, printersCompleted: $printersCompleted, printersTotal: $printersTotal, refundItems: $refundItems, originRefundItems: $originRefundItems, totalDiscount: $totalDiscount, taxAfterDiscount: $taxAfterDiscount, taxIncludedAfterDiscount: $taxIncludedAfterDiscount, totalAfterDiscountAndTax: $totalAfterDiscountAndTax, listTotalDiscount: $listTotalDiscount, listTaxAfterDiscount: $listTaxAfterDiscount, listTaxIncludedAfterDiscount: $listTaxIncludedAfterDiscount, listTotalAfterDiscAndTax: $listTotalAfterDiscAndTax)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RefundStateImpl &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isPrinting, isPrinting) ||
                other.isPrinting == isPrinting) &&
            (identical(other.currentReceiptId, currentReceiptId) ||
                other.currentReceiptId == currentReceiptId) &&
            (identical(other.refundItemsCount, refundItemsCount) ||
                other.refundItemsCount == refundItemsCount) &&
            const DeepCollectionEquality()
                .equals(other._printErrors, _printErrors) &&
            (identical(other.printersCompleted, printersCompleted) ||
                other.printersCompleted == printersCompleted) &&
            (identical(other.printersTotal, printersTotal) ||
                other.printersTotal == printersTotal) &&
            const DeepCollectionEquality()
                .equals(other._refundItems, _refundItems) &&
            const DeepCollectionEquality()
                .equals(other._originRefundItems, _originRefundItems) &&
            (identical(other.totalDiscount, totalDiscount) ||
                other.totalDiscount == totalDiscount) &&
            (identical(other.taxAfterDiscount, taxAfterDiscount) ||
                other.taxAfterDiscount == taxAfterDiscount) &&
            (identical(
                    other.taxIncludedAfterDiscount, taxIncludedAfterDiscount) ||
                other.taxIncludedAfterDiscount == taxIncludedAfterDiscount) &&
            (identical(
                    other.totalAfterDiscountAndTax, totalAfterDiscountAndTax) ||
                other.totalAfterDiscountAndTax == totalAfterDiscountAndTax) &&
            const DeepCollectionEquality()
                .equals(other._listTotalDiscount, _listTotalDiscount) &&
            const DeepCollectionEquality()
                .equals(other._listTaxAfterDiscount, _listTaxAfterDiscount) &&
            const DeepCollectionEquality().equals(
                other._listTaxIncludedAfterDiscount,
                _listTaxIncludedAfterDiscount) &&
            const DeepCollectionEquality().equals(
                other._listTotalAfterDiscAndTax, _listTotalAfterDiscAndTax));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      error,
      isLoading,
      isPrinting,
      currentReceiptId,
      refundItemsCount,
      const DeepCollectionEquality().hash(_printErrors),
      printersCompleted,
      printersTotal,
      const DeepCollectionEquality().hash(_refundItems),
      const DeepCollectionEquality().hash(_originRefundItems),
      totalDiscount,
      taxAfterDiscount,
      taxIncludedAfterDiscount,
      totalAfterDiscountAndTax,
      const DeepCollectionEquality().hash(_listTotalDiscount),
      const DeepCollectionEquality().hash(_listTaxAfterDiscount),
      const DeepCollectionEquality().hash(_listTaxIncludedAfterDiscount),
      const DeepCollectionEquality().hash(_listTotalAfterDiscAndTax));

  /// Create a copy of RefundState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RefundStateImplCopyWith<_$RefundStateImpl> get copyWith =>
      __$$RefundStateImplCopyWithImpl<_$RefundStateImpl>(this, _$identity);
}

abstract class _RefundState implements RefundState {
  const factory _RefundState(
          {final String? error,
          final bool isLoading,
          final bool isPrinting,
          final String? currentReceiptId,
          final int refundItemsCount,
          final List<String> printErrors,
          final int printersCompleted,
          final int printersTotal,
          final List<ReceiptItemModel> refundItems,
          final List<ReceiptItemModel> originRefundItems,
          final double totalDiscount,
          final double taxAfterDiscount,
          final double taxIncludedAfterDiscount,
          final double totalAfterDiscountAndTax,
          final List<Map<String, dynamic>> listTotalDiscount,
          final List<Map<String, dynamic>> listTaxAfterDiscount,
          final List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
          final List<Map<String, dynamic>> listTotalAfterDiscAndTax}) =
      _$RefundStateImpl;

  @override
  String? get error;
  @override
  bool get isLoading;
  @override
  bool get isPrinting;
  @override
  String? get currentReceiptId;
  @override
  int get refundItemsCount;
  @override
  List<String> get printErrors;
  @override
  int get printersCompleted;
  @override
  int get printersTotal; // Refund item selection and calculations
  @override
  List<ReceiptItemModel> get refundItems;
  @override
  List<ReceiptItemModel> get originRefundItems;
  @override
  double get totalDiscount;
  @override
  double get taxAfterDiscount;
  @override
  double get taxIncludedAfterDiscount;
  @override
  double
      get totalAfterDiscountAndTax; // Old notifier internal calculation lists
  @override
  List<Map<String, dynamic>> get listTotalDiscount;
  @override
  List<Map<String, dynamic>> get listTaxAfterDiscount;
  @override
  List<Map<String, dynamic>> get listTaxIncludedAfterDiscount;
  @override
  List<Map<String, dynamic>> get listTotalAfterDiscAndTax;

  /// Create a copy of RefundState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RefundStateImplCopyWith<_$RefundStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
