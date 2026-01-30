import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

//Charge detail at main tables page when table in ordered status has been clicked
class ChargeDetail extends ConsumerStatefulWidget {
  final String staffId;
  final String customerId;
  final String saleId;
  final TableModel tableModel;

  const ChargeDetail({
    super.key,
    required this.staffId,
    required this.customerId,
    required this.saleId,
    required this.tableModel,
  });

  @override
  ConsumerState<ChargeDetail> createState() => _ChargeDetailState();
}

class _ChargeDetailState extends ConsumerState<ChargeDetail> {
  SaleModel? _saleModel;
  CustomerModel? _customerModel;
  StaffModel? _staffModel;
  UserModel? _userModel;
  PredefinedOrderModel? pom;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    _saleModel = await ref
        .read(saleProvider.notifier)
        .getSaleModelBySaleId(widget.saleId);
    if (widget.customerId != '') {
      _customerModel = ref
          .read(customerProvider.notifier)
          .getCustomerById(widget.customerId);
    }
    _staffModel = await ref
        .read(staffProvider.notifier)
        .getStaffModelById(widget.staffId);

    if (_staffModel != null) {
      _userModel = await ref
          .read(userProvider.notifier)
          .getUserModelByIdUser(_staffModel!.userId!);
      //prints(_userModel);
    }

    if (widget.tableModel.predefinedOrderId != null) {
      pom = await ref
          .read(predefinedOrderProvider.notifier)
          .getPredefinedOrderById(widget.tableModel.predefinedOrderId!);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              _item(
                'openOrder'.tr(),
                pom?.id == null ? 'N/A' : (pom?.name ?? "No Name"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _item('staff'.tr(), _userModel?.name ?? 'N/A'),
              _item('Customer', _customerModel?.name ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _item(
                'sum'.tr(),
                _saleModel?.totalPrice?.toStringAsFixed(2) ?? 'N/A',
              ),
              _item(
                'time'.tr(),
                DateFormat(
                  'yyyy-MM-dd – kk:mm',
                  'en_US',
                ).format(_saleModel?.createdAt ?? DateTime.now()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color.fromARGB(255, 58, 58, 58),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
