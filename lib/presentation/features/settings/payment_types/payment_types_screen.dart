// import 'package:flutter/material.dart';
// import 'package:flutter_scale_tap/flutter_scale_tap.dart';
// import 'package:mts/core/config/constants.dart';
// import 'package:mts/data/models/payment_type/payment_type_model.dart';
// import 'package:mts/screens/settings/payment_types/components/add_payment_type_button.dart';

// class PaymentTypesScreen extends StatefulWidget {
//   const PaymentTypesScreen({super.key});

//   @override
//   State<PaymentTypesScreen> createState() => _PaymentTypesScreenState();
// }

// class _PaymentTypesScreenState extends State<PaymentTypesScreen> {
//   List<PaymentTypeModel> paymentTypes = [
//     PaymentTypeModel(title: "Credit Card", isSelected: false),
//     PaymentTypeModel(title: "Debit Card", isSelected: false),

//     // Add more payment types as needed
//   ];
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.all(20),
//       padding: EdgeInsets.all(15),
//       decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(10),
//           color: white,
//           boxShadow: [
//             BoxShadow(
//               offset: const Offset(1, 4),
//               blurRadius: 10,
//               spreadRadius: 0,
//               color: Colors.black.withValues(alpha: 0.10),
//             ),
//           ]),
//       child: Column(
//         children: [
//           const Row(
//             children: [
//               AddPaymentTypeButton(),
//             ],
//           ),
//           const SizedBox(
//             height: 20,
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               physics: const BouncingScrollPhysics(),
//               child: Column(
//                 children: paymentTypes.asMap().entries.map((entry) {
//                   int index = entry.key;
//                   String text = entry.value.title!;
//                   bool _isSelected = entry.value.isSelected!;

//                   return ScaleTap(
//                       onPressed: () {
//                         setState(() {
//                           entry.value.isSelected = !entry.value.isSelected!;
//                         });
//                       },
//                       child: ListTile(
//                         title: Text(text),
//                         leading: Checkbox(
//                           value: entry.value.isSelected!,
//                           onChanged: (value) {
//                             setState(() {
//                               entry.value.isSelected = value!;
//                             });
//                           },
//                         ),
//                       ));
//                 }).toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
