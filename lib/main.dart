import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(DriveDriverApp());
}

class DriveDriverApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveDriver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashboardScreen(),
    );
  }
}
