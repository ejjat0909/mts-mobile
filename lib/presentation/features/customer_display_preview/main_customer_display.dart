import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/plugins/presentation_displays/secondary_display.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class MainCustomerDisplay extends StatefulWidget {
  static const routeName = '/customer_display/main_customer_display';

  const MainCustomerDisplay({super.key});

  @override
  State<MainCustomerDisplay> createState() => _MainCustomerDisplayState();
}

class _MainCustomerDisplayState extends State<MainCustomerDisplay> {
  String screenData = '';
  List<String> imgList = [];

  Map<Object?, Object?>? acceptedData;
  // Initialize controller in initState to avoid late initialization error
  late final CarouselSliderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        //main customer display show receipt
      ),
      body: SecondaryDisplay(
        callback: (dynamic data) {
          try {
            prints(data.runtimeType);
            acceptedData = data;
            imgList = getImageUrls();
            // prints(screenData is Map<String, dynamic>);
            // if (screenData.isNotEmpty) {
            //   acceptedData = jsonDecode(screenData);
            // }
            setState(() {});
          } catch (e) {
            prints('Error parsing data: $e');
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/customerBackground.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Space(20.h),
              Text(
                getTitle(),
                style: TextStyle(
                  fontSize: 50.w,
                  decoration: TextDecoration.none,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.normal,
                ),
              ),
              Divider(
                color: Colors.white,
                indent: 250.w,
                endIndent: 250.w,
                thickness: 1.h,
                height: 50.h,
              ),
              Text(
                getGreeting(),
                style: TextStyle(
                  fontSize: 30.w,
                  decoration: TextDecoration.none,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.normal,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.w),
                child: Text(
                  getDescription(),
                  style: TextStyle(
                    fontSize: 20.w,
                    decoration: TextDecoration.none,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              Space(10.h),
              //image slider
              Expanded(
                child: CarouselSlider(
                  items: imageSliders(imgList),
                  carouselController: _controller,
                  options: CarouselOptions(
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    onPageChanged: (index, reason) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              //slider indicators
              // tutup sebab mohsin kata tak perlu, nak show image besar
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children:
              //       imgList.asMap().entries.map((entry) {
              //         return GestureDetector(
              //           onTap: () => _controller.animateToPage(entry.key),
              //           child: Container(
              //             width: 10.0.w,
              //             height: 10.0.w,
              //             margin: EdgeInsets.symmetric(
              //               vertical: 2.0.w,
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
              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget>? imageSliders(List<String> listUrls) {
    return listUrls
        .map(
          (item) => ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            child: CachedNetworkImage(
              imageUrl: item,
              width: MediaQuery.of(context).size.width / 1.25,
              fit: BoxFit.fill,
              placeholder:
                  (context, url) =>
                      const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        )
        .toList();
  }

  Map<String, dynamic>? castToStringKeyedMap(Map<Object?, Object?>? rawMap) {
    if (rawMap == null) return null;

    return Map.fromEntries(
      rawMap.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );
  }

  String getTitle() {
    final map = castToStringKeyedMap(acceptedData);
    final slideshowData = map?[DataEnum.slideshow];

    if (slideshowData != null) {
      final json =
          slideshowData is Map
              ? Map<String, dynamic>.from(slideshowData)
              : <String, dynamic>{};

      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.title ?? '';
    }
    return '';
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

  String getGreeting() {
    final map = castToStringKeyedMap(acceptedData);
    final slideshowData = map?[DataEnum.slideshow];

    if (slideshowData != null) {
      final json =
          slideshowData is Map
              ? Map<String, dynamic>.from(slideshowData)
              : <String, dynamic>{};

      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.greetings ?? '';
    }
    return '';
  }

  String getDescription() {
    final map = castToStringKeyedMap(acceptedData);
    final slideshowData = map?[DataEnum.slideshow];

    if (slideshowData != null) {
      final json =
          slideshowData is Map
              ? Map<String, dynamic>.from(slideshowData)
              : <String, dynamic>{};

      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.description ?? '';
    }
    return '';
  }
}
