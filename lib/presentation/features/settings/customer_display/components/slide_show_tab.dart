// import 'dart:io';

// import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:mts/app/theme/app_theme.dart';
// import 'package:mts/core/config/constants.dart';
// import 'package:mts/presentation/common/widgets/button_circle_delete.dart';
// import 'package:mts/presentation/common/widgets/button_primary.dart';

// class SlideShowTab extends StatefulWidget {
//   const SlideShowTab({super.key});

//   @override
//   State<SlideShowTab> createState() => _SlideShowTabState();
// }

// class _SlideShowTabState extends State<SlideShowTab> {
//   late List<DragAndDropList> _contents;
//   int offset = 0;

//   // ignore: prefer_final_fields
//   List<XFile> _selectedImages = [];
//   List<XFile> _imageOrder = [];

//   Future<void> _selectAndUploadImageFromGallery() async {
//     List<XFile>? selectedImages = await selectImagesFromGallery();
//     if (selectedImages != null && selectedImages.isNotEmpty) {
//       setState(() {
//         _selectedImages.addAll(selectedImages);
//         _updateContents();
//         _updateImageOrder();
//       });
//     }
//   }

//   Future<List<XFile>?> selectImagesFromGallery() async {
//     try {
//       FilePickerResult? pickedFiles = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['png', 'jpg', 'jpeg'],
//         allowMultiple: true,
//       );

//       if (pickedFiles != null) {
//         return pickedFiles.files.map((file) => XFile(file.path!)).toList();
//       }
//     } catch (e) {}

//     return null;
//   }

//   void _updateImageOrder() {
//     setState(() {
//       _imageOrder = _selectedImages.map((image) => image).toList();
//     });
//   }

//   void _updateContents() {
//     _contents = [
//       DragAndDropList(
//         header: Column(
//           children: <Widget>[
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Expanded(child: SizedBox()),
//                 Expanded(
//                   flex: 3,
//                   child: Text(
//                     'Pictures',
//                     style: AppTheme.mediumTextStyle(color: kBlackColor),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 Expanded(
//                   child: ButtonPrimary(
//                     onPressed: _selectAndUploadImageFromGallery,
//                     text: 'Add',
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 10.h),
//           ],
//         ),
//         children:
//             _selectedImages.isEmpty
//                 ? [
//                   DragAndDropItem(
//                     child: Row(
//                       children: [
//                         const Expanded(flex: 3, child: SizedBox()),
//                         Expanded(
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 15,
//                               vertical: 25,
//                             ),
//                             decoration: BoxDecoration(
//                               color: kDisabledBg,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: const Center(
//                               child: Icon(
//                                 FontAwesomeIcons.image,
//                                 color: kDisabledText,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const Expanded(flex: 3, child: SizedBox()),
//                       ],
//                     ),
//                   ),
//                 ]
//                 : _selectedImages
//                     .map(
//                       (image) => DragAndDropItem(
//                         child: Padding(
//                           padding: EdgeInsets.symmetric(vertical: 15.h),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: Image(
//                                   width: 200.w,
//                                   height: 200.h,
//                                   fit: BoxFit.fitHeight,
//                                   image: FileImage(File(image.path)),
//                                 ),
//                               ),
//                               ButtonCircleDelete(
//                                 onPressed: () {
//                                   setState(() {
//                                     _selectedImages.remove(image);
//                                     _updateContents();
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     )
//                     .toList(),
//       ),
//     ];
//   }

//   @override
//   void initState() {
//     super.initState();
//     _updateImageOrder();
//     _updateContents();
//   }

//   _onItemReorder(
//     int oldItemIndex,
//     int oldListIndex,
//     int newItemIndex,
//     int newListIndex,
//   ) {
//     setState(() {
//       var movedItem = _contents[oldListIndex].children.removeAt(oldItemIndex);
//       _contents[newListIndex].children.insert(newItemIndex, movedItem);

//       var movedImage = _selectedImages.removeAt(oldItemIndex);
//       _selectedImages.insert(newItemIndex, movedImage);
//       _updateImageOrder();
//     });
//   }

//   _onListReorder(int oldListIndex, int newListIndex) {
//     setState(() {
//       var movedList = _contents.removeAt(oldListIndex);
//       _contents.insert(newListIndex, movedList);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     var backgroundColor = const Color.fromARGB(255, 243, 242, 248);
//     return Column(
//       children: [
//         Expanded(
//           child: DragAndDropLists(
//             children: _contents,
//             onItemReorder: _onItemReorder,
//             onListReorder: _onListReorder,
//             itemDivider: Divider(
//               thickness: 2,
//               height: 2,
//               color: backgroundColor,
//             ),
//             onItemDraggingChanged: (item, dragging) {},
//             itemDecorationWhileDragging: BoxDecoration(
//               color: kDisabledBg,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withValues(alpha: 0.5),
//                   spreadRadius: 2,
//                   blurRadius: 3,
//                   offset: const Offset(0, 0), // changes position of shadow
//                 ),
//               ],
//             ),
//             listInnerDecoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.all(Radius.circular(8.0)),
//             ),
//             lastItemTargetHeight: 8,
//             addLastItemTargetHeightToTop: true,
//             lastListTargetSize: 40,
//             itemDragHandle: const DragHandle(
//               onLeft: true,
//               child: Padding(
//                 padding: EdgeInsets.only(right: 10),
//                 child: Icon(Icons.menu, color: Colors.blueGrey),
//               ),
//             ),
//           ),
//         ),
//         ButtonPrimary(
//           onPressed: () {
//             prints(_imageOrder.map((e) => e.path));
//           },
//           text: 'show images',
//         ),
//       ],
//     );
//   }
// }
