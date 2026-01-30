# StatefulWidget to ConsumerStatefulWidget Migration Strategy

## Quick Answer

**NO, do NOT convert all StatefulWidget to ConsumerStatefulWidget.**

Only convert **specific categories** that actually need Riverpod provider access. Converting unnecessarily adds overhead and complexity.

---

## Current State Analysis

### StatefulWidget Count

- **Total StatefulWidget**: ~100+ widgets
- **Already ConsumerStatefulWidget**: ~34 widgets
- **Remaining StatefulWidget**: ~70+ widgets

### Breakdown by Category

**Group 1: NO CONVERSION NEEDED** (~40 widgets)

- Pure UI state widgets (timers, animations, form inputs)
- Generic reusable widgets (buttons, text fields, containers)
- Low-level UI components

**Group 2: CONVERSION NEEDED** (~30 widgets)

- Widgets accessing facades via ServiceLocator
- Widgets that should access providers (businesses logic, data)
- High-level feature screens

**Group 3: FUTURE CONSIDERATION** (~10 widgets)

- Testing/debug widgets
- Rarely used widgets
- Performance-sensitive widgets

---

## Detailed Widget Categories & Recommendations

### ✅ KEEP as StatefulWidget (No Conversion)

**Pure UI/Animation Widgets** (~25 widgets)

These have NO business logic, just local state management:

1. **`LiveTime`** - Timer widget updating every second

   - ✅ KEEP: Only manages Timer and local state
   - NO need for providers
   - Simple lifecycle (init → periodic update → dispose)

   ```dart
   class LiveTime extends StatefulWidget {
     late Timer _timer;
     void _updateTime() { setState(() { ... }); }
   }
   // Perfect for StatefulWidget, no provider needed
   ```

2. **`ButtonBottom`** - Loading button with animation

   - ✅ KEEP: Manages AnimatedTextKit state
   - NO providers involved
   - Only need local isDisabled/loading state

3. **`OptimizedRollingNumber`**, `RollingText`, `RollingNumber`\*\* - Animated counters

   - ✅ KEEP: Pure animation state management
   - No data access
   - Performance optimized with setState

4. **`TableContent`** - Table rendering

   - ✅ KEEP: Local scroll/selection state only
   - No provider access needed

5. **`TabbedCard`** - Tab switching

   - ✅ KEEP: Just tracks active tab index
   - No business logic

6. **`LoadingGifDialogue`** - Loading dialog display

   - ✅ KEEP: Manages dialog visibility
   - No provider access

7. **`BluetoothDropdownButton`** - Dropdown selection
   - ✅ KEEP: Local selection state
   - No provider needed

**Generic Reusable Widgets** (~20 widgets)

1. **`SelectAllTextField`** - Text field utility

   - ✅ KEEP: Focus and text selection management
   - No providers

2. **`NumberPadDialogue`** - Numeric input dialog

   - ✅ KEEP: Input state management
   - No business logic

3. **`CustomTextFieldBlocBuilder`** - Form field wrapper

   - ✅ KEEP: FormBloc is separate concern
   - Local focus/validation state

4. All other `*_notifier.dart` widgets
   - ✅ KEEP: These are UI-only, not accessing complex providers

---

### 🔄 CONVERT to ConsumerStatefulWidget (~30 widgets)

**Widgets Accessing Facades/ServiceLocator** (HIGH PRIORITY)

1. **`GlobalBarcodeListener`** - Currently accesses ServiceLocator

   ```dart
   // BEFORE: Uses ServiceLocator
   _barcodeNotifier = ServiceLocator.get<BarcodeScannerNotifier>();

   // AFTER: Use ref.watch()
   class GlobalBarcodeListener extends ConsumerStatefulWidget {
     @override
     build(BuildContext context, WidgetRef ref) {
       final barcodeNotifier = ref.watch(barcodeScannerProvider);
     }
   }
   ```

   - ✅ CONVERT: Needs provider access for barcode scanning

2. **All feature screens accessing facades**:

   - `ShiftScreen` - accesses ShiftFacade
   - `LoginScreen` - accesses UserFacade
   - `CustomerDialogue` - accesses CustomerFacade
   - `SettingReceiptScreen` - accesses ReceiptFacade
   - Etc.

   ✅ CONVERT ALL: These need provider access for business logic

