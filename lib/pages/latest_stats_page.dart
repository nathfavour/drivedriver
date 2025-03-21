import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class LatestStatsPage extends StatefulWidget {
  const LatestStatsPage({Key? key}) : super(key: key);

  @override
  _LatestStatsPageState createState() => _LatestStatsPageState();
}

class _LatestStatsPageState extends State<LatestStatsPage> {
  Map<String, dynamic>? stats;
  Timer? _timer;
  final String path = '.drivedriver/data/latest_stats.json';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _loadStats());
  }

  Future<void> _loadStats() async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          stats = jsonDecode(content);
        });
      }
    } catch (e) {
      // Optionally handle read errors
      setState(() {
        stats = {'error': 'Unable to load stats: $e'};
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildSummaryCard() {
    if (stats == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (stats!['error'] != null) {
      return Center(child: Text(stats!['error']));
    }
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Divider(),
            Text('Timestamp: ${stats!['timestamp'] ?? '-'}'),
            Text('Total Files: ${stats!['total_files'] ?? '-'}'),
            Text('Total Size: ${stats!['total_size'] ?? '-'} bytes'),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypes() {
    if (stats == null || stats!['file_types'] == null) {
      return SizedBox.shrink();
    }
    final Map fileTypes = stats!['file_types'];
    final entries = fileTypes.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Type Distribution',
                style: Theme.of(context).textTheme.titleLarge),
            Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final key = entries[index].key.toString();
                final count = entries[index].value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(key.isEmpty ? '(no ext)' : '.$key',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value:
                              (count as int) / (stats!['total_files'] as int),
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('$count'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Latest Stats'),
      ),
      body: stats == null
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                children: [
                  _buildSummaryCard(),
                  _buildFileTypes(),
                ],
              ),
            ),
    );
  }
}
