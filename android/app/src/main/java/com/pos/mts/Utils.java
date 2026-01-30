package com.pos.mts;

import android.content.Context;
import android.os.Build;
import android.text.TextUtils;
import android.util.Log;

import com.imin.library.IminSDKManager;

import java.io.OutputStream;
import java.io.FileWriter;
import java.lang.reflect.Method;

/**
 * @Author xhy
 * @Feature description :
 * @Date 2023/7/21 11:31
 */
public class Utils {
    private static String TAG = "flutter_print_Utils";

    private Utils() {
    }

    public static Utils getInstance() {
        return Holder.instance;
    }

    private static class Holder {
        private static final Utils instance = new Utils();
    }

    private Context mContext;

    public Context getContext() {
        return mContext;
    }

    public void setContext(Context context) {
        this.mContext = context;
    }

    public String getPlaform() {
        return getSystemProperties("ro.board.platform");
    }

    public String getModel() {
        String model = "";
        String plaform = getPlaform();

        if (!TextUtils.isEmpty(plaform) && plaform.startsWith("mt")) {
            model = getSystemProperties("ro.neostra.imin_model");
        } else if (!TextUtils.isEmpty(plaform) && plaform.startsWith("ums512")) {
            model = Build.MODEL;
        } else if (!TextUtils.isEmpty(plaform) && plaform.startsWith("sp9863a")) {
            model = Build.MODEL;
            if (model.equals("I22M01")) {
                model = "MS1-11";
            }
        } else {
            model = getSystemProperties("sys.neostra_oem_id");
            android.util.Log.d(TAG, "model " + model);
            if (!TextUtils.isEmpty(model) && model.length() > 4) {
                model = filterModel(model.substring(0, 5));
                String oemId = getSystemProperties("sys.neostra_oem_id");
                if (oemId.length() > 27 && oemId.startsWith("W26MP")) {
                    String num28 = String.valueOf(oemId.charAt(27));
                    if ("S".equalsIgnoreCase(num28)) {
                        model = "D3-510";
                    }
                }
            } else {
                model = getSystemProperties("ro.neostra.imin_model");
            }
            if ("".equals(model)) {
                model = Build.MODEL;
                if (model.equals("I22D01")) {
                    model = "DS1-11";
                }
            }

        }
        return model;
    }

    private String filterModel(String str) {
        switch (str) {
            case "W21XX":
                return "D1-501";
            case "W21MX":
                return "D1-502";
            case "W21DX":
                return "D1-503";
            case "W22XX":
                return "D1p-601";
            case "W22MX":
                return "D1p-602";
            case "W22DX":
                return "D1p-603";
            case "W22DC":
                return "D1p-604";
            case "W23XX":
                return "D1w-701";
            case "W23MX":
                return "D1w-702";
            case "W23DX":
                return "D1w-703";
            case "W23DC":
                return "D1w-704";
            case "V1GXX":
            case "V1GPX":
                return "D2-401";
            case "V1XXX":
            case "V1PXX":
                return "D2-402";
            case "V2BXX":
                return "D2 Pro";
            case "1824P":
                if (getSystemProperties("persist.sys.customername").equals("ZKSY-301")) {
                    return "ZKSY-301";
                } else if (getSystemProperties("persist.sys.customername").equals("K3")) {
                    return "K3";
                }
                return "D3-501";//yimin
            case "P24MP":
                String customerName = getSystemProperties("persist.sys.customername");
                if (customerName.equals("2Dfire")) {
                    return "P10M";
                } else if (customerName.equalsIgnoreCase("Bestway")) {
                    return "V5-1824M Plus";
                } else if (customerName.equalsIgnoreCase("idiotehs")) {
                    return "CTA-D3M";
                } else {
                    return "D3-503";//yimin
                }
//                return "D3-503";//yimin
            case "P24XP":
                return "D3-502";
            case "W26XX":
            case "W26PX":
                return "D3-504";
            case "W26MX":
            case "W26MP":
                return "D3-505";
            case "W27LX":
                return "D4-501";
            case "W27LD":
                return "D4-502";
            case "W27XX":
            case "W27PX":
                return "D4-503";
            case "W27MX":
            case "W27MP":
                return "D4-504";
            case "W27DX":
                return "D4-505";
            case "1824M":
                return "1824M";
            case "1824D":
                return "1824D";
            case "K21XX":
                return "K1-101";
            case "D20XX":
                return "R1-201";
            case "D20TX":
                return "R1-202";
            case "W17BX":
                return "S1-702";
            case "W17XX":
            case "W17PX"://rk3566,android11
                return "S1-701";
            case "W26HX":
                return "D3-504";
            case "W26HM":
                return "D3-505";
            case "W26HD":
                return "D3-506";
            case "W26HG":
            case "W26GP":
                return "K2-201";
            case "D224G":
                return "R2-301";//D224GM04SXXT3PXW3E1MXV110CDXXX
            case "D22XX":
                return "R2-301";// error ?
            case "D22TX":
                return "R2-302";
            case "W27DP":
                return "D4-505";
            case "K21PX":
                return "K1-101";
            case "W23PX":
                return "D1w-701";
            case "W23MP":
                return "D1w-702";
            case "W23DP":
                return "D1w-703";
            case "W28XX":
            case "W28MX":
                customerName = getSystemProperties("persist.sys.customername");
                if (customerName.equals("2Dfire")) {
                    return "P5";
                } else if ("Dingjian".equals(customerName)) {
                    return "DJ-P28";
                } else if ("baohuoli".equalsIgnoreCase(customerName)) {
                    return "FS-5216";
                } else {
                    return "Swan 1";//yimin device name
                }
//                return "Swan 1";//yimin device name
            case "W28GX":
                String w28gxCustomerName = getSystemProperties("persist.sys.customername");
                if (w28gxCustomerName.equals("2Dfire")) {
                    return "P5K";
                } else if ("Dingjian".equals(w28gxCustomerName)) {
                    return "DJ-P28K";
                } else if ("baohuoli".equalsIgnoreCase(w28gxCustomerName)) {
                    return "FS-5216";
                } else {
                    return "Swan 1k";//yimin device name
                }
            case "W26DP":
                return "D3-506";
            case "26PXX":
                return "P10CS";//yimin device name
            case "26MPX":
                return "P10DS";//yimin device name
//                return "Swan 1k";//yimin device name
            default:
                break;
        }
        return "";
    }