3. **Dialogs with business operations**:

   - `OpenShiftDialogue` - Creates shifts (uses ShiftFacade)
   - `PinDialogueScreen` - Validates PIN (uses UserFacade)
   - `CustomerDialogue` - CRUD operations (uses CustomerFacade)
   - `OrderOptionDialogue` - Creates order options

   ✅ CONVERT: All business-logic dialogs

4. **Components with data operations**:

   - `CashDrawer` - Manages cash (accesses PaymentFacade)
   - `SalesSummary` - Displays sale summaries
   - `HistorySideBar` - Queries shift history

   ✅ CONVERT: Components that fetch/modify data

5. **Payment/Receipt related**:

   - `HomeReceiptScreen` - Queries receipts
   - `RefundDetails` - Processes refunds
   - `PaymentTypeDialogue` - Selects payment types

   ✅ CONVERT: Business domain components

**Already ConsumerStatefulWidget** (~34 widgets - Already Done)

These are correctly converted:

- `SalesScreen` ✅
- `PaymentScreen` ✅
- `VariantAndModifierDialogue` ✅
- `CloseShift` ✅
- `DoubleButton` ✅
- And ~29 others

---

### ⏸️ DEFER (Future Nice-to-Have)

**Testing/Debug Widgets** (~5 widgets)

1. **`HiveBoxDetailsPage`** - Hive inspector

   - ⏸️ DEFER: Debug tool, not critical
   - Convert if/when used regularly

2. **`HiveListPage`** - Hive list viewer

   - ⏸️ DEFER: Development tool

3. **`RollingTextExample`** - Example widget
   - ⏸️ DEFER: Not used in production

**Performance-Sensitive Widgets** (~5 widgets)

1. **`MenuItem`** - Already ConsumerStatefulWidget (good!)

   - ✅ Already handled

2. **`OrderItem`** - Already ConsumerStatefulWidget
   - ✅ Already handled

---

## Decision Matrix: Should You Convert?

Use this table to decide for ANY StatefulWidget:

| Criteria                                              | Yes = Convert | No = Keep |
| ----------------------------------------------------- | ------------- | --------- |
| **Uses ServiceLocator.get<Facade>()**?                | 🔄 YES        | ✅ NO     |
| **Accesses multiple repositories/services?**          | 🔄 YES        | ✅ NO     |
| **Contains business logic (insert, update, delete)?** | 🔄 YES        | ✅ NO     |
| **Needs to watch changing data from providers?**      | 🔄 YES        | ✅ NO     |
| **Only manages local state (timers, UI flags)?**      | ✅ NO         | 🔄 YES    |
| **Just renders static/parameterized UI?**             | ✅ NO         | 🔄 YES    |
| **Uses Timer, Animation, Stream for UI only?**        | ✅ NO         | 🔄 YES    |
| **Large, complex feature screen?**                    | 🔄 YES        | ✅ NO     |
| **Small reusable component?**                         | ✅ NO         | 🔄 YES    |

---

## Conversion Strategy (Smart Phasing)

### Phase 1: Service Locator Cleanup (Week 1)

Convert only widgets that use `ServiceLocator.get<>()`:

```bash
# Find all StatefulWidget files using ServiceLocator
grep -r "ServiceLocator.get" lib/presentation/**/*.dart | grep StatefulWidget

# These are candidates for conversion:
# - GlobalBarcodeListener
# - ShiftScreen
# - LoginScreen
# - CustomerDialogue
# - ... (all business-logic widgets)
```

**Action**: Convert ~30 widgets that currently access ServiceLocator

### Phase 2: RiverpodService Removal (Week 2)

After Phase 1, continue with remaining RiverpodService usages:

```bash
grep -r "RiverpodService" lib/ | grep -v "riverpod_service.dart"
```

Convert remaining widgets that access RiverpodService.

### Phase 3: Performance Review (Week 3)

After Phases 1 & 2:

- Profile app performance
- Check for unnecessary rebuilds
- Optimize using `.select()` where needed
- Add `autoDispose` to temporary screens

---

## Code Example: When to Convert

### Example 1: KEEP as StatefulWidget

