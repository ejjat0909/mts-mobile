// import 'dart:io';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:mts/core/config/constants.dart';
// import 'package:mts/presentation/common/widgets/button_primary.dart';
// import 'package:mts/presentation/common/widgets/space.dart';
// import 'package:sqlite_viewer2/sqlite_viewer.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart'
//     as webview_android;

// class BackOfficeScreen extends StatefulWidget {
//   const BackOfficeScreen({super.key});

//   @override
//   State<BackOfficeScreen> createState() => _BackOfficeScreenState();
// }

// class _BackOfficeScreenState extends State<BackOfficeScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controllerColor;
//   late Animation<Color?> _colorAnimation;

//   late final WebViewController _controller;
//   bool isFinishLoading = false;
//   bool isFailToLoad = false;
//   int percent = 0;
//   Uri? uri;

//   @override
//   void initState() {
//     super.initState();
//     uri = getUrl();
//     handleColorAnimation();

//     if (uri != null) {
//       _controller =
//           WebViewController()
//             ..setJavaScriptMode(JavaScriptMode.unrestricted)
//             ..setBackgroundColor(const Color(0x00000000))
//             ..setNavigationDelegate(
//               NavigationDelegate(
//                 onProgress: (int progress) {
//                   setState(() {
//                     percent = progress;
//                     if (progress != 100) {
//                       isFinishLoading = false;
//                     } else {
//                       isFinishLoading = true;
//                     }
//                   });
//                 },
//                 onPageStarted: (String url) {},
//                 onPageFinished: (String url) {},
//                 onWebResourceError: (WebResourceError error) {
//                   setState(() {
//                     isFailToLoad = true;
//                   });
//                 },
//               ),
//             )
//             ..loadRequest(
//               uri!,
//               headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
//             );

//       _setupFilePicker();
//     } else {
//       setState(() {
//         isFailToLoad = true;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _controllerColor.dispose(); // Dispose of the AnimationController
//     super.dispose();
//   }

//   void handleColorAnimation() {
//     // Create the AnimationController
//     _controllerColor = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true); // Repeats the animation forward and backward

//     // Create a ColorTween and bind it to the controller
//     _colorAnimation = ColorTween(
//       begin: Colors.blue,
//       end: Colors.green,
//     ).animate(_controllerColor);
//   }

//   Uri? getUrl() {
//     return Uri.tryParse(originUrl);
//   }

//   /// [for file picker]

//   void _setupFilePicker() {
//     if (Platform.isAndroid) {
//       final controller =
//           _controller.platform as webview_android.AndroidWebViewController;
//       controller.setOnShowFileSelector(_androidFilePicker);
//     } else if (Platform.isIOS) {
//       _injectJavaScriptForFilePicker();
//     }
//   }

//   Future<List<String>> _androidFilePicker(
//     webview_android.FileSelectorParams params,
//   ) async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         allowMultiple:
//             params.mode == webview_android.FileSelectorMode.openMultiple,
//       );

//       if (result == null) return [];
//       return result.files
//           .where((file) => file.path != null)
//           .map((file) => File(file.path!).uri.toString())
//           .toList();
//     } catch (e) {
//       return [];
//     }
//   }

//   void _injectJavaScriptForFilePicker() {
//     String jsCode = '''
//       document.addEventListener('click', function(event) {
//         let target = event.target;
//         if (target.tagName === 'INPUT' && target.type === 'file') {
//           window.flutter_inappwebview.callHandler('iosFilePicker');
//           event.preventDefault();
//         }
//       });
//     ''';

//     _controller.runJavaScript(jsCode);

//     _controller.addJavaScriptChannel(
//       'flutter_inappwebview',
//       onMessageReceived: (JavaScriptMessage message) async {
//         if (message.message == 'iosFilePicker') {
//           FilePickerResult? result = await FilePicker.platform.pickFiles();
//           if (result != null && result.files.single.path != null) {
//             String filePath = result.files.single.path!;
//             _controller.runJavaScript(
//               'document.querySelector("input[type=file]").value = "$filePath";',
//             );
//           }
//         }
//       },
//     );
//   }

//   Future<Map<String, bool>> checkingNavigation() async {
//     final canGoBack = await _controller.canGoBack();
//     final canGoForward = await _controller.canGoForward();

