import Flutter
import UIKit
import AVFoundation
import Photos
import CoreLocation
import UserNotifications
import EventKit

public class FlutterUsualPermissionPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    
    // 定位权限管理器
    private var locationManager: CLLocationManager?
    // 定位权限结果回调
    private var locationPermissionResult: FlutterResult?

    // 注册插件
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_usual_permission", binaryMessenger: registrar.messenger())
        let instance = FlutterUsualPermissionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // 处理 Flutter 调用
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkPermission":
            // 检查权限
            guard let args = call.arguments as? [String: Any],
                  let type = args["type"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
                return
            }
            let request = args["request"] as? Bool ?? false
            checkPermission(type: type, request: request, result: result)
        case "requestPermission":
            // 请求权限
            guard let args = call.arguments as? [String: Any],
                  let type = args["type"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
                return
            }
            requestPermission(type: type, result: result)
        case "openNotificationSettings":
            // 打开系统通知设置界面
            openNotificationSettings(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - 权限检查
    private func checkPermission(type: Int, request: Bool, result: @escaping FlutterResult) {
        switch type {
        case 0:
            // 通知权限
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus == .authorized {
                    result("1")
                } else if request {
                    self.requestNotificationPermission(result: result)
                } else {
                    result("0")
                }
            }
        case 1:
            // 相机权限
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .authorized {
                result("1")
            } else if request {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    result(granted ? "1" : "0")
                }
            } else {
                result("0")
            }
        case 2:
            // 存储权限
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .authorized {
                result("1")
            } else if request {
                PHPhotoLibrary.requestAuthorization { newStatus in
                    result(newStatus == .authorized ? "1" : "0")
                }
            } else {
                result("0")
            }
        case 3:
            // 日历权限
            let status = EKEventStore.authorizationStatus(for: .event)
            if status == .authorized {
                result("1")
            } else if request {
                let eventStore = EKEventStore()
                eventStore.requestAccess(to: .event) { granted, _ in
                    result(granted ? "1" : "0")
                }
            } else {
                result("0")
            }
        case 4:
            // 麦克风权限
            let status = AVAudioSession.sharedInstance().recordPermission
            if status == .granted {
                result("1")
            } else if request {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    result(granted ? "1" : "0")
                }
            } else {
                result("0")
            }
        case 5:
            // 定位权限
            let status = CLLocationManager.authorizationStatus()
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                result("1")
            } else if request {
                requestLocationPermission(result: result)
            } else {
                result("0")
            }
        case 6:
            // 拨打电话权限（iOS 不需要拨打电话权限，直接返回 "1"）
            result("1")
        default:
            result(FlutterError(code: "INVALID_PERMISSION_TYPE", message: "Unknown permission type", details: nil))
        }
    }

    // MARK: - 权限请求
    private func requestPermission(type: Int, result: @escaping FlutterResult) {
        switch type {
        case 0:
            // 通知权限
            requestNotificationPermission(result: result)
        case 1:
            // 相机权限
            AVCaptureDevice.requestAccess(for: .video) { granted in
                result(granted ? "1" : "0")
            }
        case 2:
            // 存储权限
            PHPhotoLibrary.requestAuthorization { status in
                result(status == .authorized ? "1" : "0")
            }
        case 3:
            // 日历权限
            let eventStore = EKEventStore()
            eventStore.requestAccess(to: .event) { granted, _ in
                result(granted ? "1" : "0")
            }
        case 4:
            // 麦克风权限
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                result(granted ? "1" : "0")
            }
        case 5:
            // 定位权限
            requestLocationPermission(result: result)
        case 6:
            // 拨打电话权限（iOS 不需要拨打电话权限，直接返回 "1"）
            result("1")
        default:
            result(FlutterError(code: "INVALID_PERMISSION_TYPE", message: "Unknown permission type", details: nil))
        }
    }

    // MARK: - 定位权限请求
    private func requestLocationPermission(result: @escaping FlutterResult) {
        // 保存回调
        locationPermissionResult = result
        // 初始化定位管理器
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        // 请求定位权限
        locationManager?.requestWhenInUseAuthorization()
    }

    // 定位权限状态变化回调
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let result = locationPermissionResult else { return }
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            result("1")
        } else {
            result("0")
        }
        locationPermissionResult = nil
    }

    // MARK: - 通知权限请求
    private func requestNotificationPermission(result: @escaping FlutterResult) {
        // 请求通知权限
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            result(granted ? "1" : "0")
        }
    }

    // MARK: - 打开系统通知设置界面
    private func openNotificationSettings(result: @escaping FlutterResult) {
        // 检查是否可以打开应用的设置页面
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            result(FlutterError(code: "UNAVAILABLE", message: "Cannot open settings", details: nil))
            return
        }

        // 打开设置页面
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:]) { success in
                result(success ? "1" : "0")
            }
        } else {
            result(FlutterError(code: "UNAVAILABLE", message: "Cannot open settings", details: nil))
        }
    }
}