```dart
// ✅ GOOD - Keep as StatefulWidget
class LiveTime extends StatefulWidget {
  @override
  State<LiveTime> createState() => _LiveTimeState();
}

class _LiveTimeState extends State<LiveTime> {
  late Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() { ... }); // Only updates UI
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

// ❌ NO need to convert - this is not data access
```

### Example 2: CONVERT to ConsumerStatefulWidget

```dart
// ❌ BAD - Uses ServiceLocator
class CustomerDialogue extends StatefulWidget {
  @override
  State<CustomerDialogue> createState() => _CustomerDialogueState();
}

class _CustomerDialogueState extends State<CustomerDialogue> {
  final _customerFacade = ServiceLocator.get<CustomerFacade>();

  Future<void> saveCustomer() async {
    await _customerFacade.insert(customer); // Needs provider
  }
}

// ✅ GOOD - Convert to ConsumerStatefulWidget
class CustomerDialogue extends ConsumerStatefulWidget {
  @override
  ConsumerState<CustomerDialogue> createState() => _CustomerDialogueState();
}

class _CustomerDialogueState extends ConsumerState<CustomerDialogue> {
  Future<void> saveCustomer() async {
    final customerFacade = ref.read(customerProvider); // Use provider
    await customerFacade.insert(customer);
  }
}
```

### Example 3: Convert Simple Button

```dart
// ❌ BEFORE - Accessing facade
class DeleteButton extends StatefulWidget {
  @override
  State<DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<DeleteButton> {
  late final _itemFacade = ServiceLocator.get<ItemFacade>();

  void _delete() async {
    await _itemFacade.delete(itemId);
  }
}

// ✅ AFTER - Using provider
class DeleteButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends ConsumerState<DeleteButton> {
  void _delete() async {
    final itemFacade = ref.read(itemProvider);
    await itemFacade.delete(itemId);
  }
}
```

---

## Common Pitfalls to Avoid

### ❌ DON'T: Convert every StatefulWidget

```dart
// BAD - Unnecessary conversion
class SimpleCounter extends ConsumerStatefulWidget {
  @override
  State<SimpleCounter> createState() => _SimpleCounterState();
}

class _SimpleCounterState extends ConsumerState<SimpleCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Never uses ref! Why convert?
    return Text('Count: $_count');
  }
}
```

### ✅ DO: Only convert if using ref

```dart
// GOOD - Only converts when needed
class SimpleBuildingBlock extends StatefulWidget {
  @override
  State<SimpleBuildingBlock> createState() => _SimpleBuildingBlockState();
}

class _SimpleBuildingBlockState extends State<SimpleBuildingBlock> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    // No ref needed, simple state is fine
    return Text('Count: $_count');
  }
}
```

### ❌ DON'T: Over-nest Consumer widgets

```dart
// BAD - Creates multiple layers
ConsumerWidget(
  child: ConsumerStatefulWidget(
    child: ConsumerWidget(...)
  )
)
```

### ✅ DO: Use single consumer at appropriate level

```dart
// GOOD - One level of consumer at top
ConsumerStatefulWidget(
  child: MyUI() // All descendants can use context/ref
)
```

---

## Summary: Conversion Checklist

### Widgets TO CONVERT (Add to Priority List)

- [ ] GlobalBarcodeListener - Uses ServiceLocator
- [ ] ShiftScreen - Uses ShiftFacade
- [ ] LoginScreen - Uses UserFacade
- [ ] CustomerDialogue - Uses CustomerFacade
- [ ] HomeReceiptScreen - Uses ReceiptFacade
- [ ] SettingReceiptScreen - Uses PrinterSettingFacade
- [ ] All dialogs with insert/update/delete operations
- [ ] All screens that query/manipulate data
- [ ] All components that access facades

**Count**: ~30 widgets

### Widgets TO KEEP (Do NOT Convert)

- [ ] All TimerWidget-based (LiveTime, etc.)
- [ ] All AnimationWidget-based (RollingText, etc.)
- [ ] All FormField wrappers (TextFieldBlocBuilder, etc.)
- [ ] All generic reusable UI components (ButtonBottom, etc.)
- [ ] All low-level widgets without business logic

**Count**: ~40 widgets

---

## Performance Implications

