import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_accessibility_service/constants.dart';

class AccessibilityServiceHandler {
  static Future<bool> isEnabled() async {
    return await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
  }

  static Future<void> requestPermission() async {
    await FlutterAccessibilityService.requestAccessibilityPermission();
  }

  static Future<void> performAction(String actionType) async {
    switch (actionType) {
      case 'back':
        await FlutterAccessibilityService.performGlobalAction(GlobalAction.globalActionBack);
        break;
      case 'home':
        await FlutterAccessibilityService.performGlobalAction(GlobalAction.globalActionHome);
        break;
      case 'recents':
        await FlutterAccessibilityService.performGlobalAction(GlobalAction.globalActionRecents);
        break;
      case 'notifications':
        await FlutterAccessibilityService.performGlobalAction(GlobalAction.globalActionNotifications);
        break;
      case 'quickSettings':
        await FlutterAccessibilityService.performGlobalAction(GlobalAction.globalActionQuickSettings);
        break;
    }
  }
}