    public String getSystemProperties(String property) {
        String value = "";
        try {
            Class clazz = Class.forName("android.os.SystemProperties");
            Method getter = clazz.getDeclaredMethod("get", String.class);
            value = (String) getter.invoke(null, property);
        } catch (Exception e) {
            Log.d(TAG, "Unable to read system properties");
        }
        return value;
    }

    public void opencashBox() {
        String model = getModel();
        String buildModel = Build.MODEL;
        String buildDevice = Build.DEVICE;
        
        Log.d("iminLib", "=== DRAWER DEBUG ===");
        Log.d("iminLib", "Utils.getModel(): " + model);
        Log.d("iminLib", "Build.MODEL: " + buildModel);
        Log.d("iminLib", "Build.DEVICE: " + buildDevice);
        
        try {
            Log.d("iminLib", "Attempting to open cash box using IminSDKManager...");
            IminSDKManager.opencashBox();
            Log.d("iminLib", "SUCCESS - Cash box opened via IminSDKManager");
        } catch (Exception e) {
            Log.e("iminLib", "IminSDKManager.opencashBox() failed: " + e.getMessage(), e);
            Log.d("iminLib", "Trying fallback method with direct file write...");
            tryFallbackMethod();
        }
    }
    
    public void openFalcon2Drawer() {
        Log.d("iminLib", "=== FALCON 2 DRAWER CONTROL ===");
        String[] falcon2Paths = new String[]{
            "/sys/class/gpio/gpio75/value",
            "/sys/class/gpio/gpio77/value",
            "/sys/class/gpio/gpio83/value",
            "/sys/extcon-usb-gpio/cashbox_en",
            "/sys/class/gpio/gpio23/value",
            "/sys/class/neostra_gpioctl/dev/gpioctl"
        };
        
        boolean success = false;
        for (String path : falcon2Paths) {
            Log.d("iminLib", "Trying Falcon 2 GPIO path: " + path);
            try {
                FileWriter fw = new FileWriter(path);
                fw.write("1");
                fw.close();
                Log.d("iminLib", "SUCCESS - Drawer opened via: " + path);
                success = true;
                break;
            } catch (Exception e) {
                Log.d("iminLib", "Failed with path " + path + ": " + e.getMessage());
            }
        }
        
        if (!success) {
            Log.w("iminLib", "WARNING - All Falcon 2 GPIO paths failed, will try fallback methods");
            tryFallbackMethod();
        }
    }
    
    private void tryFallbackMethod() {
        String[] paths = new String[]{
            "/sys/extcon-usb-gpio/cashbox_en",
            "/sys/class/gpio/gpio23/value",
            "/sys/class/neostra_gpioctl/dev/gpioctl"
        };
        
        boolean success = false;
        for (String path : paths) {
            Log.d("iminLib", "Trying fallback path: " + path);
            try {
                FileWriter fw = new FileWriter(path);
                fw.write("1");
                fw.close();
                Log.d("iminLib", "SUCCESS - Drawer opened via: " + path);
                success = true;
                break;
            } catch (Exception e) {
                Log.d("iminLib", "Failed with path " + path + ": " + e.getMessage());
            }
        }
        
        if (!success) {
            Log.w("iminLib", "WARNING - All fallback methods failed");
        }
    }
}
