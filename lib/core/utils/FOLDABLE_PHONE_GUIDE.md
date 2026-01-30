# Foldable Phone Support Guide

Complete guide for detecting and handling foldable phones like Pixel Fold, Galaxy Z Fold, and other foldable devices.

## Overview

The `DeviceUtils` class now includes comprehensive support for foldable phones, detecting both folded and unfolded states based on screen dimensions and aspect ratios.

## Device Types

```dart
enum DeviceType {
  phone,           // Regular phone
  phoneFolded,     // Foldable phone in folded state
  phoneUnfolded,   // Foldable phone in unfolded state
  tablet,          // Tablet
  web,             // Web/Desktop
}
```

## Detection Criteria

### Folded Phone

- **Width**: < 400px
- **Aspect Ratio**: ≥ 2.0 (tall and narrow)
- **Example**: Pixel Fold folded (316x884), Galaxy Z Fold folded (344x882)

### Unfolded Phone

- **Width**: 500px - 900px
- **Aspect Ratio**: ≤ 1.5 (more square-like)
- **Example**: Pixel Fold unfolded (673x884), Galaxy Z Fold unfolded (768x882)

## Common Foldable Devices

| Device          | Folded Size | Unfolded Size | Aspect Ratio (Folded) | Aspect Ratio (Unfolded) |
| --------------- | ----------- | ------------- | --------------------- | ----------------------- |
| Pixel Fold      | 316 x 884   | 673 x 884     | 2.80                  | 1.31                    |
| Galaxy Z Fold 5 | 344 x 882   | 768 x 882     | 2.56                  | 1.15                    |
| Galaxy Z Fold 4 | 344 x 904   | 768 x 904     | 2.63                  | 1.18                    |
| Oppo Find N2    | 360 x 792   | 720 x 792     | 2.20                  | 1.10                    |

## Basic Detection

### Check Foldable State

```dart
// Check if device is a foldable phone (any state)
if (DeviceUtils.isFoldablePhone(context)) {
  prints('This is a foldable phone!');
}

// Check specific fold state
if (DeviceUtils.isFoldedPhone(context)) {
  prints('Phone is folded - show compact layout');
}

if (DeviceUtils.isUnfoldedPhone(context)) {
  prints('Phone is unfolded - show expanded layout');
}

// Check if regular phone (not foldable)
if (DeviceUtils.isRegularPhone(context)) {
  prints('This is a regular phone');
}
```

### Get Device Type

```dart
DeviceType type = DeviceUtils.getDeviceType(context);

switch (type) {
  case DeviceType.phoneFolded:
    // Handle folded state
    break;
  case DeviceType.phoneUnfolded:
    // Handle unfolded state
    break;
  case DeviceType.phone:
    // Handle regular phone
    break;
  // ... other cases
}
```

### Get Foldable Info

```dart
Map<String, dynamic> info = DeviceUtils.getFoldableInfo(context);

prints('Is Foldable: ${info['isFoldable']}');
prints('Is Folded: ${info['isFolded']}');
prints('Is Unfolded: ${info['isUnfolded']}');
prints('Width: ${info['width']}');
prints('Height: ${info['height']}');
prints('Aspect Ratio: ${info['aspectRatio']}');
```

## Responsive Layouts

