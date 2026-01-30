# Hive Inspector

A comprehensive debugging and inspection tool for viewing all Hive database caches in the MTS application, similar to SQLite inspection capabilities.

## Features

- **View All Hive Boxes**: Browse all 40+ Hive boxes used for caching
- **Box Details**: Inspect complete contents of any box
- **Search & Filter**: Search items by key or value within boxes
- **Item Details**: View detailed data structures for each cached item
- **Real-time Refresh**: Pull-to-refresh to reload data
- **Navigation**: Easy back button navigation

## How to Access

### From Sales Home Page
1. Open the app and navigate to the sales home page
2. Tap the menu button (three dots) in the top right corner of the app bar
3. Select **"Hive Inspector"** from the dropdown menu
4. The Hive List page will open

### Programmatically
```dart
import 'package:mts/presentation/features/hive_inspector/hive_inspector_navigation.dart';

// Navigate to Hive Inspector
HiveInspectorNavigation.navigateToHiveList(context);

// Or push and replace current page
HiveInspectorNavigation.pushAndReplaceHiveList(context);
```

## Usage

### 1. Hive List Page
Shows all available Hive boxes with:
- Box name
- Number of items in each box
- Visual indicator for empty boxes
- Tap on a box to view its contents

**Features:**
- Pull to refresh the list
- Boxes are sorted alphabetically
- Empty boxes are disabled (cannot be tapped)
- Item count badge shows number of cached records

### 2. Box Details Page
Shows all items in a selected box with:
- Search bar to filter items
- Item count display
- Expandable item cards showing keys, types, and values
- Pretty-printed JSON/structured data

**Features:**
- Search by key or value (case-insensitive)
- Tap any item to expand and see full details
- View data types for each item
- Refresh button to reload data
- Pull to refresh support

## Available Boxes

The app caches the following 40+ models in separate Hive boxes:

### Transaction & Sales
- `sales` - Sale records
- `sale_items` - Individual sale items
- `sale_modifiers` - Sales modifiers
- `sale_modifier_options` - Modifier options for sales
- `predefined_orders` - Saved order templates
- `deleted_sale_items` - Deleted sale items log

### Inventory
- `inventories` - Inventory records
- `inventory_outlets` - Outlet-specific inventory
- `inventory_transactions` - Inventory movement logs
- `inventory_adjustments` - Manual adjustments

### Products & Services
- `items` - Product/service items
- `categories` - Item categories
- `modifiers` - Available modifiers
- `modifier_options` - Modifier options
- `item_modifiers` - Item-to-modifier mappings
- `variant_options` - Product variations
- `item_taxes` - Tax configurations for items
- `order_options` - Pre-defined order options
- `order_option_taxes` - Tax for order options

### Customers & Accounts
- `customers` - Customer records
- `suppliers` - Supplier information
- `payments` - Payment records
- `payment_types` - Available payment types
- `discounts` - Discount records
- `discount_outlets` - Outlet-specific discounts
- `discount_items` - Item-specific discounts

### Organization & Configuration
- `outlets` - Store/outlet locations
- `divisions` - Business divisions
- `staff` - Staff/employee records
- `permissions` - User permissions
- `features` - Feature flags
- `feature_companies` - Company-specific features
- `devices` - Device configurations
- `users` - User accounts

### Taxes & Pricing
- `taxes` - Tax rate definitions
- `outlet_taxes` - Outlet-specific taxes
- `category_taxes` - Category-specific taxes
- `category_discounts` - Category-level discounts

### Printing & Display
- `printers` - Printer configurations
- `printer_settings` - Printer settings
- `receipt_settings` - Receipt design settings
- `department_printers` - Department printer mappings
- `printing_logs` - Print job history

### Operational
- `tables` - Table/area definitions
- `shifts` - Shift records
- `timecard` - Employee time tracking
- `cash_drawer_logs` - Cash drawer activity
- `cash_management` - Cash management records
- `error_logs` - Application error logs
- `pending_changes` - Pending sync changes
- `page_items` - Page-level item caching
- `downloaded_files` - Downloaded file cache

## Common Tasks

### Search for an Item
1. Open a box details page
2. Use the search bar at the top
3. Type key name or value to search
4. Results update in real-time

### View Item Details
1. In box details, find the item
2. Tap the item card to expand
3. View:
   - Key identifier
   - Data type
   - Full value/structure

### Refresh Data
- Swipe down on any list (pull-to-refresh)
- Or tap the refresh icon in the app bar

### Clear Cache (For Testing)
While Hive Inspector is read-only in the UI, you can use `HiveInspector` utility methods in code:

```dart
import 'package:mts/core/services/hive_inspector.dart';

// Get box contents
final contents = await HiveInspector.getBoxContents('customers');

// Delete specific item
await HiveInspector.deleteBoxItem('customers', 'key123');

// Clear entire box
await HiveInspector.clearBox('customers');
```

## Technical Details

### Comparison with SQLite
| Task | SQLite | Hive Inspector |
|------|--------|----------------|
| List tables | `databaseList()` | View all boxes |
| View data | `query('SELECT * FROM table')` | Tap on box name |
| Search data | `WHERE clause` | Search bar |
| View item | `SELECT * WHERE id=123` | Expand item card |
| Row count | `COUNT(*)` | Item count badge |

### Data Storage
- All data is stored as `Map<String, dynamic>` JSON
- Each box has its own isolated storage
- Data persists between app sessions
- Synchronized with backend via API

### Performance
- List page loads 40+ boxes instantly
- Search is performed client-side
- Refresh is asynchronous and non-blocking
- No impact on app performance

## Troubleshooting

### Box is empty
- Data hasn't been synced yet
- Try refreshing (pull down)
- Check network connectivity

### Search returns no results
- Check spelling
- Search is case-insensitive
- Try searching just the key name

### Can't see new data
- Pull to refresh the list
- Sync data from menu
- Close and reopen inspector

## Security Note

This tool is primarily for development and debugging. In production builds, this feature could be restricted based on build configuration or user permissions.

## Related Documentation

- See `lib/core/services/hive_inspector.dart` for utility methods
- See `lib/core/services/hive_init_helper.dart` for box initialization
- See `lib/core/config/constants.dart` for Hive configuration