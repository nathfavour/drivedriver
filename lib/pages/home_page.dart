import 'package:drivedriver/pages/drives_page.dart';
import 'package:drivedriver/pages/files_page.dart';
import 'package:drivedriver/pages/stats_page.dart';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class HomePage extends StatefulWidget {
  final BackendService backendService;

  const HomePage({Key? key, required this.backendService}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DriveDriver'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: widget.backendService.isBackendRunning,
            builder: (context, isRunning, child) {
              return Chip(
                label:
                    Text(isRunning ? 'Backend: Running' : 'Backend: Stopped'),
                backgroundColor: isRunning ? Colors.green : Colors.red,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing data...')));
              await widget.backendService.refreshAllData();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data refreshed')));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'DriveDriver',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Drives'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Files & Stats'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('File Browser'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Latest Stats'),
              leading: const Icon(Icons.insert_chart),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/latest_stats');
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: widget.backendService.isBackendRunning,
              builder: (context, isRunning, child) {
                return ListTile(
                  title: Text(isRunning ? 'Stop Backend' : 'Start Backend'),
                  leading: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                  onTap: () async {
                    if (isRunning) {
                      await widget.backendService.stopBackend();
                    } else {
                      final result = await widget.backendService.startBackend();
                      // Wait for backend to start
                      await Future.delayed(const Duration(seconds: 3));
                      final running =
                          await widget.backendService.checkBackendRunning();

                      if (!running && !result) {
                        // Show message if failed to start backend
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context); // Close drawer first
                        }

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Backend Not Started'),
                            content: Text(
                                'Could not start the backend automatically. Please:\n\n'
                                '1. Make sure "drivedriverb" is installed and in your PATH\n'
                                '2. Try running "drivedriverb start" manually from a terminal\n'
                                '3. Check if the backend is already running on another process'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DrivesPage(backendService: widget.backendService),
          StatsPage(backendService: widget.backendService),
          FilesPage(backendService: widget.backendService),
        ],
      ),
    );
  }
}
