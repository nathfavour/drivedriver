import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/file_item.dart';
import '../models/scan_status.dart';
import '../widgets/file_list_item.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentPath = '/';
  bool _isLoading = true;
  List<FileItem> _files = [];
  ScanStatus? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Refresh status every 5 seconds
    Future.delayed(Duration.zero, () {
      _setupStatusRefresh();
    });
  }

  void _setupStatusRefresh() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        _loadStatus();
        _setupStatusRefresh();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final files = await api.getFileList(_currentPath);
      final status = await api.getStatus();

      if (mounted) {
        setState(() {
          _files = files;
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStatus() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final status = await api.getStatus();

      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    } catch (e) {
      // Silently fail status update
    }
  }

  void _navigateToDirectory(String path) {
    setState(() {
      _currentPath = path;
    });
    _loadData();
  }

  void _navigateUp() {
    if (_currentPath == '/') return;

    final parts = _currentPath.split('/');
    parts.removeLast();
    if (parts.isEmpty) {
      _navigateToDirectory('/');
    } else {
      _navigateToDirectory(parts.join('/'));
    }
  }

  Future<void> _startScan() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.startScan();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scan started')));
      _loadStatus();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DriveDriver'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_status != null && _status!.isScanning)
            LinearProgressIndicator(
              value: _status!.progress > 0 ? _status!.progress : null,
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_upward),
                  onPressed: _currentPath == '/' ? null : _navigateUp,
                ),
                Expanded(
                  child: Text(
                    _currentPath == '/' ? 'Root' : _currentPath,
                    style: Theme.of(context).textTheme.subtitle1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(child: _buildFileList()),
          Padding(padding: const EdgeInsets.all(8.0), child: _buildStatusBar()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _status?.isScanning == true ? null : _startScan,
        child: Icon(Icons.search),
        tooltip: 'Start Scan',
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: Text('Retry')),
          ],
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(child: Text('No files found'));
    }

    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return FileListItem(
          file: file,
          onTap: () {
            if (file.type == FileType.directory) {
              _navigateToDirectory(file.path);
            }
          },
        );
      },
    );
  }

  Widget _buildStatusBar() {
    if (_status == null) {
      return Text('Status: Unknown');
    }

    final status = _status!;
    if (status.isScanning) {
      return Text(
        'Scanning... ${status.filesScanned} of ${status.totalFiles} files processed',
      );
    } else if (status.lastScan != null) {
      return Text(
        'Last scan: ${status.lastScan!.toLocal().toString().split('.').first}',
      );
    } else {
      return Text('No scan performed yet');
    }
  }
}
