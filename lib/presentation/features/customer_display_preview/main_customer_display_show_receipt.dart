import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/plugins/presentation_displays/secondary_display.dart';
import 'package:mts/presentation/common/layouts/customer_card_display.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/customer_display_preview/customer_receipt_table.dart';
import 'package:mts/presentation/features/customer_display_preview/feedback_table.dart';

class CustomerShowReceipt extends StatefulWidget {
  static const routeName = '/customer_display/customer_show_receipt';

  const CustomerShowReceipt({super.key});

  @override
  State<CustomerShowReceipt> createState() => _CustomerShowReceiptState();
}

class _CustomerShowReceiptState extends State<CustomerShowReceipt> {
  String screenData = '';
  String tableName = '';
  List<String> imgList = [];
  String? qrCodeUrl;
  Map<Object?, Object?>? acceptedData;

  @override
  Widget build(BuildContext context) {
    // acceptedData = acceptedData;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.blue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // hides back button
      ),
      body: SecondaryDisplay(
        callback: (data) {
          acceptedData = data;
          // imgList = getImageUrls();
          // callqr code
          qrCodeUrl = getQrCodePath();
          // Safely cast to Map<String, dynamic>
          final map =
              acceptedData == null
                  ? null
                  : Map.fromEntries(
                    acceptedData!.entries
                        .where((e) => e.key is String)
                        .map((e) => MapEntry(e.key as String, e.value)),
                  );

          tableName = map?['tableName']?.toString() ?? '';
          setState(() {});
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/customerBackground.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: buildImage()),
              Expanded(child: buildReceipt(tableName)),
            ],
          ),
        ),
      ),
    );
  }

  // Widget? imageSliders(String? url) {
  //   if (url == null) return null;
  //   String qrCodeUrls = url;
  //   return Container(
  //     margin: const EdgeInsets.all(5),
  //     child: ClipRRect(
  //       borderRadius: const BorderRadius.all(Radius.circular(10)),
  //       child: AspectRatio(
  //         aspectRatio: 1,
  //         child: Image.network(qrCodeUrls, fit: BoxFit.fill),
  //       ),
  //     ),
  //   );
  // }

  //customer display section
  Widget buildImage() {
    // prints("IMAGE URL $imgList");
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.w),
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              getTitle(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 40.sp,
                decoration: TextDecoration.none,
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.normal,
              ),
            ),
            Divider(
              color: Colors.white,
              indent: 100.w,
              endIndent: 100.w,
              thickness: 1.h,
              height: 50.w,
            ),
            //qrcode image
            qrCodeUrl == null
                ? SizedBox.shrink()
                : ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: qrCodeUrl!,
                    width: MediaQuery.of(context).size.width / 3,
                    // height: MediaQuery.of(context).size.height / 1.5,
                    fit: BoxFit.fitWidth,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) => const Icon(Icons.error),
                  ),
                ),
            // tutup sebab mohsin kata tak perlu, nak show image besar
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children:
            //       imgList.asMap().entries.map((entry) {
            //         return GestureDetector(
            //           onTap: () => _controller.animateToPage(entry.key),
            //           child: Container(
            //             width: 12.0.w,
            //             height: 12.0.w,
            //             margin: EdgeInsets.symmetric(
            //               vertical: 8.0.w,
            //               horizontal: 4.0.w,
            //             ),
            //             decoration: BoxDecoration(
            //               shape: BoxShape.circle,
            //               color: (Theme.of(context).brightness ==
            //                           Brightness.dark
            //                       ? Colors.white
            //                       : Colors.black)
            //                   .withValues(alpha: _current == entry.key ? 0.9 : 0.4),
            //             ),
            //           ),
            //         );
            //       }).toList(),
            // ),
            Padding(
              padding: EdgeInsets.all(8.0.w),
              child: Column(
                children: [
                  Space(10),
                  Text(
                    getUserModel(),
                    style: TextStyle(
                      fontSize: 20.w,
                      decoration: TextDecoration.none,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Space(10),
                  Text(
                    // 'NICE TO MEET YOU',
                    getGreeting(),
                    style: TextStyle(
                      fontSize: 20.w,
                      decoration: TextDecoration.none,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Space(10),
                  Text(
                    // 'mysztech.com',
                    getPromotionLink(),
                    style: TextStyle(
                      fontSize: 20.w,
                      decoration: TextDecoration.none,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getUserModel() {
    if (acceptedData == null) return 'No user';

    // Convert keys to String
    final map = Map.fromEntries(
      acceptedData!.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );

    final userData = map[DataEnum.userModel];
    if (userData is Map) {
      final json = Map<String, dynamic>.from(userData);
      final userModel = UserModel.fromJson(json);
      final name = userModel.name?.toUpperCase();
      return name != null ? "HI I'M $name" : 'No user';
    }

    return 'No user';
  }

  String getTitle() {
    if (acceptedData == null) return '';

    // Safely convert acceptedData to Map<String, dynamic>
    final map = Map.fromEntries(
      acceptedData!.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );

    final slideshowData = map[DataEnum.slideshow];
    if (slideshowData is Map) {
      final json = Map<String, dynamic>.from(slideshowData);
      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.title ?? '';
    }

    return '';
  }

  String getGreeting() {
    if (acceptedData == null) return '';

    // Safely convert acceptedData to Map<String, dynamic>
    final map = Map.fromEntries(
      acceptedData!.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );

    final slideshowData = map[DataEnum.slideshow];
    if (slideshowData is Map) {
      final json = Map<String, dynamic>.from(slideshowData);
      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.greetings ?? '';
    }

    return '';
  }

  String getPromotionLink() {
    if (acceptedData == null) return '';

    // Safely convert acceptedData to Map<String, dynamic>
    final map = Map.fromEntries(
      acceptedData!.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );

    final slideshowData = map[DataEnum.slideshow];
    if (slideshowData is Map) {
      final json = Map<String, dynamic>.from(slideshowData);
      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.promotionlink ?? '';
    }

    return '';
  }

  //receipt section
  Widget buildReceipt(String? tableName) {
    SaleModel? saleModel;
    bool showThankYou = false;

    if (acceptedData != null) {
      // Safely convert acceptedData to Map<String, dynamic>
      final map = Map.fromEntries(
        acceptedData!.entries
            .where((e) => e.key is String)
            .map((e) => MapEntry(e.key as String, e.value)),
      );

      // Handle 'saleModel' key and ensure it's a Map<String, dynamic>
      final saleData = map['saleModel'];
      if (saleData != null && saleData is Map<String, dynamic>) {
        saleModel = SaleModel.fromJson(saleData);
      }

      // Handle 'showThankYou' key
      final showThankYouData = map[DataEnum.showThankYou];
      if (showThankYouData is bool) {
        showThankYou = showThankYouData;
      }
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.w),
      color: Colors.transparent,
      child: CustomCard(
        title: !showThankYou ? 'orderDetails'.tr() : null,
        secondTitle:
            !showThankYou
                ? "${saleModel != null ? saleModel.name ?? '' : ''} ${tableName != '' ? '- $tableName' : ''}"
                : null,
        body:
            !showThankYou
                ? CustomerReceiptTable(acceptedData: acceptedData)
                : FeedbackTable(acceptedData: acceptedData),
      ),
    );
  }

  Map<String, dynamic>? castToStringKeyedMap(Map<Object?, Object?>? rawMap) {
    if (rawMap == null) return null;

    return Map.fromEntries(
      rawMap.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );
  }

  List<String> getImageUrls() {
    final map = castToStringKeyedMap(acceptedData);
    final slideshowData = map?[DataEnum.slideshow];
    if (slideshowData != null) {
      final json =
          slideshowData is Map
              ? Map<String, dynamic>.from(slideshowData)
              : <String, dynamic>{};

      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.downloadUrls ?? [];
    }
    return [];
  }

  // get qr code path
  String? getQrCodePath() {
    final map = castToStringKeyedMap(acceptedData);
    final slideshowData = map?[DataEnum.slideshow];
    if (slideshowData != null) {
      final json =
          slideshowData is Map
              ? Map<String, dynamic>.from(slideshowData)
              : <String, dynamic>{};

      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.qrPaymentUrl;
    }
    return null;
  }
}
