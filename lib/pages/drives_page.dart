import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import 'dart:io';

class DrivesPage extends StatefulWidget {
  final BackendService backendService;

  const DrivesPage({Key? key, required this.backendService}) : super(key: key);

  @override
  _DrivesPageState createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  @override
  void initState() {
    super.initState();
    _refreshDrives();
  }

  Future<void> _refreshDrives() async {
    await widget.backendService.fetchDrives();
  }

  Future<void> _scanDrive(String path) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Starting scan of $path...')));

    final success = await widget.backendService.scanDrive(path);

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(SnackBar(
      content: Text(success
          ? 'Scan of $path started successfully'
          : 'Failed to start scan'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshDrives,
        child: ValueListenableBuilder<List<String>>(
          valueListenable: widget.backendService.availableDrives,
          builder: (context, drives, child) {
            if (!widget.backendService.isBackendRunning.value) {
              return const Center(
                child: Text('Backend is not running. Start it to see drives.'),
              );
            }

            if (drives.isEmpty) {
              return const Center(
                child: Text('No drives found'),
              );
            }

            return ListView.builder(
              itemCount: drives.length,
              itemBuilder: (context, index) {
                final drive = drives[index];
                return DriveCard(
                  drivePath: drive,
                  onScan: () => _scanDrive(drive),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshDrives,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh drives',
      ),
    );
  }
}

class DriveCard extends StatelessWidget {
  final String drivePath;
  final VoidCallback onScan;

  const DriveCard({
    Key? key,
    required this.drivePath,
    required this.onScan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRoot =
        drivePath == '/' || (Platform.isWindows && drivePath.length <= 3);
    final displayName = isRoot
        ? (Platform.isWindows ? 'System Drive' : 'Root')
        : drivePath.split(Platform.isWindows ? '\\' : '/').last;

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRoot ? Icons.computer : Icons.storage,
                  size: 36,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        drivePath,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.search),
                  label: const Text('Scan Drive'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
