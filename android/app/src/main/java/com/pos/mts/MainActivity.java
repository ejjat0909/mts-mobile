package com.pos.mts;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.annotation.SuppressLint;
import android.app.Presentation;
import android.content.Context;
import android.hardware.display.DisplayManager;
import android.os.Build;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbInterface;
import android.hardware.usb.UsbEndpoint;
import android.hardware.usb.UsbConstants;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Display;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;
import java.util.Set;
import java.util.HashSet;

import java.util.ArrayList;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
// import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity implements ActivityAware {

    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "presentation_displays_plugin";
    private static final String EVENT_CHANNEL = "com.pos.mts/event_channel";
    MethodChannel flutterEngineChannel;
    private Context context;
    private DisplayManager displayManager;
    private HashMap<Integer, Presentation> presentations = new HashMap<>();

    private static final String GATT_CHANNEL = "bluetooth_gatt_utils"; // Add this
    private static final String THERMAL_PRINTER_CHANNEL = "flutter_thermal_printer"; // Add this
    private static final String THERMAL_PRINTER_EVENT_CHANNEL = "flutter_thermal_printer/events"; // Add this
    private BluetoothGatt currentGatt; // Add this
    private final BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

    // Track connected USB printers
    private Set<String> connectedPrinters = new HashSet<>();

    // USB permission handling
    private static final String ACTION_USB_PERMISSION = "com.pos.mts.USB_PERMISSION";
    private Result pendingPrintResult;
    private String pendingVendorId;
    private String pendingProductId;
    private List<Integer> pendingPrintData;
    private String pendingPrintPath;

    // USB device listener
    private ThermalPrinterEventStreamHandler thermalPrinterEventHandler;
    private BroadcastReceiver usbDeviceReceiver;

    private final BroadcastReceiver usbReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (ACTION_USB_PERMISSION.equals(action)) {
                synchronized (this) {
                    UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        if (device != null) {
                            Log.d(TAG, "USB permission granted for device: " + device.getDeviceName());
                            // Check if this is a print request or just a permission request
                            if (pendingPrintResult != null) {
                                if (pendingPrintData != null && pendingPrintPath != null) {
                                    // This is a print request - proceed with actual printing
                                    performActualPrint(pendingVendorId, pendingProductId, pendingPrintData,
                                            pendingPrintPath, pendingPrintResult);
                                } else {
                                    // This is just a permission request - return success
                                    pendingPrintResult.success(true);
                                }
                            }
                        }
                    } else {
                        Log.e(TAG, "USB permission denied");
                        if (pendingPrintResult != null) {
                            if (pendingPrintData != null && pendingPrintPath != null) {
                                pendingPrintResult.error("USB_PERMISSION_DENIED", "User denied USB permission", null);
                            } else {
                                // This is just a permission request - return false
                                pendingPrintResult.success(false);
                            }
                        }
                    }
                    // Clear pending data
                    clearPendingPrintData();
                }
            }
        }
    };

    // USB device attach/detach receiver
    private void initializeUsbDeviceReceiver() {
        usbDeviceReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();

                if (UsbManager.ACTION_USB_DEVICE_ATTACHED.equals(action)) {
                    UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (device != null && isPrinterDevice(device)) {
                        Log.d(TAG, "USB printer attached: " + device.getDeviceName());
                        handleUsbPrinterConnected(device);
                    }
                } else if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action)) {
                    UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (device != null && isPrinterDevice(device)) {
                        Log.d(TAG, "USB printer detached: " + device.getDeviceName());
                        handleUsbPrinterDisconnected(device);
                    }
                }
            }
        };
    }

    // Register USB device receiver
    private void registerUsbDeviceReceiver() {
        if (usbDeviceReceiver != null) {
            IntentFilter filter = new IntentFilter();
            filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED);
            filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(usbDeviceReceiver, filter, Context.RECEIVER_EXPORTED);
            } else {
                registerReceiver(usbDeviceReceiver, filter);
            }
            Log.d(TAG, "USB device receiver registered at activity level");
        }
    }

    // Check if the USB device is a printer (supports various thermal printer types)
    private boolean isPrinterDevice(UsbDevice device) {
        // Check USB class 7 (Printer class)
        for (int i = 0; i < device.getInterfaceCount(); i++) {
            UsbInterface usbInterface = device.getInterface(i);
            if (usbInterface.getInterfaceClass() == 7) { // USB_CLASS_PRINTER
                Log.d(TAG, "Device is printer (USB class 7)");
                return true;
            }
        }

        int vendorId = device.getVendorId();
        int productId = device.getProductId();

        // Check for common thermal printer vendor IDs
        switch (vendorId) {
            case 0x04b8: // Epson
                Log.d(TAG, "Detected Epson printer (VID: 0x04b8)");
                return true;
            case 0x0519: // Star Micronics
                Log.d(TAG, "Detected Star Micronics printer (VID: 0x0519)");
                return true;
            case 0x1d90: // Citizen
                Log.d(TAG, "Detected Citizen printer (VID: 0x1d90)");
                return true;
            case 0x0471: // Philips (some thermal printers)
                Log.d(TAG, "Detected Philips thermal printer (VID: 0x0471)");
                return true;
            case 0x0fe6: // iMin devices (including Swan 2 Pro)
                Log.d(TAG, "Detected iMin device (VID: 0x0fe6) - ProductID: " + productId);
                return true;
            case 0x25a7: // Alternative iMin vendor ID
                Log.d(TAG, "Detected iMin device (VID: 0x25a7)");
                return true;
            default:
                Log.d(TAG, "Unknown vendor ID: 0x" + Integer.toHexString(vendorId));
                return false;
        }
    }

    // Handle USB printer connection
    private void handleUsbPrinterConnected(UsbDevice device) {
        String vendorId = String.valueOf(device.getVendorId());
        String productId = String.valueOf(device.getProductId());
        String printerId = vendorId + ":" + productId;

        Log.d(TAG, "Attempting to connect to USB printer: " + printerId);

        // Call connectThermalPrinter method
        connectThermalPrinter(vendorId, productId, new MethodChannel.Result() {
            @Override
            public void success(Object result) {
                Log.d(TAG, "Auto-connected to USB printer: " + printerId);

                // Send event to Flutter
                if (thermalPrinterEventHandler != null) {
                    HashMap<String, Object> eventData = new HashMap<>();
                    eventData.put("event", "connected");
                    eventData.put("vendorId", vendorId);
                    eventData.put("productId", productId);
                    eventData.put("deviceName", device.getDeviceName());
                    thermalPrinterEventHandler.sendUsbDeviceEvent(eventData);
                }
            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                Log.e(TAG, "Failed to auto-connect to USB printer: " + errorMessage);

                // Send error event to Flutter
                if (thermalPrinterEventHandler != null) {
                    HashMap<String, Object> eventData = new HashMap<>();
                    eventData.put("event", "connection_failed");
                    eventData.put("vendorId", vendorId);
                    eventData.put("productId", productId);
                    eventData.put("deviceName", device.getDeviceName());
                    eventData.put("error", errorMessage);
                    thermalPrinterEventHandler.sendUsbDeviceEvent(eventData);
                }
            }

            @Override
            public void notImplemented() {
                Log.w(TAG, "connectThermalPrinter not implemented");
            }
        });
    }

    // Handle USB printer disconnection
    private void handleUsbPrinterDisconnected(UsbDevice device) {
        String vendorId = String.valueOf(device.getVendorId());
        String productId = String.valueOf(device.getProductId());
        String printerId = vendorId + ":" + productId;

        Log.d(TAG, "USB printer disconnected: " + printerId);

        // Remove from connected printers set
        connectedPrinters.remove(printerId);

        // Send event to Flutter
        if (thermalPrinterEventHandler != null) {
            HashMap<String, Object> eventData = new HashMap<>();
            eventData.put("event", "disconnected");
            eventData.put("vendorId", vendorId);
            eventData.put("productId", productId);
            eventData.put("deviceName", device.getDeviceName());
            thermalPrinterEventHandler.sendUsbDeviceEvent(eventData);
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        // Call the super method to ensure proper initialization
        // This already registers all plugins
        super.configureFlutterEngine(flutterEngine);

        this.displayManager = (DisplayManager) getSystemService(Context.DISPLAY_SERVICE);

        // Ensure the activity is fully initialized before any plugin operations
        getWindow().getDecorView().post(() -> {
            // This runs after the view is fully laid out
            Log.d(TAG, "Activity fully initialized");
        });
        this.context = this;

        // Manually register the plugins
        flutterEngine.getPlugins().add(new IminPrinterPlugin());
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        switch (call.method) {
                            case "showPresentation":
                                String displayId = call.argument("displayId");
                                String routerName = call.argument("routerName");
                                result.success(showPresentation(displayId, routerName));
                                break;
                            case "hidePresentation":
                                hidePresentation(call, result);
                                break;
                            case "listDisplay":

                                Gson gson = new Gson();
                                String category = call.argument("category");
                                Display[] displays = displayManager != null ? displayManager.getDisplays(category)
                                        : null;
                                List<DisplayJson> listJson = new ArrayList<>();

                                if (displays != null) {
                                    for (Display display : displays) {
                                        DisplayJson d = new DisplayJson(
                                                String.valueOf(display.getDisplayId()),
                                                String.valueOf(display.getFlags()),
                                                String.valueOf(display.getRotation()),
                                                display.getName());
                                        listJson.add(d);

                                        // Show toast for each DisplayJson object
                                    }
                                }

                                result.success(gson.toJson(listJson));
                                break;

                            case "transferDataToPresentation":
                                try {
                                    flutterEngineChannel.invokeMethod("DataTransfer", call.arguments);
                                    result.success(true);
                                } catch (Exception e) {
                                    Log.e(TAG, "Error in transferDataToPresentation", e);
                                    result.success(false);
                                }
                                break;
                            case "hideAllPresentations":
                                hideAllPresentations(result);
                                break;
                            case "getActivePresentationsCount":
                                result.success(presentations.size());
                                break;
                            default:
                                result.notImplemented();
                                break;
                        }
                    }
                });

        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
                .setStreamHandler(new DisplayConnectedStreamHandler(displayManager));

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), GATT_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "forceCloseGatt":
                            if (currentGatt != null) {
                                new Handler(Looper.getMainLooper()).post(() -> {
                                    try {
                                        currentGatt.disconnect();
                                        currentGatt.close();
                                        currentGatt = null;
                                        result.success(true);
                                    } catch (Exception e) {
                                        result.error("CLOSE_FAILED", e.getMessage(), null);
                                    }
                                });
                            } else {
                                result.error("NO_GATT", "No active GATT connection", null);
                            }
                            break;

                        case "connectToMacAddress":
                            String mac = call.argument("macAddress");
                            connectToDevice(mac);
                            result.success(true);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });

        // Add thermal printer method channel handler
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), THERMAL_PRINTER_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "getPlatformVersion":
                            result.success("Android " + android.os.Build.VERSION.RELEASE);
                            break;
                        case "getUsbDevicesList":
                            getUsbDevicesList(result);
                            break;
                        case "connect":
                            String vendorId = call.argument("vendorId");
                            String productId = call.argument("productId");
                            connectThermalPrinter(vendorId, productId, result);
                            break;
                        case "printText":
                            String printVendorId = call.argument("vendorId");
                            String printProductId = call.argument("productId");
                            List<Integer> data = call.argument("data");
                            String path = call.argument("path");
                            printText(printVendorId, printProductId, data, path, result);
                            break;
                        case "isConnected":
                            String connVendorId = call.argument("vendorId");
                            String connProductId = call.argument("productId");
                            isConnected(connVendorId, connProductId, result);
                            break;
                        case "convertimage":
                            List<Integer> imageData = call.argument("path");
                            convertImageToGrayscale(imageData, result);
                            break;
                        case "disconnect":
                            String discVendorId = call.argument("vendorId");
                            String discProductId = call.argument("productId");
                            disconnectThermalPrinter(discVendorId, discProductId, result);
                            break;
                        case "requestUsbPermission":
                            String permVendorId = call.argument("vendorId");
                            String permProductId = call.argument("productId");
                            requestUsbPermission(permVendorId, permProductId, result);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });

        // Add thermal printer event channel handler
        thermalPrinterEventHandler = new ThermalPrinterEventStreamHandler();
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), THERMAL_PRINTER_EVENT_CHANNEL)
                .setStreamHandler(thermalPrinterEventHandler);

        // Initialize USB device receiver
        initializeUsbDeviceReceiver();

        // Register USB device receiver immediately to catch all USB events
        registerUsbDeviceReceiver();
    }

    @SuppressLint("LongLogTag")
    private boolean showPresentation(String displayId, String routerName) {
        try {
            int displayIdInt = Integer.parseInt(displayId);
            Display display = displayManager.getDisplay(displayIdInt);
            FlutterEngine flutterEngine = createFlutterEngine(routerName);

            if (display != null && flutterEngine != null) {
                // Create the new presentation first to minimize flicker
                flutterEngineChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),
                        CHANNEL + "_engine");
                Presentation newPresentation = new PresentationDisplay(context, routerName, display);

                // Show the new presentation immediately
                newPresentation.show();

                // Now dismiss the old presentation after the new one is shown (reduces flicker)
                if (presentations.containsKey(displayIdInt)) {
                    Presentation existingPresentation = presentations.get(displayIdInt);
                    if (existingPresentation != null) {
                        // Add a small delay to ensure new presentation is fully rendered
                        new Handler(Looper.getMainLooper()).postDelayed(() -> {
                            existingPresentation.dismiss();
                        }, 500); // 50ms delay to minimize flicker
                    }
                }

                // Store the new presentation with its display ID
                presentations.put(displayIdInt, newPresentation);

                Log.i(TAG, "Presentation created and stored for display ID: " + displayIdInt);
                return true;
            } else {
                Log.e("MainActivity", display == null ? "Can't find display" : "Can't find FlutterEngine");
                return false;
            }
        } catch (Exception e) {
            Log.e("MainActivity", "Error in showPresentation", e);
            return false;
        }
    }

    private FlutterEngine createFlutterEngine(String tag) {
        if (context == null) {
            return null;
        }

        FlutterEngine engine = FlutterEngineCache.getInstance().get(tag);
        if (engine == null) {
            engine = new FlutterEngine(context);
            engine.getNavigationChannel().setInitialRoute(tag);
            engine.getDartExecutor().executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault());
            engine.getLifecycleChannel().appIsResumed();
            FlutterEngineCache.getInstance().put(tag, engine);

        } else {
        }
        return engine;
    }

    private void hidePresentation(MethodCall call, Result result) {
        try {
            JSONObject obj = new JSONObject((String) call.arguments);
            int displayId = obj.getInt("displayId");
            Log.i(TAG, "Channel: method: " + call.method + " | displayId: " + displayId);

            // Check if we have a presentation for this specific display ID
            if (presentations.containsKey(displayId)) {
                Presentation presentation = presentations.get(displayId);
                if (presentation != null) {
                    Log.i(TAG, "PRESENTATION FOUND FOR DISPLAY " + displayId + ", DISMISSING");
                    presentation.dismiss();
                    presentations.remove(displayId); // Remove from map
                    result.success(true);
                } else {
                    Log.i(TAG, "PRESENTATION FOR DISPLAY " + displayId + " IS NULL");
                    presentations.remove(displayId); // Clean up null entry
                    result.success(false);
                }
            } else {
                Log.i(TAG, "NO PRESENTATION FOUND FOR DISPLAY " + displayId);
                result.success(false); // Return false to indicate no presentation was found
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in hidePresentation: " + e.getMessage());
            result.error(call.method, e.getMessage(), null);
        }
    }

    private void hideAllPresentations(Result result) {
        try {
            int dismissedCount = 0;
            Log.i(TAG, "Hiding all presentations. Total presentations: " + presentations.size());

            // Create a copy of the keys to avoid ConcurrentModificationException
            ArrayList<Integer> displayIds = new ArrayList<>(presentations.keySet());

            for (Integer displayId : displayIds) {
                Presentation presentation = presentations.get(displayId);
                if (presentation != null) {
                    Log.i(TAG, "Dismissing presentation for display: " + displayId);
                    presentation.dismiss();
                    dismissedCount++;
                }
            }

            // Clear all presentations from the map
            presentations.clear();

            Log.i(TAG, "Successfully dismissed " + dismissedCount + " presentations");
            result.success(dismissedCount);
        } catch (Exception e) {
            Log.e(TAG, "Error in hideAllPresentations: " + e.getMessage());
            result.error("hideAllPresentations", e.getMessage(), null);
        }
    }

    // @Override
    // public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    // // Code here if needed
    // }

    // @Override
    // public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    // // Code here if needed
    // }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        this.context = binding.getActivity();
        displayManager = (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // Implement if needed
    }

    @Override
    public void onDetachedFromActivity() {
        // Implement if needed
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        this.context = binding.getActivity();
        displayManager = (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);
    }

    public class DisplayConnectedStreamHandler implements EventChannel.StreamHandler {
        private DisplayManager displayManager;
        private EventChannel.EventSink sink;
        private Handler handler;

        private DisplayManager.DisplayListener displayListener = new DisplayManager.DisplayListener() {
            @Override
            public void onDisplayAdded(int displayId) {
                if (sink != null) {
                    sink.success(1);
                }
            }

            @Override
            public void onDisplayRemoved(int displayId) {
                if (sink != null) {
                    sink.success(0);
                }
            }

            @Override
            public void onDisplayChanged(int displayId) {
            }
        };

        public DisplayConnectedStreamHandler(DisplayManager displayManager) {
            this.displayManager = displayManager;
        }

        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            this.sink = events;
            this.handler = new Handler(Looper.getMainLooper());
            displayManager.registerDisplayListener(displayListener, handler);
        }

        @Override
        public void onCancel(Object arguments) {
            this.sink = null;
            this.handler = null;
            displayManager.unregisterDisplayListener(displayListener);
        }
    }

    public void setCurrentGatt(BluetoothGatt gatt) {
        this.currentGatt = gatt;
    }

    public void connectToDevice(String macAddress) {
        if (bluetoothAdapter == null || macAddress == null) {
            Log.e("Bluetooth", "Bluetooth not supported or MAC is null");
            return;
        }

        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);
        if (device == null) {
            Log.e("Bluetooth", "Device not found with address: " + macAddress);
            return;
        }
        new Handler(Looper.getMainLooper()).post(() -> {
            BluetoothGatt gatt = device.connectGatt(context, false, new BluetoothGattCallback() {
                @Override
                public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
                    super.onConnectionStateChange(gatt, status, newState);
                    Log.d("BluetoothGatt", "onConnectionStateChange: status=" + status + ", newState=" + newState);

                    if (newState == BluetoothGatt.STATE_CONNECTED) {
                        Log.d("BluetoothGatt", "Connected to GATT server.");
                        setCurrentGatt(gatt); // 🔥 Save the GATT instance
                    } else if (newState == BluetoothGatt.STATE_DISCONNECTED) {
                        Log.d("BluetoothGatt", "Disconnected from GATT server.");
                    }
                }

                // You can override other callbacks as needed...
            });
        });
    }

    // Thermal Printer Methods
    private void getUsbDevicesList(Result result) {
        try {
            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            HashMap<String, UsbDevice> deviceList = usbManager.getDeviceList();
            Log.d(TAG, "Scanning " + deviceList.size() + " USB devices for printers");

            List<HashMap<String, Object>> devices = new ArrayList<>();
            for (UsbDevice device : deviceList.values()) {
                // Only include printer devices
                if (!isPrinterDevice(device)) {
                    Log.d(TAG, "Skipping non-printer device: " + device.getDeviceName() + 
                          " (VID: 0x" + Integer.toHexString(device.getVendorId()) + 
                          ", PID: 0x" + Integer.toHexString(device.getProductId()) + ")");
                    continue;
                }

                HashMap<String, Object> deviceInfo = new HashMap<>();
                deviceInfo.put("vendorId", device.getVendorId());
                deviceInfo.put("productId", device.getProductId());
                deviceInfo.put("deviceName", device.getDeviceName());
                deviceInfo.put("manufacturerName", device.getManufacturerName());
                deviceInfo.put("productName", device.getProductName());

                // Flutter expects 'name' field - use productName or fallback to manufacturerName
                String deviceDisplayName = device.getProductName();
                if (deviceDisplayName == null || deviceDisplayName.trim().isEmpty()) {
                    deviceDisplayName = device.getManufacturerName();
                }
                if (deviceDisplayName == null || deviceDisplayName.trim().isEmpty()) {
                    deviceDisplayName = "USB Printer (VID: 0x" + Integer.toHexString(device.getVendorId()) + 
                                      ", PID: 0x" + Integer.toHexString(device.getProductId()) + ")";
                }
                deviceInfo.put("name", deviceDisplayName);

                // Check if this device is in our connected printers set
                String printerId = device.getVendorId() + ":" + device.getProductId();
                boolean isConnected = connectedPrinters.contains(printerId);
                deviceInfo.put("connected", isConnected);

                Log.d(TAG, "Found USB printer: " + deviceDisplayName +
                        " (VID: 0x" + Integer.toHexString(device.getVendorId()) +
                        ", PID: 0x" + Integer.toHexString(device.getProductId()) +
                        ", Connected: " + isConnected + ")");

                devices.add(deviceInfo);
            }

            Log.d(TAG, "Returning " + devices.size() + " USB printer devices to Flutter");
            result.success(devices);
        } catch (Exception e) {
            Log.e(TAG, "Error getting USB devices list", e);
            result.error("USB_ERROR", e.getMessage(), null);
        }
    }

    private void connectThermalPrinter(String vendorId, String productId, Result result) {
        try {
            Log.d(TAG, "Connecting to thermal printer: vendorId=" + vendorId + ", productId=" + productId);

            // Create a unique identifier for this printer
            String printerId = vendorId + ":" + productId;

            // Get UsbManager and find the device
            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            HashMap<String, UsbDevice> deviceList = usbManager.getDeviceList();

            UsbDevice targetDevice = null;
            for (UsbDevice device : deviceList.values()) {
                if (device.getVendorId() == Integer.parseInt(vendorId) &&
                        device.getProductId() == Integer.parseInt(productId)) {
                    targetDevice = device;
                    break;
                }
            }

            if (targetDevice == null) {
                Log.e(TAG, "USB device not found: " + printerId);
                result.error("DEVICE_NOT_FOUND", "USB device not found", null);
                return;
            }

            // Check if we have permission to access the device
            if (!usbManager.hasPermission(targetDevice)) {
                Log.d(TAG, "No USB permission, requesting permission for device: " + targetDevice.getDeviceName());

                // Store the pending connection data
                pendingPrintResult = result;
                pendingVendorId = vendorId;
                pendingProductId = productId;
                pendingPrintData = null; // No print data for connection request
                pendingPrintPath = null; // No print path for connection request

                // Register the USB receiver
                IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(usbReceiver, filter, Context.RECEIVER_EXPORTED);
                } else {
                    registerReceiver(usbReceiver, filter);
                }

                // Request permission
                PendingIntent permissionIntent = PendingIntent.getBroadcast(
                        this,
                        0,
                        new Intent(ACTION_USB_PERMISSION),
                        PendingIntent.FLAG_IMMUTABLE);
                usbManager.requestPermission(targetDevice, permissionIntent);
                return; // Exit here, the actual connection will happen in the receiver
            }

            // For USB printers, we consider them "connected" if they are physically
            // connected
            // and we can find them in the USB device list
            Log.d(TAG, "Adding printer to connected set: " + printerId);
            Log.d(TAG, "Connected printers before add: " + connectedPrinters.toString());
            connectedPrinters.add(printerId);
            Log.d(TAG, "Connected printers after add: " + connectedPrinters.toString());
            Log.d(TAG, "Successfully connected to printer: " + printerId);
            Log.d(TAG, "Total connected printers: " + connectedPrinters.size());

            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "Error connecting to thermal printer", e);
            result.error("CONNECT_ERROR", e.getMessage(), null);
        }
    }

    private void printText(String vendorId, String productId, List<Integer> data, String path, Result result) {
        try {
            Log.d(TAG, "Starting USB print: vendorId=" + vendorId + ", productId=" + productId + ", dataSize="
                    + data.size());

            // Get UsbManager and find the device
            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            HashMap<String, UsbDevice> deviceList = usbManager.getDeviceList();

            Log.d(TAG, "Found " + deviceList.size() + " USB devices");

            // Find the target device by vendor and product ID
            UsbDevice targetDevice = null;
            for (UsbDevice device : deviceList.values()) {
                Log.d(TAG, "Checking USB device: vendorId=" + device.getVendorId() + ", productId="
                        + device.getProductId());

                if (String.valueOf(device.getVendorId()).equals(vendorId) &&
                        String.valueOf(device.getProductId()).equals(productId)) {
                    targetDevice = device;
                    Log.d(TAG, "Found target USB printer device: " + device.getDeviceName());
                    break;
                }
            }

            if (targetDevice == null) {
                Log.e(TAG, "Target USB printer not found");
                result.error("PRINTER_NOT_FOUND", "Target USB printer not found", null);
                return;
            }

            // Check if we have permission to access the device
            if (!usbManager.hasPermission(targetDevice)) {
                Log.d(TAG, "No USB permission, requesting permission for device: " + targetDevice.getDeviceName());

                // Store the pending print data
                pendingPrintResult = result;
                pendingVendorId = vendorId;
                pendingProductId = productId;
                pendingPrintData = data;
                pendingPrintPath = path;

                // Register the USB receiver
                IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(usbReceiver, filter, Context.RECEIVER_EXPORTED);
                } else {
                    registerReceiver(usbReceiver, filter);
                }

                // Request permission
                PendingIntent permissionIntent = PendingIntent.getBroadcast(
                        this,
                        0,
                        new Intent(ACTION_USB_PERMISSION),
                        PendingIntent.FLAG_IMMUTABLE);
                usbManager.requestPermission(targetDevice, permissionIntent);
                return; // Exit here, the actual printing will happen in the receiver
            }

            // If we already have permission, proceed with printing
            performActualPrint(vendorId, productId, data, path, result);

        } catch (Exception e) {
            Log.e(TAG, "Error printing to USB printer", e);
            result.error("PRINT_ERROR", e.getMessage(), null);
        }
    }

    private void performActualPrint(String vendorId, String productId, List<Integer> data, String path, Result result) {
        try {
            Log.d(TAG, "Performing actual USB print: vendorId=" + vendorId + ", productId=" + productId);

            // Convert List<Integer> to byte array
            byte[] byteData = new byte[data.size()];
            for (int i = 0; i < data.size(); i++) {
                byteData[i] = data.get(i).byteValue();
            }

            // Get UsbManager and find the device
            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            HashMap<String, UsbDevice> deviceList = usbManager.getDeviceList();

            // Find the target device by vendor and product ID
            UsbDevice targetDevice = null;
            for (UsbDevice device : deviceList.values()) {
                if (String.valueOf(device.getVendorId()).equals(vendorId) &&
                        String.valueOf(device.getProductId()).equals(productId)) {
                    targetDevice = device;
                    break;
                }
            }

            if (targetDevice == null) {
                Log.e(TAG, "Target USB printer not found during actual print");
                result.error("PRINTER_NOT_FOUND", "Target USB printer not found", null);
                return;
            }

            // Open connection to the device
            UsbDeviceConnection connection = usbManager.openDevice(targetDevice);
            if (connection == null) {
                Log.e(TAG, "Failed to open USB device connection");
                result.error("CONNECTION_FAILED", "Failed to open USB device connection", null);
                return;
            }

            // Declare interface outside try block so it's accessible in finally
            UsbInterface usbInterface = null;
            try {
                // Find the first interface (usually the printer interface)
                usbInterface = targetDevice.getInterface(0);
                if (!connection.claimInterface(usbInterface, true)) {
                    Log.e(TAG, "Failed to claim USB interface");
                    result.error("INTERFACE_CLAIM_FAILED", "Failed to claim USB interface", null);
                    return;
                }

                // Find the bulk OUT endpoint for sending data
                UsbEndpoint endpoint = null;
                for (int i = 0; i < usbInterface.getEndpointCount(); i++) {
                    UsbEndpoint ep = usbInterface.getEndpoint(i);
                    if (ep.getType() == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                            ep.getDirection() == UsbConstants.USB_DIR_OUT) {
                        endpoint = ep;
                        break;
                    }
                }

                if (endpoint == null) {
                    Log.e(TAG, "No bulk OUT endpoint found");
                    result.error("NO_ENDPOINT", "No bulk OUT endpoint found", null);
                    return;
                }

                // Send the print data
                Log.d(TAG, "Sending " + byteData.length + " bytes to USB printer");
                int bytesTransferred = connection.bulkTransfer(endpoint, byteData, byteData.length, 5000);

                if (bytesTransferred < 0) {
                    Log.e(TAG, "Failed to transfer data to USB printer. Bytes transferred: " + bytesTransferred);
                    result.error("TRANSFER_FAILED", "Failed to transfer data to USB printer", null);
                } else {
                    Log.d(TAG, "Successfully transferred " + bytesTransferred + " bytes to USB printer");
                    result.success(true);
                }

            } finally {
                // Release the interface and close connection
                if (usbInterface != null) {
                    connection.releaseInterface(usbInterface);
                }
                connection.close();
            }

        } catch (Exception e) {
            Log.e(TAG, "Error in performActualPrint", e);
            result.error("PRINT_ERROR", e.getMessage(), null);
        }
    }

    private void clearPendingPrintData() {
        pendingPrintResult = null;
        pendingVendorId = null;
        pendingProductId = null;
        pendingPrintData = null;
        pendingPrintPath = null;

        // Unregister the receiver to avoid memory leaks
        try {
            unregisterReceiver(usbReceiver);
        } catch (IllegalArgumentException e) {
            // Receiver was not registered, ignore
        }
    }

    private void isConnected(String vendorId, String productId, Result result) {
        try {
            Log.d(TAG, "Checking connection: vendorId=" + vendorId + ", productId=" + productId);

            // Create the same unique identifier used in connect
            String printerId = vendorId + ":" + productId;
            Log.d(TAG, "Looking for printer ID: " + printerId);

            // Check if this printer is in our connected set
            boolean isConnected = connectedPrinters.contains(printerId);

            Log.d(TAG, "Printer " + printerId + " connection status: " + isConnected);
            Log.d(TAG, "Currently connected printers: " + connectedPrinters.toString());
            Log.d(TAG, "Connected printers size: " + connectedPrinters.size());

            result.success(isConnected);
        } catch (Exception e) {
            Log.e(TAG, "Error checking connection", e);
            result.error("CONNECTION_CHECK_ERROR", e.getMessage(), null);
        }
    }

    private void convertImageToGrayscale(List<Integer> imageData, Result result) {
        try {
            // Convert List<Integer> to byte array
            byte[] byteData = new byte[imageData.size()];
            for (int i = 0; i < imageData.size(); i++) {
                byteData[i] = imageData.get(i).byteValue();
            }

            // For now, just return the same data - you'll need to implement actual
            // conversion logic
            Log.d(TAG, "Converting image to grayscale: dataSize=" + byteData.length);
            result.success(imageData);
        } catch (Exception e) {
            Log.e(TAG, "Error converting image", e);
            result.error("CONVERT_ERROR", e.getMessage(), null);
        }
    }

    private void requestUsbPermission(String vendorId, String productId, Result result) {
        try {
            Log.d(TAG, "Requesting USB permission for: vendorId=" + vendorId + ", productId=" + productId);

            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            if (usbManager == null) {
                Log.e(TAG, "UsbManager is null");
                result.error("USB_MANAGER_NULL", "USB Manager not available", null);
                return;
            }

            // Find the target device
            UsbDevice targetDevice = null;
            for (UsbDevice device : usbManager.getDeviceList().values()) {
                if (String.valueOf(device.getVendorId()).equals(vendorId) &&
                        String.valueOf(device.getProductId()).equals(productId)) {
                    targetDevice = device;
                    break;
                }
            }

            if (targetDevice == null) {
                Log.e(TAG, "USB device not found: vendorId=" + vendorId + ", productId=" + productId);
                result.error("DEVICE_NOT_FOUND", "USB device not found", null);
                return;
            }

            // Check if we already have permission
            if (usbManager.hasPermission(targetDevice)) {
                Log.d(TAG, "USB permission already granted for device: " + targetDevice.getDeviceName());
                result.success(true);
                return;
            }

            // Store the result for later use in the receiver
            pendingPrintResult = result;
            pendingVendorId = vendorId;
            pendingProductId = productId;

            // Register the USB receiver
            IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(usbReceiver, filter, Context.RECEIVER_EXPORTED);
            } else {
                registerReceiver(usbReceiver, filter);
            }

            // Request permission
            PendingIntent permissionIntent = PendingIntent.getBroadcast(
                    this,
                    0,
                    new Intent(ACTION_USB_PERMISSION),
                    PendingIntent.FLAG_IMMUTABLE);
            usbManager.requestPermission(targetDevice, permissionIntent);

            Log.d(TAG, "USB permission request sent for device: " + targetDevice.getDeviceName());
            // Don't call result.success() here - it will be called in the receiver

        } catch (Exception e) {
            Log.e(TAG, "Error requesting USB permission", e);
            result.error("PERMISSION_REQUEST_ERROR", e.getMessage(), null);
        }
    }

    private void disconnectThermalPrinter(String vendorId, String productId, Result result) {
        try {
            Log.d(TAG, "Disconnecting thermal printer: vendorId=" + vendorId + ", productId=" + productId);

            // Create the same unique identifier used in connect
            String printerId = vendorId + ":" + productId;

            // Remove from connected set
            boolean wasConnected = connectedPrinters.remove(printerId);

            Log.d(TAG, "Disconnected printer: " + printerId + " (was connected: " + wasConnected + ")");
            Log.d(TAG, "Remaining connected printers: " + connectedPrinters.size());

            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "Error disconnecting thermal printer", e);
            result.error("DISCONNECT_ERROR", e.getMessage(), null);
        }
    }

    // Thermal Printer Event Stream Handler
    public class ThermalPrinterEventStreamHandler implements EventChannel.StreamHandler {
        private EventChannel.EventSink eventSink;
        private Handler handler;

        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            this.eventSink = events;
            this.handler = new Handler(Looper.getMainLooper());
            Log.d(TAG, "Thermal printer event stream started listening");
            // Note: USB device receiver is now registered at activity level, not here
        }

        @Override
        public void onCancel(Object arguments) {
            // Note: USB device receiver is managed at activity level, not unregistered here
            this.eventSink = null;
            this.handler = null;
            Log.d(TAG, "Thermal printer event stream cancelled");
        }

        // Method to send USB device events to Flutter
        public void sendUsbDeviceEvent(HashMap<String, Object> deviceInfo) {
            if (eventSink != null && handler != null) {
                handler.post(() -> {
                    try {
                        eventSink.success(deviceInfo);
                    } catch (Exception e) {
                        Log.e(TAG, "Error sending USB device event", e);
                    }
                });
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        // Unregister USB device receiver if it's still registered
        if (usbDeviceReceiver != null) {
            try {
                unregisterReceiver(usbDeviceReceiver);
                Log.d(TAG, "USB device receiver unregistered in onDestroy");
            } catch (IllegalArgumentException e) {
                // Receiver was not registered, ignore
                Log.d(TAG, "USB device receiver was not registered in onDestroy");
            }
        }

        // Clean up any pending USB operations
        clearPendingPrintData();
    }

    @Override
    protected void onPause() {
        super.onPause();
        // Clean up any pending USB operations when app goes to background
        clearPendingPrintData();
    }

}