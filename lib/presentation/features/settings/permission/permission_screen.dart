import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/string_utils.dart';
import 'package:mts/data/models/permission/permission_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  UserModel userModel = GetIt.instance<UserModel>();
  StaffModel staffModel = GetIt.instance<StaffModel>();
  List<PermissionModel> listPM = [];
  List<PermissionModel> listStaffPM = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    await getListPermission();
    await getStaffPermission();
  }

  Future<void> getListPermission() async {
    listPM =
        await ref.read(permissionProvider.notifier).getListPermissionModel();
    prints('get list permissions ${listPM.length}');
    setState(() {});
  }

  Future<void> getStaffPermission() async {
    // get user model from staffModel
    UserModel? userStaff = await ref
        .read(staffProvider.notifier)
        .getUserModelByStaffId(staffModel.id!);
    if (userStaff == null) return;
    dynamic nameJson = jsonDecode(userStaff.posPermissionJson!);
    List<String> names = List<String>.from(nameJson);

    for (String name in names) {
      DateTime now = DateTime.now();
      PermissionModel pm = PermissionModel(
        id: IdUtils.generateUUID(),
        name: name,
        description: StringUtils.convertPermissionNameToDesc(name),
        createdAt: now,
        updatedAt: now,
      );

      listStaffPM.add(pm);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (listPM.isNotEmpty) {
      return haveListPermissions();
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: canvasColor,
                    size: 30,
                  ),
                  const Space(10),
                  Text('noPermissions'.tr(), style: AppTheme.mediumTextStyle()),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget haveListPermissions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('name'.tr(), style: AppTheme.h1TextStyle()),
                    ],
                  ),
                  containerName(userModel.name!),
                  listPM.isEmpty
                      ? Column(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: canvasColor,
                            size: 30,
                          ),
                          const Space(10),
                          Text(
                            'noPermissions'.tr(),
                            style: AppTheme.mediumTextStyle(),
                          ),
                        ],
                      )
                      : listPermissions(listPM, listStaffPM),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget containerName(String name) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kLightGray,
        borderRadius: BorderRadius.circular(10),
        //  border: Border.all(color: kPrimaryBgColor),
      ),
      child: Text(name, style: AppTheme.mediumTextStyle()),
    );
  }

  Widget listPermissions(
    List<PermissionModel> listPerMis,
    List<PermissionModel> listStaffPM,
  ) {
    prints(listPerMis.length);
    prints(listStaffPM.length);
    return Column(
      children: List.generate(listPerMis.length, (index) {
        bool isChecked = listStaffPM.any(
          (staffPM) => staffPM.name == listPerMis[index].name,
        );

        return Container(
          decoration: const BoxDecoration(color: kWhiteColor),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  value: isChecked,
                  onChanged: null,
                  checkColor: white,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return kPrimaryColor;
                    }
                    return null;
                  }),
                  focusColor: kPrimaryLightColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  listPerMis[index].description!,
                  style: AppTheme.normalTextStyle(
                    color: isChecked ? kBlackColor : kTextGray,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
