import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/city/city_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/division/division_providers.dart';

class ViewCustomerBody extends ConsumerStatefulWidget {
  const ViewCustomerBody({super.key});

  @override
  ConsumerState<ViewCustomerBody> createState() => _ViewCustomerBodyState();
}

class _ViewCustomerBodyState extends ConsumerState<ViewCustomerBody> {
  String? _getDivisionName(int? divisionId) {
    if (divisionId == null) return null;
    final divisions = ref.read(divisionProvider).items;
    final division = divisions.where((d) => d.id == divisionId).firstOrNull;
    return division?.name;
  }

  String? _getCityName(String? cityId) {
    if (cityId == null) return null;
    final cities = ref.read(cityProvider).items;
    final city = cities.where((c) => c.id == cityId).firstOrNull;
    return city?.name;
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final customerModel = customerState.currentCustomer;
    final orderCustomerModel = customerState.orderCustomer;
    return Expanded(
      child: Column(
        children: [
          16.heightBox,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildNameCard(orderCustomerModel, customerModel),
                SizedBox(width: 20.w),
                _buildPhoneCard(orderCustomerModel, customerModel),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildDetailField(
                    icon: FontAwesomeIcons.noteSticky,
                    label: 'note'.tr(),
                    value:
                        orderCustomerModel?.note ??
                        customerModel?.note ??
                        'N/A',

                    backgroundColor: kBadgeBgYellow,
                    textColor: kBadgeTextYellow,
                  ),

                  _buildDetailField(
                    icon: FontAwesomeIcons.envelope,
                    label: 'email'.tr(),
                    value:
                        orderCustomerModel?.email ??
                        customerModel?.email ??
                        'N/A',
                  ),

                  _buildDetailField(
                    icon: FontAwesomeIcons.houseChimney,
                    label: 'address'.tr(),
                    value:
                        orderCustomerModel?.address ??
                        customerModel?.address ??
                        'N/A',
                  ),

                  _buildDetailField(
                    icon: FontAwesomeIcons.locationDot,
                    label: 'postcode'.tr(),
                    value:
                        orderCustomerModel?.postcode ??
                        customerModel?.postcode ??
                        'N/A',
                  ),

                  _buildDetailField(
                    icon: FontAwesomeIcons.mapPin,
                    label: 'state'.tr(),
                    value:
                        _getDivisionName(orderCustomerModel?.worldDivisionId) ??
                        _getDivisionName(customerModel?.worldDivisionId) ??
                        'N/A',
                  ),

                  _buildDetailField(
                    icon: FontAwesomeIcons.city,
                    label: 'city'.tr(),
                    value:
                        _getCityName(
                          orderCustomerModel?.worldCityId?.toString(),
                        ) ??
                        _getCityName(customerModel?.worldCityId?.toString()) ??
                        'N/A',
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Expanded _buildPhoneCard(
    CustomerModel? orderCustomerModel,
    CustomerModel? customerModel,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: UIUtils.itemShadows,
        ),
        child: Column(
          children: [
            const Icon(FontAwesomeIcons.phoneFlip, size: 60, color: kTextGray),
            const Space(20),
            Text(
              orderCustomerModel?.phoneNo ??
                  customerModel?.phoneNo ??
                  'No Phone',
              style: AppTheme.normalTextStyle(fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildNameCard(
    CustomerModel? orderCustomerModel,
    CustomerModel? customerModel,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: UIUtils.itemShadows,
        ),
        child: Column(
          children: [
            const Icon(FontAwesomeIcons.userLarge, size: 60, color: kTextGray),
            const Space(20),
            Text(
              orderCustomerModel?.name ?? customerModel?.name ?? 'No Name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.normalTextStyle(fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField({
    required IconData icon,
    required String label,
    required String value,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: UIUtils.itemShadows,
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor ?? kTextGray, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.normalTextStyle(
                    fontSize: 12.sp,
                    color: textColor ?? Colors.grey,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.normalTextStyle(
                    fontSize: 14.sp,
                    color: textColor ?? kBlackColor,
                    fontWeight:
                        backgroundColor != null ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget editProfileButton() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.pencil, color: white, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'editProfile'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.normalTextStyle(color: white),
            ),
          ),
        ],
      ),
    );
  }
}
