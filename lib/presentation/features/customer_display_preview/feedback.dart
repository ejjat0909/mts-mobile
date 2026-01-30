// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:mts/presentation/common/layouts/customer_card_display.dart';

// class CustomerFeedback extends StatefulWidget {
//   static const routeName = '/customer_display/customer_feedback';

//   const CustomerFeedback({super.key});

//   @override
//   State<CustomerFeedback> createState() => _CustomerFeedbackState();
// }

// class _CustomerFeedbackState extends State<CustomerFeedback> {
//   int _current = 0;
//   final CarouselSliderController _controller = CarouselSliderController();
//   List<String> imgList = [];
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         automaticallyImplyLeading: false,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/images/customerBackground.png'),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Row(
//           children: [
//             Expanded(child: buildImage()),
//             Expanded(child: buildReceipt()),
//           ],
//         ),
//       ),
//     );
//   }

//   List<Widget>? imageSliders(List<String> urls) {
//     return urls
//         .map(
//           (item) => Container(
//             margin: const EdgeInsets.all(5),
//             child: ClipRRect(
//               borderRadius: const BorderRadius.all(Radius.circular(10)),
//               child: Stack(
//                 children: <Widget>[
//                   AspectRatio(
//                     aspectRatio: 16 / 9,
//                     child: Image.network(
//                       item,
//                       fit: BoxFit.fill,
//                       width: 600,
//                       height: 400,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         )
//         .toList();
//   }

//   //customer display section
//   Widget buildImage() => Container(
//     margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.w),
//     padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.w),
//     color: Colors.transparent,
//     child: SingleChildScrollView(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             'Cafe XYZ',
//             style: TextStyle(
//               fontSize: 50.w,
//               decoration: TextDecoration.none,
//               color: Colors.white,
//               fontFamily: 'Poppins',
//               fontWeight: FontWeight.normal,
//             ),
//           ),
//           Divider(
//             color: Colors.white,
//             indent: 100.w,
//             endIndent: 100.w,
//             thickness: 1,
//             height: 50.h,
//           ),
//           //image slider
//           SizedBox(
//             height: 200.h,
//             child: Column(
//               children: [
//                 CarouselSlider(
//                   items: imageSliders(imgList),
//                   carouselController: _controller,
//                   options: CarouselOptions(
//                     autoPlay: true,
//                     viewportFraction: 1,
//                     enlargeCenterPage: true,
//                     aspectRatio: 2,
//                     onPageChanged: (index, reason) {
//                       setState(() {
//                         _current = index;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children:
//                 imgList.asMap().entries.map((entry) {
//                   return GestureDetector(
//                     onTap: () => _controller.animateToPage(entry.key),
//                     child: Container(
//                       width: 12.0.w,
//                       height: 12.0.w,
//                       margin: EdgeInsets.symmetric(
//                         vertical: 8.0.w,
//                         horizontal: 4.0.w,
//                       ),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: (Theme.of(context).brightness == Brightness.dark
//                                 ? Colors.white
//                                 : Colors.black)
//                             .withValues(alpha: _current == entry.key ? 0.9 : 0.4),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//           ),
//           Padding(
//             padding: EdgeInsets.all(8.0.w),
//             child: Column(
//               children: [
//                 Text(
//                   "HI I'M ALI",
//                   style: TextStyle(
//                     fontSize: 20.w,
//                     decoration: TextDecoration.none,
//                     color: Colors.white,
//                     fontFamily: 'Poppins',
//                     fontWeight: FontWeight.normal,
//                   ),
//                 ),
//                 Text(
//                   'NICE TO MEET YOU',
//                   style: TextStyle(
//                     fontSize: 20.w,
//                     decoration: TextDecoration.none,
//                     color: Colors.white,
//                     fontFamily: 'Poppins',
//                     fontWeight: FontWeight.normal,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );

//   //receipt section
//   Widget buildReceipt() => Container(
//     padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.w),
//     color: Colors.transparent,
//     child: CustomCard(body: Container()),
//   );
// }
