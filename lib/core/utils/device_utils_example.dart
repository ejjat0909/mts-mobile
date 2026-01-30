// import 'package:flutter/material.dart';
// import 'package:mts/core/utils/device_utils.dart';

// /// Example usage of DeviceUtils
// /// This file demonstrates various ways to use the device detection utilities
// class DeviceUtilsExample extends StatelessWidget {
//   const DeviceUtilsExample({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Device Utils Example'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Example 1: Basic device type detection
//             _buildSection(
//               'Basic Device Detection',
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Device Type: ${DeviceUtils.getDeviceTypeName(context)}'),
//                   Text('Is Phone: ${DeviceUtils.isPhone(context)}'),
//                   Text('Is Tablet: ${DeviceUtils.isTablet(context)}'),
//                   Text('Is Web: ${DeviceUtils.isWebOrLargeScreen(context)}'),
//                   Text('Is Mobile: ${DeviceUtils.isMobile(context)}'),
//                   Text('Is Web Platform: ${DeviceUtils.isWeb()}'),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Example 2: Screen size detection
//             _buildSection(
//               'Screen Size Detection',
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Is Small Screen: ${DeviceUtils.isSmallScreen(context)}'),
//                   Text('Is Medium Screen: ${DeviceUtils.isMediumScreen(context)}'),
//                   Text('Is Large Screen: ${DeviceUtils.isLargeScreen(context)}'),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Example 3: Responsive values
//             _buildSection(
//               'Responsive Values',
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Responsive Font Size',
//                     style: TextStyle(
//                       fontSize: DeviceUtils.getResponsiveFontSize(
//                         context,
//                         phoneFontSize: 14.0,
//                         tabletFontSize: 18.0,
//                         webFontSize: 22.0,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     'Grid Columns: ${DeviceUtils.getGridColumns(context)}',
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Example 4: Responsive layout
//             _buildSection(
//               'Responsive Layout',
//               Container(
//                 padding: DeviceUtils.getResponsivePadding(
//                   context,
//                   phonePadding: const EdgeInsets.all(8.0),
//                   tabletPadding: const EdgeInsets.all(16.0),
//                   webPadding: const EdgeInsets.all(24.0),
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade100,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text('This container has responsive padding'),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Example 5: Conditional rendering based on device type
//             _buildSection(
//               'Conditional Rendering',
//               DeviceUtils.isPhone(context)
//                   ? const Text('Phone Layout: Single Column')
//                   : DeviceUtils.isTablet(context)
//                       ? const Text('Tablet Layout: Two Columns')
//                       : const Text('Web Layout: Multiple Columns'),
//             ),

//             const SizedBox(height: 20),

//             // Example 6: Using getResponsiveValue
//             _buildSection(
//               'Custom Responsive Value',
//               Container(
//                 height: DeviceUtils.getResponsiveValue<double>(
//                   context: context,
//                   phone: 100.0,
//                   tablet: 150.0,
//                   web: 200.0,
//                 ),
//                 color: Colors.green.shade200,
//                 child: const Center(
//                   child: Text('Responsive Height Container'),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Example 7: Grid with responsive columns
//             _buildSection(
//               'Responsive Grid',
//               GridView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: DeviceUtils.getGridColumns(
//                     context,
//                     phoneColumns: 2,
//                     tabletColumns: 3,
//                     webColumns: 4,
//                   ),
//                   crossAxisSpacing: 10,
//                   mainAxisSpacing: 10,
//                 ),
//                 itemCount: 8,
//                 itemBuilder: (context, index) {
//                   return Container(
//                     color: Colors.purple.shade200,
//                     child: Center(child: Text('Item ${index + 1}')),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Example 8: Check size without context
//             _buildSection(
//               'Size Check Without Context',
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Is 500x800 a phone? ${DeviceUtils.isPhoneSize(500, 800)}'),
//                   Text('Is 700x1000 a tablet? ${DeviceUtils.isTabletSize(700, 1000)}'),
//                   Text('Is 1200x800 web? ${DeviceUtils.isWebSize(1200, 800)}'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSection(String title, Widget content) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 10),
//         content,
//       ],
//     );
//   }
// }

// /// Example: Using DeviceUtils in a custom widget
// class ResponsiveCard extends StatelessWidget {
//   final String title;
//   final String content;

//   const ResponsiveCard({
//     super.key,
//     required this.title,
//     required this.content,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: DeviceUtils.getResponsivePadding(
//         context,
//         phonePadding: const EdgeInsets.all(8.0),
//         tabletPadding: const EdgeInsets.all(12.0),
//         webPadding: const EdgeInsets.all(16.0),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: DeviceUtils.getResponsiveFontSize(
//                   context,
//                   phoneFontSize: 16.0,
//                   tabletFontSize: 20.0,
//                   webFontSize: 24.0,
//                 ),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               content,
//               style: TextStyle(
//                 fontSize: DeviceUtils.getResponsiveFontSize(
//                   context,
//                   phoneFontSize: 14.0,
//                   tabletFontSize: 16.0,
//                   webFontSize: 18.0,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Example: Responsive layout builder
// class ResponsiveLayout extends StatelessWidget {
//   final Widget phone;
//   final Widget tablet;
//   final Widget web;

//   const ResponsiveLayout({
//     super.key,
//     required this.phone,
//     required this.tablet,
//     required this.web,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final deviceType = DeviceUtils.getDeviceType(context);

//     switch (deviceType) {
//       case DeviceType.phone:
//         return phone;
//       case DeviceType.tablet:
//         return tablet;
//       case DeviceType.web:
//         return web;
//     }
//   }
// }
