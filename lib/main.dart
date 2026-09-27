import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_environment.dart';
import 'services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('GuangHeng Environment: ${AppEnvironmentConfig.current.name}');
    debugPrint('GuangHeng API: ${AppEnvironmentConfig.baseUrl}');
  }
  await LocalNotificationService.instance.initialize();
  runApp(const GuangHengApp());
}
