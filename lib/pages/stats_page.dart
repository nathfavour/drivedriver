import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../widgets/file_type_chart.dart';
import '../widgets/placeholder_content.dart';
import '../widgets/animated_progress_ring.dart';
import '../theme/app_theme.dart';

class StatsPage extends StatefulWidget {
  final BackendService backendService;

  const StatsPage({Key? key, required this.backendService}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideUpAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideUpAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _refreshStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.backendService.fetchScanStats();
      _controller.reset();
      _controller.forward();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshStats,
        child: ValueListenableBuilder<Map<String, dynamic>>(
          valueListenable: widget.backendService.scanStats,
          builder: (context, stats, child) {
            if (!widget.backendService.isBackendRunning.value) {
              return PlaceholderContent(
                icon: Icons.cloud_off,
                title: 'Backend Not Running',
                message:
                    'The backend service is required to display statistics. '
                    'Start the backend using the button in the top right corner.',
                actionText: 'Start Backend',
                onAction: () async {
                  await widget.backendService.startBackend();
                  await Future.delayed(const Duration(seconds: 3));
                  await widget.backendService.fetchScanStats();
                },
              );
            }

            if (_isLoading && stats.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (stats.isEmpty) {
              return const PlaceholderContent(
                icon: Icons.analytics_outlined,
                title: 'No Statistics Available',
                message:
                    'No scan data has been collected yet. Scan a drive to generate statistics.',
              );
            }

            final timestamp = stats['timestamp'] as int? ?? 0;
            final totalFiles = stats['total_files'] as int? ?? 0;
            final totalSize = stats['total_size'] as int? ?? 0;
            final fileTypes =
                stats['file_types'] as Map<String, dynamic>? ?? {};

            // Convert file types for the chart
            final typeData = fileTypes.entries
                .map((e) => MapEntry(e.key, e.value as int))
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            // Take only top 10 file types for chart
            final topTypes = typeData.take(10).toList();

            // Calculate largest file type for ring progress indicators
            final largestCategory = typeData.isEmpty ? null : typeData.first;
            final largestCategoryPercentage = largestCategory != null
                ? largestCategory.value / totalFiles
                : 0.0;

            // Space used by top 5 types
            final topTypesUsed = typeData
                .take(5)
                .fold<int>(0, (sum, entry) => sum + entry.value);
            final topTypesPercentage =
                totalFiles > 0 ? topTypesUsed / totalFiles : 0.0;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Transform.translate(
                    offset: Offset(0, _slideUpAnimation.value),
                    child: Opacity(
                      opacity: _fadeInAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary cards in a horizontal row
                          SizedBox(
                            height: 160,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _SummaryCard(
                                  title: 'Total Files',
                                  value: totalFiles.toString(),
                                  icon: Icons.insert_drive_file,
                                  color: Colors.blue,
                                ),
                                _SummaryCard(
                                  title: 'Total Size',
                                  value: _formatFileSize(totalSize),
                                  icon: Icons.sd_storage,
                                  color: Colors.orange,
                                ),
                                _SummaryCard(
                                  title: 'File Types',
                                  value: fileTypes.length.toString(),
                                  icon: Icons.category,
                                  color: Colors.green,
                                ),
                                _SummaryCard(
                                  title: 'Last Scan',
                                  value: timestamp > 0
                                      ? _formatDateTime(timestamp)
                                      : 'Never',
                                  icon: Icons.history,
                                  color: Colors.purple,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // File Type Distribution
                          if (topTypes.isNotEmpty) ...[
                            Text(
                              'File Type Distribution',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 300,
                                      child: FileTypeChart(data: topTypes),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // File Type Insights
                            Text(
                              'File Type Insights',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),

                            // Two progress ring cards
                            Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Largest Category',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 16),
                                          AnimatedProgressRing(
                                            progress: largestCategoryPercentage,
                                            size: 150,
                                            strokeWidth: 15,
                                            color: Colors.blue,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${(largestCategoryPercentage * 100).toStringAsFixed(1)}%',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  largestCategory != null
                                                      ? (largestCategory
                                                              .key.isEmpty
                                                          ? 'No extension'
                                                          : '.${largestCategory.key}')
                                                      : '-',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            largestCategory != null
                                                ? '${largestCategory.value} files'
                                                : '-',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Top 5 Categories',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 16),
                                          AnimatedProgressRing(
                                            progress: topTypesPercentage,
                                            size: 150,
                                            strokeWidth: 15,
                                            color: Colors.green,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${(topTypesPercentage * 100).toStringAsFixed(1)}%',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Text(
                                                  'of files',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '$topTypesUsed out of $totalFiles files',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // File Type Breakdown
                            Text(
                              'File Type Breakdown',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...typeData.take(20).map((entry) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      entry.key.isEmpty
                                                          ? '(no extension)'
                                                          : '.${entry.key}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                    ),
                                                    FractionallySizedBox(
                                                      widthFactor: entry.value /
                                                          totalFiles,
                                                      child: Container(
                                                        height: 10,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${entry.value} files',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshStats,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        tooltip: 'Refresh statistics',
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
