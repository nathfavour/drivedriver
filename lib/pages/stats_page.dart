import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../widgets/file_type_chart.dart';

class StatsPage extends StatefulWidget {
  final BackendService backendService;

  const StatsPage({Key? key, required this.backendService}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    await widget.backendService.fetchScanStats();
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
              return const Center(
                child:
                    Text('Backend is not running. Start it to see statistics.'),
              );
            }

            if (stats.isEmpty) {
              return const Center(
                child: Text('No scan statistics available yet'),
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

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Summary',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        InfoRow(
                          label: 'Last Scan:',
                          value: timestamp > 0
                              ? _formatDateTime(timestamp)
                              : 'Never',
                        ),
                        const SizedBox(height: 8),
                        InfoRow(
                          label: 'Total Files:',
                          value: totalFiles.toString(),
                        ),
                        const SizedBox(height: 8),
                        InfoRow(
                          label: 'Total Size:',
                          value: _formatFileSize(totalSize),
                        ),
                        const SizedBox(height: 8),
                        InfoRow(
                          label: 'File Types:',
                          value: fileTypes.length.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (topTypes.isNotEmpty) ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File Type Distribution',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Divider(),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: FileTypeChart(data: topTypes),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File Type Breakdown',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          ...typeData.take(20).map((entry) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        entry.key.isEmpty
                                            ? '(no extension)'
                                            : '.${entry.key}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: LinearProgressIndicator(
                                        value: entry.value / totalFiles,
                                        backgroundColor: Colors.grey[200],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${entry.value} files'),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshStats,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh statistics',
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value),
        ),
      ],
    );
  }
}