//     return {'canGoBack': canGoBack, 'canGoForward': canGoForward};
//   }

//   Future<void> _goForward() async {
//     if (await _controller.canGoForward()) {
//       await _controller.goForward();
//     }
//   }

//   Future<void> _goBack() async {
//     if (await _controller.canGoBack()) {
//       await _controller.goBack();
//     }
//   }

//   // Future<void> _goBackToGivenUrl() async {
//   //   String targetUrl = originUrl;

//   //   // Keep navigating back until the current URL matches the target URL or there's no more history
//   //   while (await _controller.canGoBack()) {
//   //     final currentUrl = await _controller.currentUrl();
//   //     if (currentUrl == targetUrl) {
//   //       break; // Stop if we reach the target URL
//   //     }
//   //     await _controller.goBack();
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         kDebugMode
//             ? ButtonPrimary(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const DatabaseList()),
//                 );
//               },
//               text: 'go to local db',
//             )
//             : Expanded(
//               child: Scaffold(
//                 //   backgroundColor: ShadTheme.of(context).colorScheme.primary,
//                 appBar: AppBar(
//                   backgroundColor: kPrimaryBgColor.withValues(alpha: 0),
//                   leadingWidth: 100,
//                   elevation: 0,
//                   leading: Row(
//                     children: [
//                       FutureBuilder(
//                         future: checkingNavigation(),
//                         builder: (context, snapshot) {
//                           bool canGoBack = snapshot.data?['canGoBack'] ?? false;
//                           return IconButton(
//                             splashColor: Colors.transparent,
//                             highlightColor: Colors.transparent,
//                             hoverColor: Colors.transparent,
//                             icon: const Icon(FontAwesomeIcons.arrowLeft),
//                             color: canGoBack ? Colors.black : Colors.grey,
//                             onPressed: _goBack,
//                           );
//                         },
//                       ),

//                       // IconButton(
//                       //   splashColor: Colors.transparent,
//                       //   highlightColor: Colors.transparent,
//                       //   hoverColor: Colors.transparent,
//                       //   icon: Icon(
//                       //     FontAwesomeIcons.powerOff,
//                       //   ),
//                       //   color: kTextRed,
//                       //   onPressed: () async {
//                       //     await goHome(context);
//                       //   },
//                       // ),
//                     ],
//                   ),
//                   // title: Image.network(
//                   //   UrlContainer.appBarImageUrl, // Replace with your image URL
//                   //   height: 30.0,
//                   //   errorBuilder: (BuildContext context, Object error,
//                   //       StackTrace? stackTrace) {
//                   //     return const Text(
//                   //       'Doffis', // Fallback text
//                   //       style: TextStyle(color: Colors.black),
//                   //     );
//                   //   },
//                   // ),
//                   centerTitle: true,
//                   actions: [
//                     FutureBuilder(
//                       future: checkingNavigation(),
//                       builder: (context, snapshot) {
//                         bool canGoForward =
//                             snapshot.data?['canGoForward'] ?? false;
//                         return IconButton(
//                           icon: const Icon(FontAwesomeIcons.arrowRight),
//                           splashColor: Colors.transparent,
//                           highlightColor: Colors.transparent,
//                           hoverColor: Colors.transparent,
//                           color: canGoForward ? Colors.black : Colors.grey,
//                           onPressed: _goForward,
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//                 body: body(),
//               ),
//             ),
//       ],
//     );
//   }

//   Widget body() {
//     if (isFinishLoading) {
//       return WebViewWidget(controller: _controller);
//     } else if (isFailToLoad) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               FontAwesomeIcons.circleExclamation,
//               color: Colors.blue,
//               size: 30,
//             ),
//             Text(
//               'Failed to load live chat',
//               style: TextStyle(color: Colors.blue),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return Center(
//         child: AnimatedBuilder(
//           animation: _colorAnimation,
//           builder: (context, child) {
//             return Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(
//                   color: Colors.blue,
//                   value: percent / 100,
//                   valueColor: _colorAnimation,
//                 ),
//                 Space(10.h),
//                 Text(
//                   'Loading $percent%',
//                   style: TextStyle(color: _colorAnimation.value),
//                 ),
//               ],
//             );
//           },
//         ),
//       );
//     }
//   }
// }
