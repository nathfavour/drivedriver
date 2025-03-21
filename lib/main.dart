import 'package:drivedriver/pages/home_page.dart';
import 'package:drivedriver/pages/latest_stats_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'services/backend_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize backend service
  final backendService = BackendService();
  backendService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
      ],
      child: DriveDriverApp(backendService: backendService),
    ),
  );
}

class DriveDriverApp extends StatelessWidget {
  final BackendService backendService;

  const DriveDriverApp({Key? key, required this.backendService})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveDriver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(backendService: backendService),
        '/settings': (context) => SettingsScreen(),
        '/latest_stats': (context) => LatestStatsPage(),
      },
    );
  }
}
