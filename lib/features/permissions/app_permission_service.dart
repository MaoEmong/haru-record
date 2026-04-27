import 'package:permission_handler/permission_handler.dart';

abstract interface class AppPermissionService {
  Future<bool> ensureLocationTrackingPermission();
  Future<bool> ensureNotificationPermission();
}

class PermissionHandlerAppPermissionService implements AppPermissionService {
  const PermissionHandlerAppPermissionService();

  @override
  Future<bool> ensureLocationTrackingPermission() async {
    final foreground = await Permission.locationWhenInUse.request();
    if (!foreground.isGranted) return false;

    final background = await Permission.locationAlways.status;
    if (background.isDenied || background.isRestricted) {
      await Permission.locationAlways.request();
    }
    return true;
  }

  @override
  Future<bool> ensureNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
