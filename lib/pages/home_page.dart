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
                      await widget.backendService.startBackend();
                      // Wait for backend to start
                      await Future.delayed(const Duration(seconds: 3));
                      await widget.backendService.checkBackendRunning();
                    }
                    Navigator.pop(context);
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
