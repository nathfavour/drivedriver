import 'package:drivedriver/pages/latest_stats_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'services/backend_service.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => DashboardScreen(),
        '/settings': (context) => SettingsScreen(),
        '/latest_stats': (context) => LatestStatsPage(), // added new route
      },
    );
  }
}
