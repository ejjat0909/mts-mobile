# Project Architecture Guide

## Table of Contents

1. [Overview](#overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Project Structure](#project-structure)
4. [Dependency Injection - Service Locator](#dependency-injection---service-locator)
5. [State Management - Riverpod](#state-management---riverpod)
6. [Data Layer](#data-layer)
7. [Domain Layer](#domain-layer)
8. [Presentation Layer](#presentation-layer)
9. [Core Services](#core-services)
10. [Sync Architecture](#sync-architecture)
11. [Setup Guide for New Projects](#setup-guide-for-new-projects)
12. [Best Practices](#best-practices)

---

## Overview

This is a **Point of Sale (POS) System** built with Flutter using a **Clean Architecture** approach with **hybrid dependency injection** combining:

- **GetIt (Service Locator)** for singleton services and datasources
- **Riverpod** for state management and reactive features

### Key Technologies

- **Flutter SDK**: ^3.7.2
- **State Management**: Riverpod ^2.6.1 + Provider ^6.1.2
- **Dependency Injection**: GetIt ^8.0.3
- **Local Database**: SQLite (sqflite ^2.4.2)
- **Caching**: Hive ^2.2.3 + Hive Flutter ^1.1.0
- **Secure Storage**: Flutter Secure Storage ^9.0.0 + Encrypted Shared Preferences ^3.0.1
- **Network**: Dio ^5.8.0+1 + HTTP ^1.3.0
- **Real-time Communication**: Pusher Channels Flutter ^2.4.0
- **Localization**: Easy Localization ^3.0.7+1
- **Forms**: Flutter Form Bloc + Reactive Forms ^17.0.1

---

## Architecture Pattern

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│              Presentation Layer                      │
│  ┌──────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │   Screens    │  │   Widgets   │  │ Form Blocs │ │
│  └──────────────┘  └─────────────┘  └────────────┘ │
│            ▲                  ▲                      │
│            │     Riverpod     │                      │
│            │    Providers     │                      │
└────────────┼──────────────────┼──────────────────────┘
             │                  │
┌────────────┼──────────────────┼──────────────────────┐
│            ▼                  ▼      Domain Layer    │
│  ┌──────────────────┐  ┌─────────────────────────┐ │
│  │   Repositories    │  │   Services (Business)   │ │
│  │   (Interfaces)    │  │        Logic            │ │
│  └──────────────────┘  └─────────────────────────┘ │
└────────────┬──────────────────┬──────────────────────┘
             │                  │
┌────────────┼──────────────────┼──────────────────────┐
│            ▼                  ▼      Data Layer      │
│  ┌──────────────────┐  ┌─────────────────────────┐ │
│  │  Repository Impl  │  │     Data Sources        │ │
│  │   (Local/Remote)  │  │  (Local/Remote/Cache)   │ │
│  └──────────────────┘  └─────────────────────────┘ │
│            ▲                  ▲                      │
│            │   Service Locator │                     │
└────────────┼──────────────────┼──────────────────────┘
             │                  │
┌────────────┼──────────────────┼──────────────────────┐
│            ▼                  ▼      Core Layer      │
│  ┌──────────────────┐  ┌─────────────────────────┐ │
│  │  Network Client   │  │   Storage (SQLite +     │ │
│  │   (Dio/HTTP)      │  │   Hive + SecureStore)   │ │
│  └──────────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### Hybrid Dependency Injection Strategy

1. **Service Locator (GetIt)** - Used for:
   - Core services (Database, Network, Storage)
   - Datasources (API, Local, Remote)
   - Singleton models (User, Outlet, Device)
   - Infrastructure components

2. **Riverpod Providers** - Used for:
   - State management (StateNotifier)
   - Reactive data streams
   - Repository layer
   - Business logic services
   - UI-related state

---

## Project Structure

```
lib/
├── main.dart                          # Application entry point
├── app/
│   ├── app.dart                       # Main app widget
│   ├── di/
│   │   ├── service_locator.dart       # GetIt service locator setup
│   │   └── service_locator_pusher_extension.dart
│   └── theme/                         # App theme configuration
│
├── core/                              # Core utilities and services
│   ├── adapters/                      # Data adapters
│   ├── assets/                        # Asset path constants
│   ├── config/                        # App configuration
│   ├── constants/                     # Constants
│   ├── enum/ & enums/                 # Enumerations
│   ├── error/                         # Error handling
│   ├── interfaces/                    # Core interfaces
│   ├── mixins/                        # Reusable mixins
│   ├── network/                       # Network layer (ApiClient, WebService)
│   ├── services/                      # Core services
│   │   ├── repository_crud_service.dart     # Generic CRUD operations
│   │   ├── hive_box_manager.dart            # Hive cache manager
│   │   ├── database_index_manager.dart      # Database indexing
│   │   └── ...
│   ├── storage/                       # Storage layer
│   │   ├── secure_storage_api.dart          # Encrypted storage
│   │   └── hive_box_manager.dart
│   ├── sync/                          # Sync engine
│   │   ├── app_sync_service.dart            # Main sync orchestrator
│   │   ├── sync_policy.dart
│   │   ├── sync_reason.dart
│   │   └── sync_state.dart
│   └── utils/                         # Utility functions
│
├── data/                              # Data layer implementation
│   ├── datasources/
│   │   ├── local/                     # Local data sources
│   │   │   ├── database_helpers.dart        # SQLite helpers
│   │   │   ├── database_helpers_interface.dart
│   │   │   └── storage_datasource.dart
│   │   └── remote/                    # Remote data sources
│   │       ├── api_datasource.dart
│   │       ├── auth_datasource.dart
│   │       └── pusher_datasource.dart
│   │
│   ├── models/                        # Data models
│   │   ├── customer/
│   │   │   ├── customer_model.dart
│   │   │   └── customer_list_response_model.dart
│   │   ├── meta_model.dart
│   │   └── ... (other domain models)
│   │
│   ├── repositories/                  # Repository implementations
│   │   ├── local/
│   │   │   ├── local_customer_repository_impl.dart
│   │   │   ├── local_item_repository_impl.dart
│   │   │   └── ... (all local repositories)
│   │   └── remote/
│   │       ├── sync_repository_impl.dart
│   │       └── ... (all remote repositories)
│   │
│   └── services/                      # Data layer services
│       ├── sync_service.dart
│       └── sync/                      # Entity sync handlers
│           ├── customer_sync_handler.dart
│           ├── item_sync_handler.dart
│           └── ... (all sync handlers)
│
├── domain/                            # Business logic layer
│   ├── repositories/                  # Repository interfaces
│   │   ├── local/
│   │   │   ├── customer_repository.dart
│   │   │   └── ... (all local repository interfaces)
│   │   └── remote/
│   │       ├── sync_repository.dart
│   │       └── ... (all remote repository interfaces)
│   │
│   └── services/                      # Domain services
│       └── realtime/
│           └── websocket_service.dart
│
├── providers/                         # Riverpod state management
│   ├── app/
│   │   ├── app_providers.dart         # App-level providers
│   │   └── app_state.dart
│   ├── customer/
│   │   ├── customer_providers.dart    # Customer domain providers
│   │   └── customer_state.dart
│   ├── services/
│   │   └── service_providers.dart     # Service providers
│   └── ... (all domain providers)
│
├── presentation/                      # UI layer
│   ├── common/                        # Shared UI components
│   │   ├── dialogs/
│   │   ├── layouts/
│   │   └── widgets/
│   └── features/                      # Feature-based screens
│       ├── after_login/
│       ├── login/
│       ├── activate_license/
│       └── ... (all feature screens)
│
├── form_bloc/                         # Form state management
│   ├── add_customer_form_bloc.dart
│   ├── login_form_bloc.dart
│   └── ... (all form blocs)
│
├── widgets/                           # Reusable widgets
│   ├── global_barcode_listener.dart
│   ├── sync_indicator.dart
│   └── ...
│
└── migrations/                        # Database migrations
    └── migration_runner.dart
```

---

## Dependency Injection - Service Locator

### What is Service Locator?

The Service Locator pattern uses **GetIt** to provide a centralized registry for accessing singleton instances throughout the app without passing dependencies through constructors.

### Setup Service Locator

#### 1. Initialize in main.dart

```dart
import 'package:mts/app/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator
  ServiceLocator.init();

  // Use registered services
  final dbHelper = ServiceLocator.get<IDatabaseHelpers>();
  await dbHelper.initializeDatabaseWithMigrations();

  runApp(MyApp());
}
```

#### 2. Define Service Locator (lib/app/di/service_locator.dart)

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// Initialize all dependencies
  static void init() {
    // Register storage
    _getIt.registerLazySingleton<SecureStorageApi>(
      () => SecureStorageApi(),
    );

    // Register network client
    _getIt.registerLazySingleton<ApiClient>(
      () => ApiClient(secureStorage: _getIt<SecureStorageApi>()),
    );

    // Register Dio
    _getIt.registerLazySingleton<Dio>(
      () => Dio(BaseOptions(
        baseUrl: versionApiUrl,
        connectTimeout: kDefaultTimeout,
        receiveTimeout: kDefaultTimeout,
      )),
    );

    // Register WebService
    _getIt.registerLazySingleton<IWebService>(
      () => WebService(
        secureStorage: _getIt<SecureStorageApi>(),
        baseUrl: versionApiUrl,
        apiKey: apiKey,
      ),
    );

    // Register datasources
    _getIt.registerLazySingleton<AuthDatasource>(
      () => AuthDatasource(
        apiClient: _getIt<ApiClient>(),
        secureStorage: _getIt<SecureStorageApi>(),
      ),
    );

    _getIt.registerLazySingleton<StorageDatasource>(
      () => StorageDatasource(secureStorage: _getIt<SecureStorageApi>()),
    );

    _getIt.registerLazySingleton<ApiDatasource>(
      () => ApiDatasource(secureStorage: _getIt<SecureStorageApi>()),
    );

    // Register database
    _getIt.registerLazySingleton<IDatabaseHelpers>(
      () => DatabaseHelpers(),
    );

    // Register repositories
    _getIt.registerLazySingleton<SyncRepository>(
      () => SyncRepositoryImpl(),
    );
  }

  /// Get a registered instance
  static T get<T extends Object>() => _getIt<T>();

  /// Check if a type is registered
  static bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  /// Register a singleton instance
  static void registerSingleton<T extends Object>(T instance) {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
    _getIt.registerSingleton<T>(instance);
  }

  /// Unregister an instance
  static void unregister<T extends Object>() {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
  }

  /// Reset all registered instances
  static Future<void> resetAll() async {
    await _getIt.reset();
  }
}
```

### How to Use Service Locator

#### Basic Usage

```dart
// Get a service
final apiClient = ServiceLocator.get<ApiClient>();
final storage = ServiceLocator.get<SecureStorageApi>();
final database = ServiceLocator.get<IDatabaseHelpers>();

// Check if registered
if (ServiceLocator.isRegistered<MyService>()) {
  final service = ServiceLocator.get<MyService>();
}

// Register dynamic singleton
ServiceLocator.registerSingleton<UserModel>(userModel);

// Later, retrieve it
final user = ServiceLocator.get<UserModel>();
```

#### In Constructors

```dart
class AuthDatasource {
  final ApiClient _apiClient;
  final SecureStorageApi _secureStorage;

  AuthDatasource({
    required ApiClient apiClient,
    required SecureStorageApi secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage;
}
```

#### Direct Access Pattern

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final storage = ServiceLocator.get<SecureStorageApi>();

    return FutureBuilder(
      future: storage.read(key: 'token'),
      builder: (context, snapshot) {
        // Use the data
      },
    );
  }
}
```

---

## State Management - Riverpod

### What is Riverpod?

Riverpod is a complete rewrite of Provider that offers:

- **Compile-safe** dependency injection
- **No BuildContext** required
- **Better testing** capabilities
- **Type-safe** providers

### Setup Riverpod

#### 1. Wrap App with ProviderScope

```dart
void main() {
  runApp(
    ProviderScope(  // Riverpod root
      child: MyApp(),
    ),
  );
}
```

#### 2. Define Providers

##### Provider (Immutable)

```dart
// Service provider
final remotePaginationServiceProvider = Provider<RemotePaginationService>((ref) {
  return RemotePaginationService();
});

// Computed provider
final sortedCustomersProvider = Provider<List<CustomerModel>>((ref) {
  final items = ref.watch(customerProvider).items;
  return List<CustomerModel>.from(items)
    ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
});
```

##### StateNotifierProvider (Mutable State)

```dart
// State class
class CustomerState {
  final List<CustomerModel> items;
  final bool isLoading;
  final String? error;

  const CustomerState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerState copyWith({
    List<CustomerModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return CustomerState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// StateNotifier
class CustomerNotifier extends StateNotifier<CustomerState> {
  final LocalCustomerRepository _localRepository;
  final CustomerRepository _remoteRepository;
  final IWebService _webService;

  CustomerNotifier({
    required LocalCustomerRepository localRepository,
    required CustomerRepository remoteRepository,
    required IWebService webService,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       super(const CustomerState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final customers = await _localRepository.getAll();
      state = state.copyWith(items: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<int> insert(CustomerModel model) async {
    state = state.copyWith(isLoading: true);
    final result = await _localRepository.insert(model);
    if (result > 0) {
      final updatedItems = [...state.items, model];
      state = state.copyWith(items: updatedItems, isLoading: false);
    }
    return result;
  }
}

// Provider definition
final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier(
    localRepository: ref.read(customerLocalRepoProvider),
    remoteRepository: ref.read(customerRemoteRepoProvider),
    webService: ServiceLocator.get<IWebService>(),
  );
});
```

##### FutureProvider (Async Data)

```dart
final customerByIdProvider = FutureProvider.family<CustomerModel?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(customerProvider.notifier);
  return await notifier.getById(id);
});
```

### How to Use Riverpod

#### ConsumerWidget

```dart
class CustomerListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state (rebuilds on change)
    final customerState = ref.watch(customerProvider);

    // Read once (no rebuild)
    final customers = ref.read(customerProvider).items;

    // Call methods
    ref.read(customerProvider.notifier).loadAll();

    if (customerState.isLoading) {
      return CircularProgressIndicator();
    }

    if (customerState.error != null) {
      return Text('Error: ${customerState.error}');
    }

    return ListView.builder(
      itemCount: customerState.items.length,
      itemBuilder: (context, index) {
        final customer = customerState.items[index];
        return ListTile(title: Text(customer.name ?? ''));
      },
    );
  }
}
```

#### ConsumerStatefulWidget

```dart
class CustomerFormScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadAll();
    });
  }

  Future<void> _saveCustomer() async {
    final notifier = ref.read(customerProvider.notifier);
    final customer = CustomerModel(name: _nameController.text);
    await notifier.insert(customer);
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);

    return Scaffold(
      body: Column(
        children: [
          TextField(controller: _nameController),
          ElevatedButton(
            onPressed: customerState.isLoading ? null : _saveCustomer,
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

#### Provider with Dependency Injection

```dart
// Repository provider
final customerLocalRepoProvider = Provider<LocalCustomerRepository>((ref) {
  return LocalCustomerRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(customerBoxProvider),
  );
});

// Box provider
final customerBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(CustomerModel.modelBoxName);
});

// Database provider
final databaseHelpersProvider = Provider<IDatabaseHelpers>((ref) {
  return DatabaseHelpers();
});
```

---

## Data Layer

### Repository Pattern

#### Local Repository Interface (domain/repositories/local/)

```dart
abstract class LocalCustomerRepository {
  Future<int> insert(CustomerModel model, {required bool isInsertToPending});
  Future<int> update(CustomerModel model, {required bool isInsertToPending});
  Future<int> delete(String id, {required bool isInsertToPending});
  Future<List<CustomerModel>> getAll();
  Future<CustomerModel?> getById(String id);
  Future<bool> upsertBulk(List<CustomerModel> list, {required bool isInsertToPending});
}
```

#### Local Repository Implementation (data/repositories/local/)

```dart
class LocalCustomerRepositoryImpl implements LocalCustomerRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  static const String tableName = 'customers';

  LocalCustomerRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  @override
  Future<int> insert(CustomerModel model, {required bool isInsertToPending}) async {
    model.createdAt = DateTime.now();
    model.updatedAt = DateTime.now();

    // Insert to SQLite
    int result = await _dbHelper.insertDb(tableName, model.toJson());

    // Insert to Hive cache
    if (result > 0 && model.id != null) {
      await _hiveBox.put(model.id, model.toJson());
    }

    // Track pending changes
    if (isInsertToPending && model.id != null) {
      await _pendingChangesRepository.insert(
        PendingChangesModel(
          operation: PendingChangeOperation.created,
          modelName: CustomerModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        ),
      );
    }

    return result;
  }

  @override
  Future<List<CustomerModel>> getAll() async {
    // Try Hive cache first
    if (_hiveBox.isNotEmpty) {
      return _hiveBox.values
          .map((json) => CustomerModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    // Fallback to SQLite
    final db = await _dbHelper.database;
    final results = await db.query(tableName);
    return results.map((json) => CustomerModel.fromJson(json)).toList();
  }

  @override
  Future<CustomerModel?> getById(String id) async {
    // Check Hive cache
    final cached = _hiveBox.get(id);
    if (cached != null) {
      return CustomerModel.fromJson(Map<String, dynamic>.from(cached));
    }

    // Fallback to SQLite
    final db = await _dbHelper.database;
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final model = CustomerModel.fromJson(results.first);
      // Update cache
      await _hiveBox.put(id, model.toJson());
      return model;
    }

    return null;
  }
}
```

### Datasource Layer

#### Local Datasource (database_helpers.dart)

```dart
class DatabaseHelpers implements IDatabaseHelpers {
  static const String databaseName = 'mts.db';
  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables
    await LocalCustomerRepositoryImpl.createTable(db);
    // ... other tables
  }

  Future<int> insertDb(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryDb(String table) async {
    final db = await database;
    return await db.query(table);
  }
}
```

#### Remote Datasource (api_datasource.dart)

```dart
class ApiDatasource {
  final SecureStorageApi _secureStorage;
  final Dio _dio = Dio();

  ApiDatasource({required SecureStorageApi secureStorage})
      : _secureStorage = secureStorage;

  Future<Response> get(String endpoint) async {
    final token = await _secureStorage.read(key: 'access_token');
    final response = await _dio.get(
      endpoint,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }

  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    final token = await _secureStorage.read(key: 'access_token');
    final response = await _dio.post(
      endpoint,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response;
  }
}
```

---

## Domain Layer

### Use Cases / Business Logic

Domain services contain business logic and orchestrate data flow between repositories.

#### Example: WebSocket Service

```dart
class WebSocketService {
  final PusherDatasource _pusherDatasource;
  final LocalShiftRepository _shiftRepository;

  WebSocketService({
    required PusherDatasource pusherDatasource,
    required LocalShiftRepository shiftRepository,
  }) : _pusherDatasource = pusherDatasource,
       _shiftRepository = shiftRepository;

  Future<void> subscribeToLatestShift() async {
    final shift = await _shiftRepository.getLatestShift();
    if (shift != null) {
      await _pusherDatasource.subscribeToChannel('shift-${shift.id}');
    }
  }

  Future<void> handleShiftUpdate(Map<String, dynamic> data) async {
    final shiftModel = ShiftModel.fromJson(data);
    await _shiftRepository.update(shiftModel, isInsertToPending: false);
  }
}
```

---

## Presentation Layer

### Feature Structure

```
presentation/features/customer/
├── customer_list_screen.dart       # Main screen
├── customer_detail_screen.dart
├── customer_form_screen.dart
└── components/                     # Screen-specific widgets
    ├── customer_card.dart
    └── customer_filter_dialog.dart
```

### Screen Example

```dart
class CustomerListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final sortedCustomers = ref.watch(sortedCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Customers')),
      body: customerState.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: sortedCustomers.length,
              itemBuilder: (context, index) {
                final customer = sortedCustomers[index];
                return CustomerCard(customer: customer);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/customer/add'),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## Core Services

### 1. Repository CRUD Service

Generic CRUD service to eliminate code duplication:

```dart
class RepositoryCrudService {
  static const int defaultChunkSize = 500;

  Future<int> insert<T>(CrudConfig<T> config, T model) async {
    var id = config.getId(model);
    if (id == null) {
      id = IdUtils.generateUUID();
      config.setId(model, id);
    }

    config.setTimestamps(model);
    final modelJson = config.toJson(model);

    final result = await config.db.transaction((txn) async {
      return await txn.insert(config.tableName, modelJson);
    });

    // Update cache
    if (config.cache != null) {
      await config.cache!.put(id, modelJson);
    }

    // Track pending changes
    if (config.trackPendingChanges && config.pendingChangesTracker != null) {
      await config.pendingChangesTracker!.track(
        PendingChangesModel(
          operation: PendingChangeOperation.created,
          modelName: config.modelName,
          modelId: id,
          data: jsonEncode(modelJson),
        ),
      );
    }

    return result;
  }
}
```

### 2. Hive Box Manager

Centralized Hive cache management:

```dart
class HiveBoxManager {
  static final Map<String, Box<Map>> _boxes = {};

  static Future<void> initializeAllBoxes() async {
    await _openBox(CustomerModel.modelBoxName);
    await _openBox(ItemModel.modelBoxName);
    // ... other boxes
  }

  static Future<void> _openBox(String boxName) async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      _boxes[boxName] = box;
    } catch (e) {
      prints('Error opening box $boxName: $e');
    }
  }

  static Box<Map> getValidatedBox(String boxName) {
    final box = _boxes[boxName];
    if (box == null) {
      throw Exception('Box $boxName not initialized');
    }
    return box;
  }

  static Future<void> clearAllBoxes() async {
    for (var box in _boxes.values) {
      await box.clear();
    }
  }
}
```

### 3. Secure Storage API

```dart
class SecureStorageApi {
  static const _boxName = 'secureBox';
  late Box<dynamic> _box;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _box = await Hive.openBox(_boxName, encryptionCipher: _cipher);
      _initialized = true;
    }
  }

  Future<String> read({String? key}) async {
    await _ensureInitialized();
    final value = _box.get(key ?? 'null');
    return value?.toString() ?? '';
  }

  Future<bool> write(String key, String value) async {
    await _ensureInitialized();
    await _box.put(key, value);
    return true;
  }

  Future<Map<String, dynamic>?> readObject(String key) async {
    final jsonString = await read(key: key);
    if (jsonString.isEmpty) return null;
    return jsonDecode(jsonString);
  }

  Future<bool> writeObject(String key, Map<String, dynamic> value) async {
    return await write(key, jsonEncode(value));
  }
}
```

---

## Sync Architecture

### App Sync Service

The `AppSyncService` orchestrates data synchronization:

```dart
class AppSyncService extends StateNotifier<SyncState> {
  final Ref ref;
  final SecureStorageApi _secureStorageApi;
  final SyncRepository _syncRepository;
  final IWebService _webService;

  late final Map<String, Future<void> Function()> _syncRegistry;

  AppSyncService({
    required this.ref,
    required SecureStorageApi secureStorageApi,
    required SyncRepository syncRepository,
    required IWebService webService,
  }) : super(const SyncState()) {
    _syncRegistry = {
      'customer': () => ref.read(customerProvider.notifier).syncFromServer(),
      'item': () => ref.read(itemProvider.notifier).syncFromServer(),
      // ... all entities
    };
  }

  Future<void> syncAll() async {
    state = state.copyWith(isSyncing: true, syncProgress: 0.0);

    int completed = 0;
    final total = _syncRegistry.length;

    for (var entry in _syncRegistry.entries) {
      try {
        await entry.value();
        completed++;
        state = state.copyWith(
          syncProgress: (completed / total) * 100,
          syncProgressText: 'Syncing ${entry.key}...',
        );
      } catch (e) {
        prints('Error syncing ${entry.key}: $e');
      }
    }

    state = state.copyWith(isSyncing: false, syncProgress: 100.0);
  }
}
```

### Entity Sync Handler

```dart
class CustomerSyncHandler {
  Future<void> handleCreated(Map<String, dynamic> data) async {
    final customer = CustomerModel.fromJson(data);
    final repo = ServiceLocator.get<LocalCustomerRepository>();
    await repo.insert(customer, isInsertToPending: false);
  }

  Future<void> handleUpdated(Map<String, dynamic> data) async {
    final customer = CustomerModel.fromJson(data);
    final repo = ServiceLocator.get<LocalCustomerRepository>();
    await repo.update(customer, isInsertToPending: false);
  }

  Future<void> handleDeleted(String id) async {
    final repo = ServiceLocator.get<LocalCustomerRepository>();
    await repo.delete(id, isInsertToPending: false);
  }
}
```

---

## Setup Guide for New Projects

### Step 1: Project Structure Setup

```bash
flutter create my_pos_app
cd my_pos_app

# Create folder structure
mkdir -p lib/app/di lib/app/theme
mkdir -p lib/core/{config,constants,network,services,storage,sync,utils}
mkdir -p lib/data/{datasources/{local,remote},models,repositories/{local,remote},services}
mkdir -p lib/domain/{repositories/{local,remote},services}
mkdir -p lib/presentation/{common,features}
mkdir -p lib/providers
mkdir -p lib/form_bloc
mkdir -p lib/widgets
mkdir -p lib/migrations
```

### Step 2: Add Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.6.1
  provider: ^6.1.2

  # Dependency Injection
  get_it: ^8.0.3

  # Database
  sqflite: ^2.4.2
  path: ^1.9.1

  # Cache
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Secure Storage
  flutter_secure_storage: ^9.0.0
  encrypted_shared_preferences: ^3.0.1

  # Network
  dio: ^5.8.0
  http: ^1.3.0

  # Real-time
  pusher_channels_flutter: ^2.4.0

  # Localization
  easy_localization: ^3.0.7
  intl: ^0.19.0

  # Forms
  flutter_bloc: ^9.1.1
  reactive_forms: ^17.0.1

  # Utilities
  uuid: ^4.5.1
  logger: ^1.1.0
  equatable: ^2.0.3
```

### Step 3: Initialize Service Locator

Create `lib/app/di/service_locator.dart`:

```dart
import 'package:get_it/get_it.dart';

class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  static void init() {
    // Register core services
    _getIt.registerLazySingleton<SecureStorageApi>(() => SecureStorageApi());
    _getIt.registerLazySingleton<IDatabaseHelpers>(() => DatabaseHelpers());
    _getIt.registerLazySingleton<ApiClient>(
      () => ApiClient(secureStorage: _getIt<SecureStorageApi>()),
    );
  }

  static T get<T extends Object>() => _getIt<T>();
  static bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();
}
```

### Step 4: Setup main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app/di/service_locator.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await HiveBoxManager.initializeAllBoxes();

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Initialize service locator
  ServiceLocator.init();

  // Initialize database
  final dbHelper = ServiceLocator.get<IDatabaseHelpers>();
  await dbHelper.initializeDatabaseWithMigrations();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: [Locale('en', 'US'), Locale('ms', 'MY')],
        path: 'assets/dictionary',
        fallbackLocale: Locale('en', 'US'),
        child: MyApp(),
      ),
    ),
  );
}
```

### Step 5: Create Domain Entity

#### Model (data/models/product/product_model.dart)

```dart
class ProductModel {
  static const String modelName = 'Product';
  static const String modelBoxName = 'product_box';

  String? id;
  String? name;
  double? price;
  DateTime? createdAt;
  DateTime? updatedAt;

  ProductModel({this.id, this.name, this.price, this.createdAt, this.updatedAt});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      price: json['price']?.toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
```

#### Repository Interface (domain/repositories/local/product_repository.dart)

```dart
abstract class LocalProductRepository {
  Future<int> insert(ProductModel model, {required bool isInsertToPending});
  Future<int> update(ProductModel model, {required bool isInsertToPending});
  Future<int> delete(String id, {required bool isInsertToPending});
  Future<List<ProductModel>> getAll();
  Future<ProductModel?> getById(String id);
}
```

#### Repository Implementation (data/repositories/local/local_product_repository_impl.dart)

```dart
class LocalProductRepositoryImpl implements LocalProductRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;

  static const String tableName = 'products';

  LocalProductRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper, _hiveBox = hiveBox;

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT,
        price REAL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  @override
  Future<int> insert(ProductModel model, {required bool isInsertToPending}) async {
    model.createdAt = DateTime.now();
    model.updatedAt = DateTime.now();

    final result = await _dbHelper.insertDb(tableName, model.toJson());

    if (result > 0 && model.id != null) {
      await _hiveBox.put(model.id, model.toJson());
    }

    return result;
  }

  @override
  Future<List<ProductModel>> getAll() async {
    if (_hiveBox.isNotEmpty) {
      return _hiveBox.values
          .map((json) => ProductModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    final db = await _dbHelper.database;
    final results = await db.query(tableName);
    return results.map((json) => ProductModel.fromJson(json)).toList();
  }
}
```

### Step 6: Create Riverpod Provider

#### State (providers/product/product_state.dart)

```dart
class ProductState {
  final List<ProductModel> items;
  final bool isLoading;
  final String? error;

  const ProductState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<ProductModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
```

#### Notifier (providers/product/product_providers.dart)

```dart
class ProductNotifier extends StateNotifier<ProductState> {
  final LocalProductRepository _localRepository;

  ProductNotifier({required LocalProductRepository localRepository})
      : _localRepository = localRepository,
        super(const ProductState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await _localRepository.getAll();
      state = state.copyWith(items: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<int> insert(ProductModel model) async {
    state = state.copyWith(isLoading: true);
    final result = await _localRepository.insert(model, isInsertToPending: true);
    if (result > 0) {
      final updatedItems = [...state.items, model];
      state = state.copyWith(items: updatedItems, isLoading: false);
    }
    return result;
  }
}

// Providers
final productBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ProductModel.modelBoxName);
});

final productLocalRepoProvider = Provider<LocalProductRepository>((ref) {
  return LocalProductRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(productBoxProvider),
  );
});

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(
    localRepository: ref.read(productLocalRepoProvider),
  );
});
```

### Step 7: Use in UI

```dart
class ProductListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: productState.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: productState.items.length,
              itemBuilder: (context, index) {
                final product = productState.items[index];
                return ListTile(
                  title: Text(product.name ?? ''),
                  subtitle: Text('\$${product.price}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(productProvider.notifier).insert(
            ProductModel(id: uuid.v4(), name: 'New Product', price: 10.0),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## Best Practices

### 1. Dependency Injection

- **Use Service Locator for**: Core infrastructure (database, network, storage)
- **Use Riverpod for**: Business logic, repositories, state management
- **Avoid mixing**: Don't use ServiceLocator inside Riverpod providers if you can use `ref.read()` instead

### 2. State Management

- **StateNotifier**: For mutable state (lists, complex objects)
- **Provider**: For immutable services and computed values
- **FutureProvider**: For one-time async operations
- **StreamProvider**: For real-time data streams

### 3. Repository Pattern

- Always define interfaces in `domain/repositories`
- Implement in `data/repositories`
- Use dependency injection via Riverpod providers
- Keep repositories focused on single entities

### 4. Error Handling

```dart
try {
  state = state.copyWith(isLoading: true);
  final result = await _repository.fetch();
  state = state.copyWith(items: result, isLoading: false);
} catch (e) {
  state = state.copyWith(isLoading: false, error: e.toString());
  LogUtils.error('Failed to fetch data', e);
}
```

### 5. Testing

```dart
void main() {
  test('ProductNotifier loads products', () async {
    final mockRepo = MockProductRepository();
    when(mockRepo.getAll()).thenAnswer((_) async => [ProductModel()]);

    final notifier = ProductNotifier(localRepository: mockRepo);
    await notifier.loadAll();

    expect(notifier.state.items.length, 1);
    expect(notifier.state.isLoading, false);
  });
}
```

### 6. Performance Optimization

- Use Hive for caching frequently accessed data
- Implement pagination for large lists
- Use `const` constructors where possible
- Lazy-load providers with `registerLazySingleton`

### 7. Code Organization

- One feature, one folder
- Keep files small and focused
- Use meaningful names
- Follow consistent naming conventions:
  - Models: `*_model.dart`
  - Repositories: `*_repository.dart` (interface), `*_repository_impl.dart` (implementation)
  - Providers: `*_providers.dart`
  - States: `*_state.dart`
  - Screens: `*_screen.dart`

---

## Summary

This architecture provides:

✅ **Separation of Concerns**: Clean separation between UI, business logic, and data
✅ **Testability**: Easy to mock and test individual components
✅ **Scalability**: Modular structure that grows with your project
✅ **Maintainability**: Clear conventions and patterns
✅ **Performance**: Efficient caching with Hive + SQLite
✅ **Type Safety**: Compile-time safety with Riverpod
✅ **Flexibility**: Hybrid DI allows choosing the right tool for each job

By following this guide, you can build robust, maintainable Flutter applications with a solid architectural foundation.
