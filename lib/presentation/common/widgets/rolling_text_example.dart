import 'package:flutter/material.dart';
import 'rolling_text.dart';

/// Example screen demonstrating the RollingText and RollingNumber widgets
class RollingTextExample extends StatefulWidget {
  const RollingTextExample({super.key});

  @override
  State<RollingTextExample> createState() => _RollingTextExampleState();
}

class _RollingTextExampleState extends State<RollingTextExample> {
  // Example state for RollingText
  String _text = 'Hello';

  // Example state for RollingNumber
  double _value = 1234.56;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rolling Text Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // RollingText example
            const Text('RollingText Example:'),
            const SizedBox(height: 8),
            RollingText(
              text: _text,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _text = 'Hello';
                    });
                  },
                  child: const Text('Hello'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _text = 'World';
                    });
                  },
                  child: const Text('World'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _text = 'Flutter';
                    });
                  },
                  child: const Text('Flutter'),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // RollingNumber example
            const Text('RollingNumber Example:'),
            const SizedBox(height: 8),
            RollingNumber(
              value: _value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              decimalPlaces: 2,
              useThousandsSeparator: true,
              prefix: '\$',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _value = 1234.56;
                    });
                  },
                  child: const Text('1,234.56'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _value = 9876.54;
                    });
                  },
                  child: const Text('9,876.54'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _value = _value + 100;
                    });
                  },
                  child: const Text('+100'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // RollingNumber with different formatting
            RollingNumber(
              value: _value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              decimalPlaces: 0,
              useThousandsSeparator: true,
              suffix: ' units',
            ),
          ],
        ),
      ),
    );
  }
}
