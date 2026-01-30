# Device Utils

A comprehensive utility for detecting device types (phone, tablet, web) and creating responsive layouts in Flutter applications.

## Features

- ✅ Detect device type (phone, tablet, web)
- ✅ Check screen sizes (small, medium, large)
- ✅ Get responsive values based on device type
- ✅ Platform detection (web vs mobile)
- ✅ Size checking without BuildContext
- ✅ Helper methods for responsive UI

## Breakpoints

The utility uses the following breakpoints:

- **Phone**: width < 600px
- **Tablet**: 600px ≤ width < 1024px
- **Web/Desktop**: width ≥ 1024px

## Usage

### 1. Basic Device Detection

```dart
import 'package:mts/core/utils/device_utils.dart';

// Check device type
if (DeviceUtils.isPhone(context)) {
  // Phone-specific code
}

if (DeviceUtils.isTablet(context)) {
  // Tablet-specific code
}

if (DeviceUtils.isWebOrLargeScreen(context)) {
  // Web/Desktop-specific code
}

// Get device type as enum
DeviceType deviceType = DeviceUtils.getDeviceType(context);

// Get device type as string
String deviceName = DeviceUtils.getDeviceTypeName(context); // "Phone", "Tablet", or "Web"
```

### 2. Screen Size Detection

```dart
// Check screen sizes
bool isSmall = DeviceUtils.isSmallScreen(context);   // < 600px
bool isMedium = DeviceUtils.isMediumScreen(context); // 600-1024px
bool isLarge = DeviceUtils.isLargeScreen(context);   // >= 1024px

// Check if mobile (phone or tablet)
bool isMobile = DeviceUtils.isMobile(context);

// Check if running on web platform
bool isWeb = DeviceUtils.isWeb();
```

### 3. Responsive Values

```dart
// Get different values based on device type
double fontSize = DeviceUtils.getResponsiveValue<double>(
  context: context,
  phone: 14.0,
  tablet: 18.0,
  web: 22.0,
);

// Get responsive font size
double fontSize = DeviceUtils.getResponsiveFontSize(
  context,
  phoneFontSize: 14.0,
  tabletFontSize: 16.0,
  webFontSize: 18.0,
);

// Get responsive padding
EdgeInsets padding = DeviceUtils.getResponsivePadding(
  context,
  phonePadding: EdgeInsets.all(8.0),
  tabletPadding: EdgeInsets.all(16.0),
  webPadding: EdgeInsets.all(24.0),
);

// Get responsive grid columns
int columns = DeviceUtils.getGridColumns(
  context,
  phoneColumns: 2,
  tabletColumns: 3,
  webColumns: 4,
);
```

### 4. Size Checking Without Context

```dart
// Check device type from width and height
DeviceType type = DeviceUtils.getDeviceTypeFromSize(800, 600);

// Check specific sizes
bool isPhone = DeviceUtils.isPhoneSize(500, 800);
bool isTablet = DeviceUtils.isTabletSize(700, 1000);
bool isWeb = DeviceUtils.isWebSize(1200, 800);
```

### 5. Practical Examples

#### Example 1: Responsive Text

```dart
Text(
  'Hello World',
  style: TextStyle(
    fontSize: DeviceUtils.getResponsiveFontSize(
      context,
      phoneFontSize: 14.0,
      tabletFontSize: 18.0,
      webFontSize: 22.0,
    ),
  ),
)
```

#### Example 2: Responsive Container

```dart
Container(
  padding: DeviceUtils.getResponsivePadding(
    context,
    phonePadding: EdgeInsets.all(8.0),
    tabletPadding: EdgeInsets.all(16.0),
    webPadding: EdgeInsets.all(24.0),
  ),
  child: Text('Responsive Container'),
)
```

#### Example 3: Responsive Grid

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: DeviceUtils.getGridColumns(
      context,
      phoneColumns: 2,
      tabletColumns: 3,
      webColumns: 4,
    ),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
  ),
  itemBuilder: (context, index) {
    return YourWidget();
  },
)
```

#### Example 4: Conditional Layout

```dart
Widget build(BuildContext context) {
  if (DeviceUtils.isPhone(context)) {
    return PhoneLayout();
  } else if (DeviceUtils.isTablet(context)) {
    return TabletLayout();
  } else {
    return WebLayout();
  }
}
```

#### Example 5: Using Switch Statement

```dart
Widget build(BuildContext context) {
  final deviceType = DeviceUtils.getDeviceType(context);

  switch (deviceType) {
    case DeviceType.phone:
      return PhoneLayout();
    case DeviceType.tablet:
      return TabletLayout();
    case DeviceType.web:
      return WebLayout();
  }
}
```

#### Example 6: Responsive AppBar

```dart
AppBar(
  title: Text(
    'My App',
    style: TextStyle(
      fontSize: DeviceUtils.getResponsiveFontSize(
        context,
        phoneFontSize: 18.0,
        tabletFontSize: 22.0,
        webFontSize: 26.0,
      ),
    ),
  ),
  actions: DeviceUtils.isPhone(context)
      ? [IconButton(icon: Icon(Icons.menu), onPressed: () {})]
      : [
          TextButton(child: Text('Home'), onPressed: () {}),
          TextButton(child: Text('About'), onPressed: () {}),
          TextButton(child: Text('Contact'), onPressed: () {}),
        ],
)
```

#### Example 7: Responsive Sidebar

```dart
Widget build(BuildContext context) {
  return Scaffold(
    drawer: DeviceUtils.isPhone(context) ? Drawer(...) : null,
    body: Row(
      children: [
        if (DeviceUtils.isTablet(context) || DeviceUtils.isWebOrLargeScreen(context))
          Container(
            width: DeviceUtils.getResponsiveValue<double>(
              context: context,
              phone: 0,
              tablet: 250,
              web: 300,
            ),
            child: NavigationRail(...),
          ),
        Expanded(child: MainContent()),
      ],
    ),
  );
}
```

## Custom Breakpoints

If you need different breakpoints, you can modify the constants in `device_utils.dart`:

```dart
static const double phoneMaxWidth = 600;   // Change this
static const double tabletMaxWidth = 1024; // Change this
```

## Best Practices

1. **Use responsive values** instead of hardcoded sizes
2. **Test on multiple devices** to ensure proper responsiveness
3. **Consider orientation** when designing layouts
4. **Use MediaQuery** for more complex responsive logic
5. **Combine with ScreenUtil** for more precise scaling

## Integration with Existing Code

You can easily integrate this utility into your existing codebase:

```dart
// Before
Container(
  padding: EdgeInsets.all(16.0),
  child: Text('Hello', style: TextStyle(fontSize: 14)),
)

// After
Container(
  padding: DeviceUtils.getResponsivePadding(context),
  child: Text(
    'Hello',
    style: TextStyle(
      fontSize: DeviceUtils.getResponsiveFontSize(context),
    ),
  ),
)
```

## See Also

- `device_utils_example.dart` - Complete working examples
- `ui_utils.dart` - Other UI utility functions
- Flutter's `MediaQuery` - For more advanced responsive design
