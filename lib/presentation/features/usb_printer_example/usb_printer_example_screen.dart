import 'package:flutter/material.dart';
import 'package:mts/core/mixins/usb_printer_lifecycle_mixin.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';

/// Example screen showing how to use USB printer lifecycle events
/// This demonstrates how to use the UsbPrinterLifecycleMixin in any widget
class UsbPrinterExampleScreen extends StatefulWidget {
  const UsbPrinterExampleScreen({super.key});

  @override
  State<UsbPrinterExampleScreen> createState() => _UsbPrinterExampleScreenState();
}

class _UsbPrinterExampleScreenState extends State<UsbPrinterExampleScreen>
    with WidgetsBindingObserver, UsbPrinterLifecycleMixin {
  
  List<String> _eventLog = [];

  void _addToLog(String message) {
    setState(() {
      _eventLog.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      // Keep only last 20 events
      if (_eventLog.length > 20) {
        _eventLog = _eventLog.take(20).toList();
      }
    });
  }

  @override
  void onUsbPrinterConnected(PrinterModel printer) {
    super.onUsbPrinterConnected(printer);
    _addToLog('✅ Connected: ${printer.name} (${printer.address})');
    
    // Example: You could automatically start using this printer
    // or update your app's printer settings here
  }

  @override
  void onUsbPrinterDisconnected(PrinterModel printer) {
    super.onUsbPrinterDisconnected(printer);
    _addToLog('❌ Disconnected: ${printer.name} (${printer.address})');
    
    // Example: You could switch to a backup printer here
    // or show a warning to the user
  }

  @override
  void onUsbPrinterConnectionFailed(PrinterModel printer, String error) {
    super.onUsbPrinterConnectionFailed(printer, error);
    _addToLog('⚠️ Connection Failed: ${printer.name} - $error');
    
    // Example: You could retry the connection or log the error
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Printer Events Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected USB Printers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (connectedUsbPrinters.isEmpty)
                      const Text(
                        'No USB printers connected',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...connectedUsbPrinters.map((printer) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.print, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    printer.name ?? "no printer name",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Address: ${printer.address}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Event Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: _eventLog.isEmpty
                    ? const Center(
                        child: Text(
                          'No events yet.\nConnect or disconnect a USB printer to see events.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _eventLog.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(
                              _eventLog[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _eventLog.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}