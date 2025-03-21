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

class _DrivesPageState extends State<DrivesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRefreshing = false;

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
        child: ValueListenableBuilder<List<String>>(
          valueListenable: widget.backendService.availableDrives,
          builder: (context, drives, child) {
            if (!widget.backendService.isBackendRunning.value) {
              return PlaceholderContent(
                icon: Icons.cloud_off,
                title: 'Backend Not Running',
                message:
                    'The backend service is required to discover and scan drives. '
                    'Start the backend using the button in the top right corner.',
                actionText: 'Start Backend',
                onAction: () async {
                  await widget.backendService.startBackend();
                  await Future.delayed(const Duration(seconds: 3));
                  await widget.backendService.fetchDrives();
                },
              );
            }

            if (_isRefreshing) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (drives.isEmpty) {
              return const PlaceholderContent(
                icon: Icons.search_off,
                title: 'No Drives Found',
                message:
                    'No drives were detected on your system. If you believe this is an error, '
                    'try refreshing or check if the backend has proper permissions.',
              );
            }

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 3 / 2.5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: drives.length,
                  itemBuilder: (context, index) {
                    // Calculate individual animation delay based on index
                    final delay = index * 0.2;
                    final slideValue = _controller.value > delay
                        ? (((_controller.value - delay) / (1 - delay))
                            .clamp(0.0, 1.0))
                        : 0.0;

                    final slideAnimation = Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).transform(Curves.easeOutCubic.transform(slideValue));

                    final fadeAnimation = Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ).transform(Curves.easeOut.transform(slideValue));

                    return FadeTransition(
                      opacity: AlwaysStoppedAnimation(fadeAnimation),
                      child: SlideTransition(
                        position: AlwaysStoppedAnimation(slideAnimation),
                        child: DriveCard(
                          drivePath: drives[index],
                          onScan: () => _scanDrive(drives[index]),
                        ),
                      ),
                    );
                  },
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

class DriveCard extends StatefulWidget {
  final String drivePath;
  final VoidCallback onScan;

  const DriveCard({
    Key? key,
    required this.drivePath,
    required this.onScan,
  }) : super(key: key);

  @override
  State<DriveCard> createState() => _DriveCardState();
}

class _DriveCardState extends State<DriveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
      if (isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = widget.drivePath == '/' ||
        (Platform.isWindows && widget.drivePath.length <= 3);
    final displayName = isRoot
        ? (Platform.isWindows ? 'System Drive' : 'Root')
        : widget.drivePath.split(Platform.isWindows ? '\\' : '/').last;

    // Random capacity for visualization (just for UI display)
    final random = math.Random(widget.drivePath.hashCode);
    final capacityPercentage = random.nextDouble() * 0.8 + 0.1; // 10% to 90%
    final totalSpaceGB = (random.nextInt(900) + 100) / 100; // 1GB to 10GB
    final usedSpaceGB = totalSpaceGB * capacityPercentage;

    // Drive type indicator
    final isDisk = displayName.toLowerCase().contains('disk') ||
        displayName.toLowerCase().contains('drive') ||
        isRoot;
    final isExternal = displayName.toLowerCase().contains('usb') ||
        displayName.toLowerCase().contains('external');
    final isNetwork = displayName.toLowerCase().contains('network') ||
        widget.drivePath.startsWith('//') ||
        widget.drivePath.startsWith('\\\\');

    IconData driveIcon;
    Color iconColor;
    String driveType;

    if (isNetwork) {
      driveIcon = Icons.cloud;
      iconColor = Colors.blue;
      driveType = 'Network Drive';
    } else if (isExternal) {
      driveIcon = Icons.usb;
      iconColor = Colors.orange;
      driveType = 'External Drive';
    } else if (isRoot) {
      driveIcon = Icons.computer;
      iconColor = Colors.teal;
      driveType = 'System Drive';
    } else {
      driveIcon = Icons.storage;
      iconColor = Colors.blueGrey;
      driveType = 'Local Drive';
    }

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        final elevation =
            Tween<double>(begin: 2, end: 8).evaluate(_hoverController);
        final scale =
            Tween<double>(begin: 1.0, end: 1.03).evaluate(_hoverController);

        return MouseRegion(
          onEnter: (_) => _handleHover(true),
          onExit: (_) => _handleHover(false),
          child: Transform.scale(
            scale: scale,
            child: Card(
              elevation: elevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: _isHovered
                    ? BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                        width: 2,
                      )
                    : BorderSide.none,
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
                      widget.drivePath,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
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
                        onPressed: widget.onScan,
                        icon: const Icon(Icons.search),
                        label: const Text('Scan Drive'),
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
