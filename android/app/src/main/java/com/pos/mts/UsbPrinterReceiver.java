package com.pos.mts;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.util.Log;

/**
 * System-level broadcast receiver for USB printer attach/detach events
 * This receiver ensures USB printer detection works even when the app is not in foreground
 */
public class UsbPrinterReceiver extends BroadcastReceiver {
    private static final String TAG = "UsbPrinterReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        
        if (action == null) {
            return;
        }

        UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
        
        if (device == null) {
            Log.w(TAG, "Received USB intent but device is null");
            return;
        }

        if (UsbManager.ACTION_USB_DEVICE_ATTACHED.equals(action)) {
            Log.d(TAG, "USB Device Attached: " + device.getDeviceName() + 
                  " (VendorId: " + device.getVendorId() + 
                  ", ProductId: " + device.getProductId() + ")");
            
            if (isPrinterDevice(device)) {
                Log.d(TAG, "Detected printer device, notifying MainActivity");
                notifyMainActivity(context, device, "attached");
            }
        } 
        else if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action)) {
            Log.d(TAG, "USB Device Detached: " + device.getDeviceName() + 
                  " (VendorId: " + device.getVendorId() + 
                  ", ProductId: " + device.getProductId() + ")");
            
            if (isPrinterDevice(device)) {
                Log.d(TAG, "Detected printer device detached, notifying MainActivity");
                notifyMainActivity(context, device, "detached");
            }
        }
    }

    /**
     * Improved printer detection for various thermal printer types
     * Supports both class-based and vendor/product ID-based detection
     */
    private boolean isPrinterDevice(UsbDevice device) {
        // Check USB class 7 (Printer class)
        for (int i = 0; i < device.getInterfaceCount(); i++) {
            if (device.getInterface(i).getInterfaceClass() == 7) {
                Log.d(TAG, "Device is printer (USB class 7)");
                return true;
            }
        }

        int vendorId = device.getVendorId();
        int productId = device.getProductId();

        // Check for common thermal printer vendor IDs
        // These are known thermal printer manufacturers
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
            case 0x0fe6: // IMin - for iMin Swan 2 Pro and other iMin devices
                Log.d(TAG, "Detected iMin device (VID: 0x0fe6)");
                return true;
            case 0x25a7: // Another common vendor for iMin devices
                Log.d(TAG, "Detected iMin device (VID: 0x25a7)");
                return true;
            default:
                // Log the vendor ID for debugging
                Log.d(TAG, "Unknown vendor ID: 0x" + Integer.toHexString(vendorId));
                return false;
        }
    }

    /**
     * Notify MainActivity about USB printer events
     * This sends a local broadcast that MainActivity can receive
     */
    private void notifyMainActivity(Context context, UsbDevice device, String action) {
        try {
            // Send a broadcast to the app's main activity if it's running
            Intent broadcastIntent = new Intent("com.pos.mts.USB_PRINTER_EVENT");
            broadcastIntent.putExtra("action", action);
            broadcastIntent.putExtra("deviceName", device.getDeviceName());
            broadcastIntent.putExtra("vendorId", device.getVendorId());
            broadcastIntent.putExtra("productId", device.getProductId());
            broadcastIntent.putExtra("manufacturerName", device.getManufacturerName());
            broadcastIntent.putExtra("productName", device.getProductName());
            
            // Send broadcast - it will be received by MainActivity if it's running
            context.sendBroadcast(broadcastIntent, "com.pos.mts.USB_PERMISSION");
            
            Log.d(TAG, "Broadcast sent for " + action + " event");
        } catch (Exception e) {
            Log.e(TAG, "Error sending broadcast notification", e);
        }
    }
}
