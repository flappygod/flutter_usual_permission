import 'flutter_usual_permission_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'flutter_usual_permission.dart';
import 'package:flutter/services.dart';

/// An implementation of [FlutterUsualPermissionPlatform] that uses method channels.
class MethodChannelFlutterUsualPermission
    extends FlutterUsualPermissionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_usual_permission');

  @override
  Future<bool> checkPermission(PermissionType permissionType) async {
    final String? ret = await methodChannel.invokeMethod('checkPermission', {
      "type": getPermissionType(permissionType),
    });
    if (ret == "1") {
      return true;
    } else {
      return false;
    }
  }

  ///request permission
  @override
  Future<bool> requestPermission(PermissionType permissionType) async {
    final String? ret = await methodChannel.invokeMethod('requestPermission', {
      "type": getPermissionType(permissionType),
    });
    if (ret == "1") {
      return true;
    } else {
      return false;
    }
  }

  ///open notification settings
  @override
  Future<void> openNotificationSettings() async {
    await methodChannel.invokeMethod('openNotificationSettings');
  }
}