### Adaptive Grid

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: DeviceUtils.getGridColumns(
      context,
      phoneColumns: 2,
      phoneFoldedColumns: 1,      // Single column when folded
      phoneUnfoldedColumns: 3,    // More columns when unfolded
      tabletColumns: 4,
      webColumns: 5,
    ),
  ),
  itemBuilder: (context, index) => YourWidget(),
)
```

### Adaptive Font Size

```dart
Text(
  'Responsive Text',
  style: TextStyle(
    fontSize: DeviceUtils.getResponsiveFontSize(
      context,
      phoneFontSize: 14.0,
      phoneFoldedFontSize: 12.0,    // Smaller when folded
      phoneUnfoldedFontSize: 18.0,  // Larger when unfolded
      tabletFontSize: 20.0,
      webFontSize: 22.0,
    ),
  ),
)
```

### Adaptive Padding

```dart
Container(
  padding: DeviceUtils.getResponsivePadding(
    context,
    phonePadding: EdgeInsets.all(8.0),
    phoneFoldedPadding: EdgeInsets.all(4.0),   // Less padding when folded
    phoneUnfoldedPadding: EdgeInsets.all(16.0), // More padding when unfolded
    tabletPadding: EdgeInsets.all(20.0),
    webPadding: EdgeInsets.all(24.0),
  ),
  child: YourWidget(),
)
```

### Conditional Layouts

```dart
Widget build(BuildContext context) {
  if (DeviceUtils.isFoldedPhone(context)) {
    return CompactLayout();  // Single column, minimal UI
  } else if (DeviceUtils.isUnfoldedPhone(context)) {
    return ExpandedLayout();  // Multi-column, rich UI
  } else {
    return RegularLayout();
  }
}
```

## Practical Examples

### Example 1: Adaptive Navigation

```dart
Widget buildNavigation(BuildContext context) {
  if (DeviceUtils.isFoldedPhone(context)) {
    // Folded: Use bottom navigation bar
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
      ],
    );
  } else if (DeviceUtils.isUnfoldedPhone(context)) {
    // Unfolded: Use navigation rail (side navigation)
    return NavigationRail(
      destinations: [
        NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
        NavigationRailDestination(icon: Icon(Icons.search), label: Text('Search')),
      ],
      selectedIndex: 0,
    );
  } else {
    // Regular: Use drawer
    return Drawer(/* ... */);
  }
}
```

### Example 2: Adaptive Content Layout

```dart
Widget buildContent(BuildContext context) {
  if (DeviceUtils.isFoldedPhone(context)) {
    // Folded: Stack content vertically
    return Column(
      children: [
        HeaderWidget(),
        ContentWidget(),
        FooterWidget(),
      ],
    );
  } else if (DeviceUtils.isUnfoldedPhone(context)) {
    // Unfolded: Show side-by-side
    return Row(
      children: [
        Expanded(flex: 1, child: SidebarWidget()),
        Expanded(flex: 2, child: ContentWidget()),
      ],
    );
  } else {
    return DefaultLayout();
  }
}
```

### Example 3: Adaptive App Bar

```dart
AppBar buildAppBar(BuildContext context) {
  return AppBar(
    title: Text(
      'My App',
      style: TextStyle(
        fontSize: DeviceUtils.getResponsiveFontSize(
          context,
          phoneFoldedFontSize: 16.0,
          phoneFontSize: 18.0,
          phoneUnfoldedFontSize: 22.0,
        ),
      ),
    ),
    actions: DeviceUtils.isFoldedPhone(context)
        ? [IconButton(icon: Icon(Icons.menu), onPressed: () {})]
        : [
            TextButton(child: Text('Home'), onPressed: () {}),
            TextButton(child: Text('About'), onPressed: () {}),
            IconButton(icon: Icon(Icons.settings), onPressed: () {}),
          ],
  );
}
```

### Example 4: Adaptive Image Display

```dart
Widget buildImageGallery(BuildContext context) {
  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: DeviceUtils.getGridColumns(
        context,
        phoneFoldedColumns: 1,      // Single image when folded
        phoneColumns: 2,
        phoneUnfoldedColumns: 3,    // More images when unfolded
        tabletColumns: 4,
      ),
      mainAxisSpacing: DeviceUtils.isFoldedPhone(context) ? 8 : 16,
      crossAxisSpacing: DeviceUtils.isFoldedPhone(context) ? 8 : 16,
    ),
    itemBuilder: (context, index) => Image.network(imageUrls[index]),
  );
}
```

## Size Checking Without Context

```dart
// Check specific dimensions
bool isFolded = DeviceUtils.isFoldedPhoneSize(316, 884);  // Pixel Fold folded
bool isUnfolded = DeviceUtils.isUnfoldedPhoneSize(673, 884);  // Pixel Fold unfolded

// Get device type from dimensions
DeviceType type = DeviceUtils.getDeviceTypeFromSize(316, 884);
prints(type);  // DeviceType.phoneFolded
```

## Custom Responsive Values

```dart
// Get custom values based on device type
double spacing = DeviceUtils.getResponsiveValue<double>(
  context: context,
  phone: 8.0,
  phoneFolded: 4.0,
  phoneUnfolded: 12.0,
  tablet: 16.0,
  web: 24.0,
);

// Use in your layout
SizedBox(height: spacing);
```

## Best Practices

### 1. **Test on Real Devices**

- Test on actual foldable devices when possible
- Use Android Studio's foldable emulators
- Test both folded and unfolded states

### 2. **Handle State Changes**

- Users can fold/unfold while using your app
- Use `MediaQuery` to rebuild UI when dimensions change
- Consider using `LayoutBuilder` for dynamic layouts

### 3. **Optimize for Each State**

- **Folded**: Compact, single-column layouts
- **Unfolded**: Expanded, multi-column layouts
- Don't just scale - redesign for each state

### 4. **Consider Aspect Ratios**

- Folded phones have very tall aspect ratios (2.0+)
- Unfolded phones are more square (1.1-1.5)
- Design accordingly

### 5. **Provide Fallbacks**

- Always provide default values
- Use optional parameters for foldable-specific values
- Gracefully handle edge cases

## Customizing Breakpoints

If you need different breakpoints, modify the constants in `device_utils.dart`:

```dart
// Foldable phone breakpoints
static const double foldedPhoneMaxWidth = 400;
static const double unfoldedPhoneMinWidth = 500;
static const double unfoldedPhoneMaxWidth = 900;

// Aspect ratio thresholds
static const double foldedAspectRatioMin = 2.0;
static const double unfoldedAspectRatioMax = 1.5;
```

## Debugging

```dart
// Print device info
void debugDeviceInfo(BuildContext context) {
  final info = DeviceUtils.getFoldableInfo(context);
  prints('=== Device Info ===');
  prints('Device Type: ${DeviceUtils.getDeviceTypeName(context)}');
  prints('Is Foldable: ${info['isFoldable']}');
  prints('Is Folded: ${info['isFolded']}');
  prints('Is Unfolded: ${info['isUnfolded']}');
  prints('Width: ${info['width']}');
  prints('Height: ${info['height']}');
  prints('Aspect Ratio: ${info['aspectRatio']}');
  prints('==================');
}
```

## See Also

- `device_utils.dart` - Main utility file
- `foldable_phone_example.dart` - Complete working examples
- `device_utils_example.dart` - General device detection examples
- Flutter's `MediaQuery` - For responsive design
- Android's Foldable documentation
