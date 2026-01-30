import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class OutletPaymentTypeModel {
 static const String modelName = 'OutletPaymentType';
 static const String modelBoxName = 'outlet_payment_type_box';

 // Properties
 String? outletId;
 String? paymentTypeId;
 DateTime? createdAt;
 DateTime? updatedAt;

 // Constructor
 OutletPaymentTypeModel({
   this.outletId,
   this.paymentTypeId,
   this.createdAt,
   this.updatedAt,
 });

 // Factory constructor from JSON
 OutletPaymentTypeModel.fromJson(Map<String, dynamic> json) {
   outletId = FormatUtils.parseToString(json['outlet_id']);
   paymentTypeId = FormatUtils.parseToString(json['payment_type_id']);
   createdAt =
       json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
   updatedAt =
       json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
 }

 // Convert to JSON
 Map<String, dynamic> toJson() {
   final Map<String, dynamic> data = <String, dynamic>{};
   data['outlet_id'] = outletId;
   data['payment_type_id'] = paymentTypeId;

   if (createdAt != null) {
     data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
   }
   if (updatedAt != null) {
     data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
   }

   return data;
 }

 // Copy with method for immutability
 OutletPaymentTypeModel copyWith({
   String? outletId,
   String? paymentTypeId,
   DateTime? createdAt,
   DateTime? updatedAt,
 }) {
   return OutletPaymentTypeModel(
     outletId: outletId ?? this.outletId,
     paymentTypeId: paymentTypeId ?? this.paymentTypeId,
     createdAt: createdAt ?? this.createdAt,
     updatedAt: updatedAt ?? this.updatedAt,
   );
 }
}