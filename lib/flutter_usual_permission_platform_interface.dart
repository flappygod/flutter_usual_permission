import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'flutter_usual_permission_method_channel.dart';
import 'flutter_usual_permission.dart';

abstract class FlutterUsualPermissionPlatform extends PlatformInterface {
  /// Constructs a FlutterUsualPermissionPlatform.
  FlutterUsualPermissionPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterUsualPermissionPlatform _instance =
      MethodChannelFlutterUsualPermission();

  /// The default instance of [FlutterUsualPermissionPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterUsualPermission].
  static FlutterUsualPermissionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterUsualPermissionPlatform] when
  /// they register themselves.
  static set instance(FlutterUsualPermissionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  ///check  permission
  Future<bool> checkPermission(PermissionType permissionType) {
    throw UnimplementedError('checkPermission() has not been implemented.');
  }

  ///request permission
  Future<bool> requestPermission(PermissionType permissionType) {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  ///open notification settings
  Future<void> openNotificationSettings() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }
}
