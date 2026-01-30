import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/temp/temp_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/after_login/after_login_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

class DrawerHeaderContent extends ConsumerStatefulWidget {
  final TempModel? tempModel;

  const DrawerHeaderContent({super.key, required this.tempModel});

  @override
  ConsumerState<DrawerHeaderContent> createState() =>
      _DrawerHeaderContentState();
}

class _DrawerHeaderContentState extends ConsumerState<DrawerHeaderContent> {
  UserModel userModel = ServiceLocator.get<UserModel>();
  StaffModel staffModel = ServiceLocator.get<StaffModel>();
  OutletModel outletModel = ServiceLocator.get<OutletModel>();
  // Secondary display handled by secondDisplayProvider.notifier
  final PosDeviceModel posDeviceModel = ServiceLocator.get<PosDeviceModel>();

  Future<void> getUserModel() async {
    UserModel? user = await ref
        .read(userProvider.notifier)
        .getUserModelByIdUser(staffModel.userId!);

    if (user != null) {
      userModel = user.copyWith();
    }

    setState(() {});
  }

  @override
  void initState() {
    getUserModel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      decoration: const BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // logo picture
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CachedNetworkImage(
                  // imageUrl:
                  //     userModel.profilePhoto == null
                  //         ? 'https://ui-avatars.com/api/?name=${userModel.name}&color=FFFFFF&background=030712'
                  //         : userModel.profilePhoto!,
                  imageUrl:
                      'https://ui-avatars.com/api/?name=${userModel.name}&color=FFFFFF&background=030712',
                  errorWidget:
                      (context, url, error) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        constraints: const BoxConstraints(
                          maxWidth: 50,
                          maxHeight: 50,
                        ),
                      ),
                  width: 60.0,
                  height: 60.0,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, url) => Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ThemeSpinner.spinnerInput(),
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  outletModel.name ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: white,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'staffName'.tr(),
                    //   style: const TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     color: white,
                    //   ),
                    // ),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.user,
                          color: kWhiteColor,
                          size: 16,
                        ),
                        5.widthBox,
                        Flexible(
                          child: Text(
                            userModel.name ?? 'Administrator',
                            style: const TextStyle(color: white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    10.heightBox,
                    Row(
                      children: [
                        Icon(Icons.tablet_mac, color: kWhiteColor, size: 16),
                        5.widthBox,
                        Flexible(
                          child: Text(
                            posDeviceModel.name ?? '-',
                            style: const TextStyle(color: white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // staff profile picture
              GestureDetector(
                onTap: () async {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) {
                        return AfterLoginScreen(
                          isFromHome: true,
                          tempModel: widget.tempModel,
                        );
                      },
                    ),
                    (Route<dynamic> route) => false,
                  );

                  ref
                      .read(myNavigatorProvider.notifier)
                      .setPageIndex(2, 'pinLock'.tr());

                  ref
                      .read(secondDisplayProvider.notifier)
                      .showMainCustomerDisplay();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: white,
                  ),
                  child: const Icon(FontAwesomeIcons.lock, color: canvasColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
