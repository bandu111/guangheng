import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'repositories/backend_repository.dart';
import 'services/backend_api_client.dart';
import 'services/local_notification_service.dart';
import 'viewmodels/backend_view_model.dart';
import 'viewmodels/main_view_model.dart';
import 'views/main/main_shell.dart';

class GuangHengApp extends StatelessWidget {
  const GuangHengApp({
    super.key,
    this.enableInteractive3d = true,
    this.initialData,
    this.repository,
  });

  final bool enableInteractive3d;
  final BackendSnapshot? initialData;
  final BackendRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainViewModel()),
        ChangeNotifierProvider(
          create: (_) {
            final viewModel = BackendViewModel(
              repository ?? BackendRepository(BackendApiClient()),
              data: initialData,
              notificationSync: initialData == null
                  ? LocalNotificationService.instance.sync
                  : null,
            );
            if (initialData == null) {
              viewModel.load();
            }
            return viewModel;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '光衡',
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,

        theme: AppTheme.light,

        home: MainShell(enableInteractive3d: enableInteractive3d),
      ),
    );
  }
}
