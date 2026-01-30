import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/domain/services/media/asset_download_service.dart';
import 'package:mts/providers/downloaded_file/downloaded_file_providers.dart';
import 'package:mts/providers/receipt_settings/receipt_settings_providers.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/layouts/invalid_image_container.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class ReceiptLogo extends ConsumerStatefulWidget {
  const ReceiptLogo({super.key});

  @override
  ConsumerState<ReceiptLogo> createState() => _ReceiptLogoState();
}

class _ReceiptLogoState extends ConsumerState<ReceiptLogo> {
  bool isPrintReceipt = false;
  bool isEmailedReceipt = false;
  ReceiptSettingsModel rsm = ReceiptSettingsModel();

  File? filePrintedLogo;
  File? fileEmailedLogo;

  @override
  void initState() {
    super.initState();
    getLatestReceiptSettings();
  }

  Future<void> getLatestReceiptSettings() async {
    List<ReceiptSettingsModel> listRSM =
        await ref
            .read(receiptSettingsProvider.notifier)
            .getListReceiptSettings();

    if (listRSM.isNotEmpty) {
      rsm = listRSM.last;
      if (rsm.printLogoUrl != null) {
        String printedPath = await ref
            .read(downloadedFileProvider.notifier)
            .getImagePath(rsm.printLogoUrl);
        filePrintedLogo = File(printedPath);
      }
      if (rsm.emailLogoUrl != null) {
        String emailedPath = await ref
            .read(downloadedFileProvider.notifier)
            .getImagePath(rsm.emailLogoUrl);
        fileEmailedLogo = File(emailedPath);

        //  fileEmailedLogo = File(rsm.emailedLogo!);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(flex: 5, child: SizedBox()),
              Expanded(
                child: ButtonTertiary(
                  onPressed: () async {
                    await handleOnSync();
                  },
                  text: 'sync'.tr(),
                  icon: FontAwesomeIcons.arrowsRotate,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: printedReceiptSwitch()),
              Expanded(child: emailedReceiptSwitch()),
            ],
          ),
          const Space(10),
          Row(
            children: [
              imageLogo(filePrintedLogo),
              SizedBox(width: 20.w),
              imageLogo(fileEmailedLogo),
            ],
          ),
          const Space(10),
          companyName(),
          const Space(10),
          outletName(),
          const Space(10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [header(), SizedBox(width: 20.w), footer()],
          ),
          //SizedBox(height: 30.h),
          // ImageUpload(
          //   onImageSelected: (xfile) {
          //   },
          // ),
          // SizedBox(height: 30.h),

          // SizedBox(height: 30.h),
          // ImageUpload(
          //   onImageSelected: (xfile) {},
          // ),
        ],
      ),
    );
  }

  Column outletName() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('outletName'.tr(), style: AppTheme.normalTextStyle(fontSize: 16)),
        const Space(10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(7.5),
            border: Border.all(width: 0.5, color: kTextGray),
            // boxShadow: UIUtils.itemShadows,
          ),
          child: Text(rsm.outletName ?? '', style: AppTheme.grayTextStyle()),
        ),
      ],
    );
  }

  Column companyName() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('companyName'.tr(), style: AppTheme.normalTextStyle(fontSize: 16)),
        const Space(10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(7.5),
            border: Border.all(width: 0.5, color: kTextGray),
            // boxShadow: UIUtils.itemShadows,
          ),
          child: Text(rsm.companyName ?? '', style: AppTheme.grayTextStyle()),
        ),
      ],
    );
  }

  Widget header() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('header'.tr(), style: AppTheme.normalTextStyle(fontSize: 16)),
          const Space(10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(7.5),
              border: Border.all(width: 0.5, color: kTextGray),
              // boxShadow: UIUtils.itemShadows,
            ),
            child: Text(rsm.header ?? '', style: AppTheme.grayTextStyle()),
          ),
        ],
      ),
    );
  }

  Widget footer() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('footer'.tr(), style: AppTheme.normalTextStyle(fontSize: 16)),
          const Space(10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(7.5),
              border: Border.all(width: 0.5, color: kTextGray),
              // boxShadow: UIUtils.itemShadows,
            ),
            child: Text(rsm.footer ?? '', style: AppTheme.grayTextStyle()),
          ),
        ],
      ),
    );
  }

  Widget imageLogo(File? filePath) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: kTextGray.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7.5),
          // boxShadow: UIUtils.itemShadows,
        ),
        child: FutureBuilder(
          future: loadLogo(filePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: InvalidImageContainer(forMenuItem: false)),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: InvalidImageContainer(
                    forMenuItem: false,
                    text: 'noImage'.tr(),
                  ),
                ),
              );
            } else {
              Uint8List? imageData = snapshot.data;
              if (imageData != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(7.5),
                  child: Image.memory(
                    imageData,
                    fit: BoxFit.fitWidth,
                    errorBuilder: (context, error, stackTrace) {
                      prints('Error loading logo image: $error');
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: InvalidImageContainer(forMenuItem: false),
                        ),
                      ); // Handle any loading errors
                    },
                  ),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: InvalidImageContainer(forMenuItem: false),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Row printedReceiptSwitch() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: scaffoldBackgroundColor,
          ),
          child: const Icon(FontAwesomeIcons.print, color: kPrimaryColor),
        ),
        SizedBox(width: 20.w),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'printedReceipts'.tr(),
                style: AppTheme.normalTextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              Text('printedReceiptsDesc'.tr(), style: AppTheme.grayTextStyle()),
            ],
          ),
        ),
        // client minta buang
        // Expanded(
        //   child: CustomSwitch(
        //     value: isPrintReceipt,
        //     onChanged: (value) {
        //       setState(() {
        //         isPrintReceipt = value;
        //       });
        //     },
        //   ),
        // )
      ],
    );
  }

  Row emailedReceiptSwitch() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: scaffoldBackgroundColor,
          ),
          child: const Icon(FontAwesomeIcons.envelope, color: kPrimaryColor),
        ),
        SizedBox(width: 20.w),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'emailedReceipts'.tr(),
                style: AppTheme.normalTextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              Text('emailedReceiptsDesc'.tr(), style: AppTheme.grayTextStyle()),
            ],
          ),
        ),
        // Expanded(
        //   child: CustomSwitch(
        //     value: isEmailedReceipt,
        //     onChanged: (value) {
        //       setState(() {
        //         isEmailedReceipt = value;
        //       });
        //     },
        //   ),
        // )
      ],
    );
  }

  Future<Uint8List?> loadLogo(File? file) async {
    if (file != null) {
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<void> handleOnSync() async {
    // Check if widget is still mounted before proceeding with async operations

    List<ReceiptSettingsModel> listRsm =
        await ref
            .read(receiptSettingsProvider.notifier)
            .getListReceiptSettings();
    rsm = listRsm.isNotEmpty ? listRsm.last : ReceiptSettingsModel();
    if (rsm.id == null) {
      if (mounted) {
        ThemeSnackBar.showSnackBar(context, 'noDataFromBackOffice'.tr());
      }
      return;
    }

    // Check again after the second async operation
    if (!mounted) return;

    final assetService = ref.read(assetDownloadServiceProvider);
    await assetService.downloadPendingAssets();

    // Get downloaded files after download completes
    final dfmPrinted = await ref
        .read(downloadedFileProvider.notifier)
        .getDownloadedFileByUrl(rsm.printLogoUrl ?? "");

    if (dfmPrinted != null) {
      filePrintedLogo = File(dfmPrinted.path!);
    } else {
      filePrintedLogo = null;
    }

    // get downloaded file for emailed logo based on url from rsm where isDownloaded = true, and path not null
    final dfmEmailed = await ref
        .read(downloadedFileProvider.notifier)
        .getDownloadedFileByUrl(rsm.emailLogoUrl ?? "");

    if (dfmEmailed != null) {
      fileEmailedLogo = File(dfmEmailed.path!);
    } else {
      fileEmailedLogo = null;
    }

    // Final check before calling setState
    if (mounted) {
      setState(() {});
    }
  }
}
