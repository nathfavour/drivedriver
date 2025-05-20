import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../widgets/placeholder_content.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import 'dart:math' as math;

class DrivesPage extends StatefulWidget {
  final BackendService backendService;

  const DrivesPage({Key? key, required this.backendService}) : super(key: key);

  @override
  _DrivesPageState createState() => _DrivesPageState();
}

class DriveInfo {
  final String mountPoint;
  final String fsType;
  final int totalSpace;
  final int availableSpace;
  final int usedSpace;
  final bool isRemovable;

  DriveInfo({
    required this.mountPoint,
    required this.fsType,
    required this.totalSpace,
    required this.availableSpace,
    required this.usedSpace,
    required this.isRemovable,
  });

  factory DriveInfo.fromJson(Map<String, dynamic> json) {
    return DriveInfo(
      mountPoint: json['mount_point'] ?? '',
      fsType: json['fs_type'] ?? '',
      totalSpace: json['total_space'] ?? 0,
      availableSpace: json['available_space'] ?? 0,
      usedSpace: json['used_space'] ?? 0,
      isRemovable: json['is_removable'] ?? false,
    );
  }
}

class _DrivesPageState extends State<DrivesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRefreshing = false;
  List<DriveInfo> _drives = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _refreshDrives();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshDrives() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.backendService.fetchDrives();
      // Parse real drive info from backend
      final drivesRaw = widget.backendService.availableDrives.value;
      final drivesJson =
          widget.backendService.systemStatus.value['drives'] ?? [];
      _drives = drivesJson is List
          ? drivesJson.map((e) => DriveInfo.fromJson(e)).toList()
          : [];
      _controller.forward(from: 0.0);
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _scanDrive(String path) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text('Starting scan of $path...'),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    final success = await widget.backendService.scanDrive(path);

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Scan of $path started successfully'
            : 'Failed to start scan'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshDrives,
        child: _isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : _drives.isEmpty
                ? const PlaceholderContent(
                    icon: Icons.search_off,
                    title: 'No Drives Found',
                    message:
                        'No drives were detected on your system. If you believe this is an error, try refreshing or check if the backend has proper permissions.',
                  )
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          childAspectRatio: 3 / 2.5,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: _drives.length,
                        itemBuilder: (context, index) {
                          final drive = _drives[index];
                          // Calculate animation
                          final delay = index * 0.2;
                          final slideValue = _controller.value > delay
                              ? (((_controller.value - delay) / (1 - delay))
                                  .clamp(0.0, 1.0))
                              : 0.0;
                          final slideAnimation = Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).transform(
                              Curves.easeOutCubic.transform(slideValue));
                          final fadeAnimation = Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).transform(Curves.easeOut.transform(slideValue));
                          return FadeTransition(
                            opacity: AlwaysStoppedAnimation(fadeAnimation),
                            child: SlideTransition(
                              position: AlwaysStoppedAnimation(slideAnimation),
                              child: DriveCard(
                                driveInfo: drive,
                                onScan: () => _scanDrive(drive.mountPoint),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshDrives,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        tooltip: 'Refresh drives',
      ),
    );
  }
}

class DriveCard extends StatelessWidget {
  final DriveInfo driveInfo;
  final VoidCallback onScan;

  const DriveCard({Key? key, required this.driveInfo, required this.onScan})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalSpaceGB = driveInfo.totalSpace / (1024 * 1024 * 1024);
    final usedSpaceGB = driveInfo.usedSpace / (1024 * 1024 * 1024);
    final capacityPercentage = driveInfo.totalSpace > 0
        ? driveInfo.usedSpace / driveInfo.totalSpace
        : 0.0;
    final displayName = driveInfo.mountPoint == '/'
        ? 'Root'
        : driveInfo.mountPoint.split('/').last;
    final driveType = driveInfo.isRemovable ? 'Removable Drive' : 'Local Drive';
    final driveIcon = driveInfo.isRemovable ? Icons.usb : Icons.storage;
    final iconColor = driveInfo.isRemovable ? Colors.orange : Colors.blueGrey;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    driveIcon,
                    size: 32,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driveType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              driveInfo.mountPoint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${usedSpaceGB.toStringAsFixed(1)}GB / ${totalSpaceGB.toStringAsFixed(1)}GB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: capacityPercentage,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      capacityPercentage > 0.85
                          ? Colors.red
                          : capacityPercentage > 0.7
                              ? Colors.orange
                              : Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.search),
                label: const Text('Scan Drive'),
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
