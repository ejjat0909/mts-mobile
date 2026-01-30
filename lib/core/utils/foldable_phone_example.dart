import 'package:flutter/material.dart';
import 'package:mts/core/utils/device_utils.dart';
import 'package:mts/core/utils/log_utils.dart';

/// Example usage of DeviceUtils for Foldable Phones
/// This demonstrates how to detect and handle foldable devices like Pixel Fold, Galaxy Z Fold, etc.
class FoldablePhoneExample extends StatelessWidget {
  const FoldablePhoneExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foldable Phone Detection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Basic foldable detection
            _buildSection(
              'Foldable Phone Detection',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Type: ${DeviceUtils.getDeviceTypeName(context)}',
                  ),
                  Text(
                    'Is Foldable Phone: ${DeviceUtils.isFoldablePhone(context)}',
                  ),
                  Text('Is Folded: ${DeviceUtils.isFoldedPhone(context)}'),
                  Text('Is Unfolded: ${DeviceUtils.isUnfoldedPhone(context)}'),
                  Text(
                    'Is Regular Phone: ${DeviceUtils.isRegularPhone(context)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Example 2: Foldable info
            _buildSection(
              'Detailed Foldable Info',
              Builder(
                builder: (context) {
                  final info = DeviceUtils.getFoldableInfo(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Width: ${info['width']?.toStringAsFixed(1)}'),
                      Text('Height: ${info['height']?.toStringAsFixed(1)}'),
                      Text(
                        'Aspect Ratio: ${info['aspectRatio']?.toStringAsFixed(2)}',
                      ),
                      Text('Device Type: ${info['deviceType']}'),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Example 3: Conditional layout based on fold state
            _buildSection('Adaptive Layout', _buildAdaptiveLayout(context)),

            const SizedBox(height: 20),

            // Example 4: Responsive grid for foldable
            _buildSection(
              'Responsive Grid',
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: DeviceUtils.getGridColumns(
                    context,
                    phoneColumns: 2,
                    phoneFoldedColumns: 1, // Single column when folded
                    phoneUnfoldedColumns: 3, // More columns when unfolded
                    tabletColumns: 4,
                  ),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    color: Colors.blue.shade200,
                    child: Center(child: Text('Item ${index + 1}')),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Example 5: Responsive font size
            _buildSection(
              'Responsive Text',
              Text(
                'This text adapts to fold state',
                style: TextStyle(
                  fontSize: DeviceUtils.getResponsiveFontSize(
                    context,
                    phoneFontSize: 14.0,
                    phoneFoldedFontSize: 12.0, // Smaller when folded
                    phoneUnfoldedFontSize: 18.0, // Larger when unfolded
                    tabletFontSize: 20.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Example 6: Responsive padding
            _buildSection(
              'Responsive Padding',
              Container(
                padding: DeviceUtils.getResponsivePadding(
                  context,
                  phonePadding: const EdgeInsets.all(8.0),
                  phoneFoldedPadding: const EdgeInsets.all(
                    4.0,
                  ), // Less padding when folded
                  phoneUnfoldedPadding: const EdgeInsets.all(
                    16.0,
                  ), // More padding when unfolded
                  tabletPadding: const EdgeInsets.all(20.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Container with adaptive padding'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _buildAdaptiveLayout(BuildContext context) {
    if (DeviceUtils.isFoldedPhone(context)) {
      // Folded state: Show compact single-column layout
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          children: [
            Icon(Icons.phone_android, size: 40),
            SizedBox(height: 8),
            Text(
              'Folded Layout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Compact single-column view', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    } else if (DeviceUtils.isUnfoldedPhone(context)) {
      // Unfolded state: Show expanded two-column layout
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.purple.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.tablet_android, size: 50),
                  const SizedBox(height: 8),
                  const Text(
                    'Unfolded Layout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.open_in_full, size: 50),
                  const SizedBox(height: 8),
                  const Text(
                    'Expanded View',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Regular phone or other device
      return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          children: [
            Icon(Icons.smartphone, size: 40),
            SizedBox(height: 8),
            Text(
              'Regular Layout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Standard phone view', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
  }
}

/// Example: Responsive app bar for foldable phones
class FoldableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const FoldableAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: DeviceUtils.getResponsiveFontSize(
            context,
            phoneFoldedFontSize: 16.0,
            phoneFontSize: 18.0,
            phoneUnfoldedFontSize: 22.0,
            tabletFontSize: 24.0,
          ),
        ),
      ),
      actions:
          DeviceUtils.isFoldedPhone(context)
              ? [
                // Compact actions for folded state
                IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
              ]
              : [
                // Full actions for unfolded/regular state
                TextButton(child: const Text('Home'), onPressed: () {}),
                TextButton(child: const Text('Settings'), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Example: Foldable-aware navigation
class FoldableNavigation extends StatelessWidget {
  final Widget child;

  const FoldableNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (DeviceUtils.isFoldedPhone(context)) {
      // Folded: Use bottom navigation
      return Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
    } else if (DeviceUtils.isUnfoldedPhone(context)) {
      // Unfolded: Use side navigation rail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search),
                  label: Text('Search'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
              selectedIndex: 0,
              onDestinationSelected: (index) {},
            ),
            Expanded(child: child),
          ],
        ),
      );
    } else {
      // Regular phone: Use drawer
      return Scaffold(
        appBar: AppBar(title: const Text('App')),
        drawer: Drawer(
          child: ListView(
            children: const [
              DrawerHeader(child: Text('Menu')),
              ListTile(leading: Icon(Icons.home), title: Text('Home')),
              ListTile(leading: Icon(Icons.search), title: Text('Search')),
              ListTile(leading: Icon(Icons.person), title: Text('Profile')),
            ],
          ),
        ),
        body: child,
      );
    }
  }
}

/// Example: Check foldable size without context
void checkFoldableSizes() {
  // Pixel Fold dimensions
  // Folded: 316 x 884 (aspect ratio: 2.8)
  // Unfolded: 673 x 884 (aspect ratio: 1.31)

  prints('Pixel Fold Folded (316x884):');
  prints('  Is Folded: ${DeviceUtils.isFoldedPhoneSize(316, 884)}');
  prints('  Is Unfolded: ${DeviceUtils.isUnfoldedPhoneSize(316, 884)}');
  prints('  Device Type: ${DeviceUtils.getDeviceTypeFromSize(316, 884)}');

  prints('\nPixel Fold Unfolded (673x884):');
  prints('  Is Folded: ${DeviceUtils.isFoldedPhoneSize(673, 884)}');
  prints('  Is Unfolded: ${DeviceUtils.isUnfoldedPhoneSize(673, 884)}');
  prints('  Device Type: ${DeviceUtils.getDeviceTypeFromSize(673, 884)}');

  // Galaxy Z Fold dimensions
  // Folded: 344 x 882 (aspect ratio: 2.56)
  // Unfolded: 768 x 882 (aspect ratio: 1.15)

  prints('\nGalaxy Z Fold Folded (344x882):');
  prints('  Is Folded: ${DeviceUtils.isFoldedPhoneSize(344, 882)}');
  prints('  Device Type: ${DeviceUtils.getDeviceTypeFromSize(344, 882)}');

  prints('\nGalaxy Z Fold Unfolded (768x882):');
  prints('  Is Unfolded: ${DeviceUtils.isUnfoldedPhoneSize(768, 882)}');
  prints('  Device Type: ${DeviceUtils.getDeviceTypeFromSize(768, 882)}');
}