| Conversion Type                  | Performance Impact                               | Recommendation |
| -------------------------------- | ------------------------------------------------ | -------------- |
| Convert necessary (30 widgets)   | +2-5% memory (provider overhead)                 | ✅ DO IT       |
| Convert unnecessary (40 widgets) | +1-2% memory (wasted)                            | ❌ DON'T       |
| Keep necessary as StatefulWidget | -5-10% performance issues (RiverpodService hack) | ❌ BAD         |

**Bottom line**: Converting the RIGHT ~30 widgets will improve performance by removing the RiverpodService hack. Converting the unnecessary ~40 will add tiny overhead but is harmless.

---

## Recommended Action Plan

1. **Identify widgets using ServiceLocator** (grep search)
2. **Convert only those** to ConsumerStatefulWidget
3. **Replace ServiceLocator.get()** with `ref.watch/read(provider)`
4. **Test each conversion** (build + run basic test)
5. **Profile & benchmark** after conversion complete
6. **Leave pure UI widgets alone**

**Estimated conversion time**: 2-3 hours for ~30 critical widgets

---

## Detailed Widget Conversion List

### Priority 1: Core Business Logic (Start Here)

These are most critical - accessed by multiple users daily:

1. **`GlobalBarcodeListener.dart`**

   - Current: `ServiceLocator.get<BarcodeScannerNotifier>()`
   - Convert to: `ref.watch(barcodeScannerProvider)`
   - Impact: HIGH - used globally for all barcode operations

2. **`ShiftScreen.dart`**

   - Current: `ServiceLocator.get<ShiftFacade>()`
   - Convert to: `ref.watch(shiftProvider)`
   - Impact: HIGH - core POS screen

3. **`LoginScreen.dart`**

   - Current: `ServiceLocator.get<UserFacade>()`
   - Convert to: `ref.watch(userProvider)`
   - Impact: HIGH - every session starts here

4. **`CustomerDialogue.dart` (entire directory)**
   - Current: Multiple `ServiceLocator.get<CustomerFacade>()`
   - Convert to: `ref.watch(customerProvider)`
   - Impact: HIGH - customer operations

### Priority 2: Feature Screens (Do After Priority 1)

Mid-level importance:

5. **`HomeReceiptScreen.dart`**

   - Current: `ServiceLocator.get<ReceiptFacade>()`
   - Impact: MEDIUM - frequently used

6. **`SettingReceiptScreen.dart`**

   - Current: `ServiceLocator.get<ReceiptSettingsFacade>()`
   - Impact: MEDIUM - settings screen

7. **All shift history components**
   - Location: `shift_history/components/*.dart`
   - Current: Multiple facades
   - Impact: MEDIUM - analytics/reporting

### Priority 3: Component Updates (Do After Priority 2)

Lower-level components:

8. **`shift_screen/components/` (all)**

   - `cash_drawer.dart` - `ServiceLocator.get<PaymentFacade>()`
   - `sales_summary.dart` - `ServiceLocator.get<SaleFacade>()`
   - `open_shift_dialogue.dart` - Multiple facades
   - Impact: LOW - sub-components

9. **`payment/components/` (selected)**

   - `balance_payment_dialogue.dart`
   - Impact: LOW

10. **`sales/components/` (selected)**
    - `discount_item.dart`
    - Impact: LOW

---

## Widget Conversion Reference Template

Use this template when converting each widget:

```dart
// BEFORE
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/domain/facades/[facade_name].dart';

class [WidgetName] extends StatefulWidget {
  @override
  State<[WidgetName]> createState() => _[WidgetName]State();
}

class _[WidgetName]State extends State<[WidgetName]> {
  final _facade = ServiceLocator.get<[FacadeType]>();

  Future<void> someMethod() async {
    await _facade.someOp();
  }
}

// AFTER
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/providers/riverpod/[domain]/[domain]_providers.dart';

class [WidgetName] extends ConsumerStatefulWidget {
  @override
  ConsumerState<[WidgetName]> createState() => _[WidgetName]State();
}

class _[WidgetName]State extends ConsumerState<[WidgetName]> {
  Future<void> someMethod() async {
    final facade = ref.read([facadeNameProvider]);
    await facade.someOp();
  }
}
```

---

## Migration Validation Checklist

For each converted widget:

