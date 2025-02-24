package com.flappy.flutter_usual_permission;

import static android.content.pm.PackageManager.PERMISSION_GRANTED;

import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Build;
import android.Manifest;
import android.provider.Settings;

import androidx.core.content.ContextCompat;
import androidx.core.app.ActivityCompat;
import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;

/**
 * FlutterUsualPermissionPlugin
 * 插件用于处理 Android 权限检查和请求
 */
public class FlutterUsualPermissionPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {

    // 请求权限的请求码
    private static final int REQUEST_PERMISSION_CODE = 1;

    // 请求通知策略访问权限的请求码
    private static final int REQUEST_NOTIFICATION_POLICY_ACCESS = 2;

    // 权限回调接口
    private PermissionListener permissionListener;

    // Flutter 与原生通信的通道
    private MethodChannel channel;

    // 应用上下文
    private Context context;

    // 当前 Activity
    private Activity activity;

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        // 绑定 Activity
        addBinding(binding);
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        // 重新绑定 Activity（例如屏幕旋转时）
        addBinding(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // 解绑 Activity（例如屏幕旋转时）
        removeBinding();
    }

    @Override
    public void onDetachedFromActivity() {
        // 完全解绑 Activity
        removeBinding();
    }

    // 添加 Activity 绑定
    private void addBinding(ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
        binding.addRequestPermissionsResultListener(this);
    }

    // 移除 Activity 绑定
    private void removeBinding() {
        activity = null;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        // 初始化 Flutter 通信通道
        this.context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_usual_permission");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        // 解绑 Flutter 通信通道
        channel.setMethodCallHandler(null);
        context = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        // 根据方法名处理不同的调用
        switch (call.method) {
            case "checkPermission":
                handleCheckPermission(call, result);
                break;
            case "requestPermission":
                handleRequestPermission(call, result);
                break;
            case "openNotificationSettings":
                openNotificationSettings(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    // 处理权限检查
    private void handleCheckPermission(MethodCall call, MethodChannel.Result result) {
        // 获取权限类型
        Integer type = call.argument("type");
        if (type == null) {
            result.error("INVALID_ARGUMENT", "Type argument is missing or invalid", null);
            return;
        }

        // 获取对应的权限列表
        List<String> permissions = getPermissionsForType(type);
        if (permissions == null) {
            result.error("INVALID_ARGUMENT", "Unknown permission type", null);
            return;
        }

        // 如果是特殊权限（如通知权限），直接检查
        if (permissions.isEmpty()) {
            boolean isGranted = checkSpecialPermission(type);
            result.success(isGranted ? "1" : "0");
        } else {
            // 普通权限，逐一检查
            checkPermission(permissions, flag -> result.success(flag ? "1" : "0"));
        }
    }

    // 处理权限请求
    private void handleRequestPermission(MethodCall call, MethodChannel.Result result) {
        // 获取权限类型
        Integer type = call.argument("type");
        if (type == null) {
            result.error("INVALID_ARGUMENT", "Type argument is missing or invalid", null);
            return;
        }

        // 获取对应的权限列表
        List<String> permissions = getPermissionsForType(type);
        if (permissions == null) {
            result.error("INVALID_ARGUMENT", "Unknown permission type", null);
            return;
        }

        // 如果是特殊权限（如通知权限），启动设置页面
        if (permissions.isEmpty()) {
            if (type == 0) {
                Intent intent = new Intent(android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS);
                activity.startActivityForResult(intent, REQUEST_NOTIFICATION_POLICY_ACCESS);
                permissionListener = flag -> result.success(flag ? "1" : "0");
                return;
            }
            result.success("0");
        } else {
            // 普通权限，动态请求
            requestPermission(permissions, flag -> result.success(flag ? "1" : "0"));
        }
    }

    // 打开系统通知设置界面
    private void openNotificationSettings(MethodChannel.Result result) {
        try {
            // 构建 Intent，跳转到当前应用的通知设置页面
            Intent intent = new Intent();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            } else {
                // 低于 Android 8.0 的设备，跳转到应用详情页面
                intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                intent.setData(android.net.Uri.parse("package:" + context.getPackageName()));
            }
            activity.startActivity(intent);
            result.success("1"); // 成功打开设置页面
        } catch (Exception e) {
            result.error("UNAVAILABLE", "Cannot open notification settings", e.getMessage());
        }
    }

    // 根据权限类型获取对应的权限列表
    private List<String> getPermissionsForType(int type) {
        List<String> permissions = new ArrayList<>();
        switch (type) {
            case 0:
                // 通知权限
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    permissions.add(Manifest.permission.POST_NOTIFICATIONS);
                }
                return permissions;
            case 1:
                // 相机权限
                permissions.add(Manifest.permission.CAMERA);
                break;
            case 2:
                // 存储权限
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    permissions.add(Manifest.permission.READ_MEDIA_IMAGES);
                    permissions.add(Manifest.permission.READ_MEDIA_VIDEO);
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE);
                } else {
                    permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
                    permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE);
                }
                break;
            case 3:
                // 日历权限
                permissions.add(Manifest.permission.WRITE_CALENDAR);
                permissions.add(Manifest.permission.READ_CALENDAR);
                break;
            case 4:
                // 麦克风权限
                permissions.add(Manifest.permission.RECORD_AUDIO);
                break;
            case 5:
                // 定位权限
                permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
                permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION);
                }
                break;
            case 6:
                // 拨打电话权限
                permissions.add(Manifest.permission.CALL_PHONE);
                break;
            default:
                return null;
        }
        return permissions;
    }

    // 检查特殊权限（如通知权限）
    private boolean checkSpecialPermission(int type) {
        if (type == 0) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                return ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PERMISSION_GRANTED;
            } else {
                NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                return notificationManager != null && notificationManager.isNotificationPolicyAccessGranted();
            }
        }
        return false;
    }

    // 检查普通权限
    private void checkPermission(List<String> permissions, PermissionListener listener) {
        List<String> permissionsToRequest = new ArrayList<>();
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(context, permission) != PERMISSION_GRANTED) {
                permissionsToRequest.add(permission);
            }
        }
        listener.result(permissionsToRequest.isEmpty());
    }

    // 动态请求权限
    private void requestPermission(List<String> permissions, PermissionListener listener) {
        if (activity == null) {
            listener.result(false);
            return;
        }
        permissionListener = listener;
        ActivityCompat.requestPermissions(activity, permissions.toArray(new String[0]), REQUEST_PERMISSION_CODE);
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == REQUEST_PERMISSION_CODE) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (permissionListener != null) {
                permissionListener.result(allGranted);
                permissionListener = null;
            }
            return true;
        }
        return false;
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_NOTIFICATION_POLICY_ACCESS) {
            //检查通知权限是否已授予
            boolean isGranted = checkSpecialPermission(0);
            if (permissionListener != null) {
                permissionListener.result(isGranted);
                permissionListener = null;
            }
            return true;
        }
        return false;
    }
}