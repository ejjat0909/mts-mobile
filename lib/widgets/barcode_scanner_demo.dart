// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:mts/providers/barcode_scanner_notifier.dart';

// /// Demo widget to show barcode scanner functionality
// class BarcodeScannerDemo extends StatelessWidget {
//   const BarcodeScannerDemo({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<BarcodeScannerNotifier>(
//       builder: (context, barcodeNotifier, child) {
//         return Container(
//           padding: const EdgeInsets.all(16),
//           margin: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey),
//             borderRadius: BorderRadius.circular(8),
//             color: Colors.white,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Barcode Scanner Status',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Scanner status
//               Row(
//                 children: [
//                   Icon(
//                     Icons.qr_code_scanner,
//                     color: Colors.green,
//                     size: 20,
//                   ),
//                   const SizedBox(width: 8),
//                   const Text('Scanner Ready - Scan any Code 128 barcode'),
//                 ],
//               ),
              
//               const SizedBox(height: 12),
              
//               // Last scanned barcode
//               if (barcodeNotifier.lastScannedBarcode != null) ...[
//                 const Text(
//                   'Last Scanned:',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     barcodeNotifier.lastScannedBarcode!,
//                     style: const TextStyle(
//                       fontFamily: 'monospace',
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
              
//               // Processing indicator
//               if (barcodeNotifier.isProcessing) ...[
//                 const Row(
//                   children: [
//                     SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                     SizedBox(width: 8),
//                     Text('Processing...'),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//               ],
              
//               // Found item
//               if (barcodeNotifier.scannedItem != null) ...[
//                 const Text(
//                   'Found Item:',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.green[50],
//                     border: Border.all(color: Colors.green[200]!),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         barcodeNotifier.scannedItem!.name ?? 'Unknown Item',
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       if (barcodeNotifier.scannedItem!.price != null)
//                         Text('Price: \$${barcodeNotifier.scannedItem!.price!.toStringAsFixed(2)}'),
//                       if (barcodeNotifier.scannedItem!.sku != null)
//                         Text('SKU: ${barcodeNotifier.scannedItem!.sku}'),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
              
//               // Error message
//               if (barcodeNotifier.errorMessage != null) ...[
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.red[50],
//                     border: Border.all(color: Colors.red[200]!),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.error_outline, color: Colors.red[600], size: 16),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           barcodeNotifier.errorMessage!,
//                           style: TextStyle(color: Colors.red[600]),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
              
//               // Clear button
//               if (barcodeNotifier.lastScannedBarcode != null ||
//                   barcodeNotifier.errorMessage != null) ...[
//                 ElevatedButton(
//                   onPressed: () {
//                     barcodeNotifier.clearScannedItem();
//                   },
//                   child: const Text('Clear'),
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }
// }