- [ ] Import changed from `State<T>` to `ConsumerState<T>`
- [ ] Class now extends `ConsumerStatefulWidget`
- [ ] State class method signature updated: `build(BuildContext context, WidgetRef ref)`
- [ ] All `ServiceLocator.get<>()` removed
- [ ] All replaced with `ref.watch()` or `ref.read()`
- [ ] Widget builds without errors
- [ ] Functionality works as before
- [ ] No new rebuild loops observed
- [ ] No missing provider definitions

---

## Testing Each Conversion

After converting a widget:

```bash
# 1. Build the app
flutter pub get
flutter build apk --debug 2>&1 | grep -i error

# 2. Run the app
flutter run

# 3. Test the specific feature (manually)
# - For shift screen: Open/close shift
# - For customer: Add/edit/delete customer
# - For receipt: Print/email receipt

# 4. Check logs for errors
flutter logs | grep -i "error\|exception"

# 5. Observe rebuilds (optional - use DevTools)
# - Open DevTools
# - Check Performance tab for rebuild storms
```

---

## Post-Migration Optimization

After all conversions are complete:

1. **Profile the app**

   ```bash
   flutter run --profile
   # Use DevTools to check frame rates, memory usage
   ```

2. **Check for rebuild issues**

   ```dart
   // In providers, use .select() for fine-grained updates
   // BEFORE
   final state = ref.watch(itemProvider);

   // AFTER (if you only need count)
   final count = ref.watch(itemProvider.select((state) => state.items.length));
   ```

3. **Add autoDispose to temporary providers**

   ```dart
   // For dialogs, temporary screens
   final temporaryDataProvider = FutureProvider.autoDispose<Data>((ref) async {
     return fetchData();
   });
   ```

4. **Benchmark before/after**
   - Memory usage
   - Frame render time
   - Provider rebuild frequency
   - RiverpodService removed = performance gain

---

## Rollback Strategy

If a conversion breaks something:

```bash
# 1. Identify broken widget (app crashes, feature doesn't work)
# 2. Revert conversion using git
git checkout HEAD -- path/to/widget.dart

# 3. Investigate issue
# - Was provider not created?
# - Is provider not injected?
# - Is facade logic broken?

# 4. Fix provider/facade, then retry conversion
```

---

## Summary Table: All Widgets Status

| Widget                | Category  | Current                | Action  | Priority |
| --------------------- | --------- | ---------------------- | ------- | -------- |
| LiveTime              | Timer     | StatefulWidget         | KEEP    | -        |
| ButtonBottom          | Button    | StatefulWidget         | KEEP    | -        |
| RollingText           | Animation | StatefulWidget         | KEEP    | -        |
| GlobalBarcodeListener | Global    | StatefulWidget         | CONVERT | P1       |
| ShiftScreen           | Screen    | StatefulWidget         | CONVERT | P1       |
| LoginScreen           | Screen    | StatefulWidget         | CONVERT | P1       |
| CustomerDialogue      | Dialog    | StatefulWidget         | CONVERT | P1       |
| SalesScreen           | Screen    | ConsumerStatefulWidget | KEEP    | -        |
| PaymentScreen         | Screen    | ConsumerStatefulWidget | KEEP    | -        |
| HiveBoxDetailsPage    | Debug     | StatefulWidget         | DEFER   | -        |
| ...                   | ...       | ...                    | ...     | ...      |

---

## Implementation Command Reference

```bash
# Find all StatefulWidget using ServiceLocator
grep -r "class.*extends StatefulWidget" lib/ | xargs grep -l "ServiceLocator.get"

# Count widgets to convert
grep -r "class.*extends StatefulWidget" lib/ | xargs grep -l "ServiceLocator.get" | wc -l

# Find specific facades being used
grep -r "ServiceLocator.get<.*Facade>" lib/ | sort | uniq

# Verify all RiverpodService removed (after conversion)
grep -r "RiverpodService" lib/ --include="*.dart" | grep -v "riverpod_service.dart"
```

---

## Final Recommendations

1. **Don't rush** - Convert ~5 widgets per session, test thoroughly
2. **Keep pure UI widgets as StatefulWidget** - No downside to keeping them
3. **Focus on business-logic widgets first** - They give most ROI
4. **Profile before and after** - Verify improvements
5. **Leave architecture for Phase 3** - These conversions are Phase 1 (removing RiverpodService), not Phase 3 (full Riverpod migration)
