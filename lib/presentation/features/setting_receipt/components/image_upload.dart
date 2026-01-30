// import 'dart:io';

// import 'package:easy_localization/easy_localization.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_scale_tap/flutter_scale_tap.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mts/app/theme/app_theme.dart';
// import 'package:mts/core/config/constants.dart';
// import 'package:open_filex/open_filex.dart';

// class ImageUpload extends StatefulWidget {
//   final Function(XFile) onImageSelected;

//   const ImageUpload({super.key, required this.onImageSelected});

//   @override
//   State<ImageUpload> createState() => _ImageUploadState();
// }

// class _ImageUploadState extends State<ImageUpload> {
//   XFile? _selectedImage;

//   @override
//   void initState() {
//     super.initState();
//   }

//   Future<void> _selectAndUploadImageFromCamera() async {
//     List<XFile>? selectedImages = await selectImagesFromCamera();
//     if (selectedImages != null && selectedImages.isNotEmpty) {
//       setImageToCircle(selectedImages[0], widget.onImageSelected);
//     }
//   }

//   Future<void> _selectAndUploadImageFromGallery() async {
//     List<XFile>? selectedImages = await selectImagesFromGallery();
//     if (selectedImages != null && selectedImages.isNotEmpty) {
//       setImageToCircle(selectedImages[0], widget.onImageSelected);
//     }
//   }

//   Future<List<XFile>?> selectImagesFromCamera() async {
//     try {
//       final pickedFile = await ImagePicker().pickImage(
//         source: ImageSource.camera,
//       );

//       if (pickedFile != null) {
//         return [XFile(pickedFile.path)];
//       }
//     } catch (e) {}

//     return null;
//   }

//   Future<List<XFile>?> selectImagesFromGallery() async {
//     try {
//       FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['png', 'jpg', 'jpeg'],
//       );

//       if (pickedFile != null) {
//         return [XFile(pickedFile.files.single.path!)];
//       }
//     } catch (e) {}

//     return null;
//   }

//   void setImageToCircle(
//     XFile selectedImage,
//     Function(XFile) onImageSelected,
//   ) async {
//     String imagePath = selectedImage.path;

//     setState(() {
//       _selectedImage = selectedImage;
//       onImageSelected(selectedImage);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           child: Column(
//             children: [
//               ScaleTap(
//                 onPressed:
//                     _selectedImage != null
//                         ? () async {
//                           await OpenFilex.open(_selectedImage!.path);
//                           return [XFile(_selectedImage!.path)];
//                         }
//                         : null,
//                 child: Container(
//                   height: 200.h,
//                   width: 200.w,
//                   decoration: const BoxDecoration(
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(7),
//                       topRight: Radius.circular(7),
//                     ),
//                     color: kDisabledBg,
//                   ),
//                   child:
//                       _selectedImage != null
//                           ? Image(
//                             width: double.infinity,
//                             height: 200.h,
//                             fit: BoxFit.fitHeight,
//                             image: FileImage(File(_selectedImage!.path)),
//                           )
//                           : const Center(
//                             child: Icon(
//                               FontAwesomeIcons.image,
//                               color: kDisabledText,
//                             ),
//                           ),
//                 ),
//               ),
//               ScaleTap(
//                 onPressed: () {
                 
//                   _selectAndUploadImageFromGallery();
//                 },
//                 child: Container(
//                   width: 200.w,
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 5,
//                     horizontal: 15,
//                   ),
//                   decoration: const BoxDecoration(
//                     borderRadius: BorderRadius.only(
//                       bottomLeft: Radius.circular(7),
//                       bottomRight: Radius.circular(7),
//                     ),
//                     color: kPrimaryColor,
//                   ),
//                   child: Text(
//                     'upload'.tr(),
//                     style: AppTheme.mediumTextStyle(color: white),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Positioned(
//           top: 0.h,
//           right: 0.w,
//           child:
//               _selectedImage != null
//                   ? ScaleTap(
//                     onPressed: () {
//                       setState(() {
//                         _selectedImage = null;
//                       });
//                     },
//                     child: const Icon(
//                       FontAwesomeIcons.solidCircleXmark,
//                       color: Colors.red,
//                     ),
//                   )
//                   : const SizedBox(),
//         ),
//       ],
//     );
//   }
// }

// class UploadEmailedReceiptImage extends StatelessWidget {
//   const UploadEmailedReceiptImage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Stack(
//           children: [
//             Container(
//               height: 200.h,
//               width: 200.w,
//               padding: const EdgeInsets.all(15),
//               decoration: const BoxDecoration(
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(7),
//                   topRight: Radius.circular(7),
//                 ),
//                 color: kDisabledBg,
//               ),
//               child: const Center(
//                 child: Icon(FontAwesomeIcons.envelope, color: kDisabledText),
//               ),
//             ),
//             Positioned(
//               top: 10.h,
//               right: 10.h,
//               child: const Icon(
//                 FontAwesomeIcons.solidCircleXmark,
//                 color: Colors.red,
//               ),
//             ),
//           ],
//         ),
//         Container(
//           width: 200.w,
//           padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
//           decoration: const BoxDecoration(
//             borderRadius: BorderRadius.only(
//               bottomLeft: Radius.circular(7),
//               bottomRight: Radius.circular(7),
//             ),
//             color: kPrimaryColor,
//           ),
//           child: Text(
//             'upload'.tr(),
//             style: AppTheme.mediumTextStyle(color: white),
//           ),
//         ),
//       ],
//     );
//   }
// }
