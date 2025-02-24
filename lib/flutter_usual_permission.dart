import 'flutter_usual_permission_platform_interface.dart';

//permission type
enum PermissionType {
  notification,
  camera,
  photo,
  calendar,
  microphone,
  location,
  phoneCall
}

//get permission type
int getPermissionType(PermissionType type) {
  int permissionType = 0;
  switch (type) {
    case PermissionType.notification:
      permissionType = 0;
      break;
    case PermissionType.camera:
      permissionType = 1;
      break;
    case PermissionType.photo:
      permissionType = 2;
      break;
    case PermissionType.calendar:
      permissionType = 3;
      break;
    case PermissionType.microphone:
      permissionType = 4;
      break;
    case PermissionType.location:
      permissionType = 5;
      break;
    case PermissionType.phoneCall:
      permissionType = 6;
      break;
  }
  return permissionType;
}

///check  permission
///this package is used to check and request permissions
class FlutterUsualPermission {
  ///check  permission
  static Future<bool> checkPermission(PermissionType permissionType,
      {bool request = false}) {
    return FlutterUsualPermissionPlatform.instance.checkPermission(
      permissionType,
      request: request,
    );
  }

  ///request permission
  static Future<bool> requestPermission(PermissionType permissionType) {
    return FlutterUsualPermissionPlatform.instance
        .requestPermission(permissionType);
  }

  ///open notification settings
  static Future<void> openNotificationSettings() {
    return FlutterUsualPermissionPlatform.instance.openNotificationSettings();
  }
}
