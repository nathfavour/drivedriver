import 'package:drivedriver/pages/drives_page.dart';
import 'package:drivedriver/pages/files_page.dart';
import 'package:drivedriver/pages/stats_page.dart';
import 'package:drivedriver/widgets/backend_status_button.dart';
import 'package:drivedriver/widgets/modern_drawer.dart';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  final BackendService backendService;

  const HomePage({Key? key, required this.backendService}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  Future<void> _refreshData() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Refreshing data...')));
    await widget.backendService.refreshAllData();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Data refreshed')));
  }

  void _launchVerboseMonitor() {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', 'drivedriverb', 'monitor']);
    } else {
      Process.run('x-terminal-emulator', ['-e', 'drivedriverb', 'monitor']);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build drawer items
    final drawerItems = [
      const DrawerItem(
        title: 'Drives',
        icon: Icons.storage,
      ),
      const DrawerItem(
        title: 'Statistics',
        icon: Icons.insert_chart,
      ),
      const DrawerItem(
        title: 'Files',
        icon: Icons.folder,
      ),
    ];

    // Build drawer footer items
    final drawerFooterItems = [
      ListTile(
        leading: const Icon(Icons.bar_chart),
        title: const Text('Latest Stats'),
        onTap: () {
          Navigator.pushNamed(context, '/latest_stats');
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Settings'),
        onTap: () {
          Navigator.pushNamed(context, '/settings');
        },
      ),
      ListTile(
        leading: const Icon(Icons.terminal),
        title: const Text('Verbose Monitor'),
        onTap: _launchVerboseMonitor,
      ),
    ];

    final pageTitle = [
      'Drives Manager',
      'Storage Statistics',
      'File Browser',
    ][_selectedIndex];

    return Scaffold(
      body: Row(
        children: [
          // Persistent side navigation
          ModernDrawer(
            items: drawerItems,
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemTapped,
            footerItems: drawerFooterItems,
          ),
          // Main content area
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Icon(
                      drawerItems[_selectedIndex].icon,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(pageTitle),
                  ],
                ),
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh data',
                    onPressed: _refreshData,
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: BackendStatusButton(
                      backendService: widget.backendService,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                children: [
                  DrivesPage(backendService: widget.backendService),
                  StatsPage(backendService: widget.backendService),
                  FilesPage(backendService: widget.backendService),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
