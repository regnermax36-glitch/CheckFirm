import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AppService {
  static Future<void> openApp(String packageName) async {
    await InstalledApps.startApp(packageName);
  }

  static Future<List<AppInfo>> getInstalledApps() async {
    return await InstalledApps.getInstalledApps();
  }
}
