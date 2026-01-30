# MTS (Myzstech POS System) Information

## Summary

MTS is a Point of Sale (POS) system developed by Myzstech. It's a Flutter-based application designed to run on multiple platforms including Android, iOS, macOS, and Windows. The application follows a clean architecture pattern with distinct layers for presentation, domain, and data.

## Structure

- **lib/** - Main source code directory with application logic
  - **app/** - Application initialization and configuration
  - **bloc/** - Business Logic Components for state management
  - **core/** - Core utilities, configurations, and helpers
  - **data/** - Data layer with repositories, models, and services
  - **domain/** - Domain layer with entities and business rules
  - **form_bloc/** - Form handling logic
  - **presentation/** - UI components and screens
  - **providers/** - State management providers
  - **testing_package/** - Testing utilities and packages
  - **widgets/** - Reusable UI components
- **assets/** - Application assets (images, fonts, dictionaries)
- **android/**, **ios/**, **macos/**, **windows/** - Platform-specific code

## Language & Runtime

**Language**: Dart/Flutter
**Version**: Flutter 3.29.2 (Dart 3.7.2)
**Build System**: Flutter build system
**Package Manager**: pub (Dart package manager)

## Dependencies

**Main Dependencies**:

- **State Management**: flutter_riverpod (2.6.1), provider (6.1.2), bloc pattern
- **UI**: flutter_screenutil (5.9.3), flutter_svg (2.0.17), auto_size_text (3.0.0)
- **Networking**: dio (5.8.0+1), http (1.3.0), connectivity_plus (6.1.3)
- **Storage**: sqflite (2.4.2), flutter_secure_storage (9.0.0)
- **Forms**: reactive_forms (17.0.1)
- **Localization**: easy_localization (3.0.7+1), intl (0.19.0)

**Development Dependencies**:

- flutter_lints (5.0.0)
- flutter_test

## Build & Installation

```bash
# Get dependencies
flutter pub get

# Run the application in debug mode
flutter run

# Build for specific platforms
flutter build apk  # Android
flutter build ios  # iOS
flutter build macos  # macOS
flutter build windows  # Windows
```

## Testing

**Framework**: flutter_test
**Test Location**: Limited testing files found in lib/testing_package
**Run Command**:

```bash
flutter test
```

## Architecture

The application follows a clean architecture approach with:

1. **Presentation Layer**:

   - Features organized by functionality
   - Blocs for state management
   - Form handling with form_bloc

2. **Domain Layer**:

   - Business logic and rules
   - Entity definitions
   - Repository interfaces

3. **Data Layer**:

   - API communication
   - Local storage
   - Repository implementations

4. **State Management**:

   - Mix of Provider, Riverpod, and BLoC patterns
   - Notifiers for reactive state updates

5. **Navigation**:
   - Custom navigator implementation
   - Route management

The application also supports multiple displays with a secondary display feature for customer-facing interfaces, which is common in POS systems.
