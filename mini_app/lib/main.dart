import 'package:flutter/material.dart';
import 'package:mini_app/core/api_client.dart';
import 'package:mini_app/core/auth_service.dart';
import 'package:mini_app/core/constants.dart';
import 'package:mini_app/core/progress_service.dart';
import 'package:mini_app/core/telegram_bridge.dart';
import 'package:mini_app/screens/auth_gate.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/widgets/app_background.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final TelegramBridge telegram = TelegramBridge()..initialize();
  final ApiClient api = ApiClient();
  final AuthService auth = AuthService(api: api, telegram: telegram);
  final ProgressService progress = ProgressService(api: api);

  runApp(RechiApp(api: api, auth: auth, progress: progress));
}

/// Корневое приложение «Речи».
class RechiApp extends StatelessWidget {
  const RechiApp({
    super.key,
    required this.api,
    required this.auth,
    required this.progress,
  });

  final ApiClient api;
  final AuthService auth;
  final ProgressService progress;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<ProgressService>.value(value: progress),
      ],
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: const AuthGate(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery.withClampedTextScaling(
            minScaleFactor: 1,
            maxScaleFactor: 1.3,
            child: AppBackground(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
