import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/file_item.dart'; // Ensure this file exists and is correctly implemented
import '../models/scan_status.dart'; // Ensure this file exists and is correctly implemented
import '../widgets/file_list_item.dart'; // Ensure this file exists and is correctly implemented

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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
      appBar: AppBar(title: Text('DriveDriver Dashboard')),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(child: _buildFileList()),
        ],
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: Icon(Icons.add),
        onSelected: (value) async {
          if (value == 'create_file') {
            // Show dialog to create file
            final fileName = await showDialog<String>(
              context: context,
              builder: (context) => _CreateFileDialog(),
            );
            if (fileName != null && fileName.isNotEmpty) {
              final api = Provider.of<ApiService>(context, listen: false);
              await api.createFile('$_currentPath/$fileName');
              _loadData();
            }
          } else if (value == 'create_folder') {
            // Show dialog to create folder
            final folderName = await showDialog<String>(
              context: context,
              builder: (context) => _CreateFileDialog(isFolder: true),
            );
            if (folderName != null && folderName.isNotEmpty) {
              final api = Provider.of<ApiService>(context, listen: false);
              await api.createFile('$_currentPath/$folderName', content: null);
              _loadData();
            }
          } else if (value == 'refresh') {
            _loadData();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'create_file', child: Text('Create File')),
          PopupMenuItem(value: 'create_folder', child: Text('Create Folder')),
          PopupMenuItem(value: 'refresh', child: Text('Refresh')),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_files.isEmpty) {
      return Center(child: Text('No files found.'));
    }
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return ListTile(
          leading: Icon(file.type == FileType.directory
              ? Icons.folder
              : Icons.insert_drive_file),
          title: Text(file.name),
          subtitle: Text(file.sizeFormatted),
          onTap: () {
            if (file.type == FileType.directory) {
              _navigateToDirectory(file.path);
            } else {
              // Show file details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileDetailScreen(file: file),
                ),
              );
            }
          },
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              final api = Provider.of<ApiService>(context, listen: false);
              if (value == 'delete') {
                await api.deleteFile(file.path);
                _loadData();
              } else if (value == 'rename') {
                final newName = await showDialog<String>(
                  context: context,
                  builder: (context) => _RenameFileDialog(oldName: file.name),
                );
                if (newName != null && newName.isNotEmpty) {
                  await api.renameFile(file.path, '${_currentPath}/$newName');
                  _loadData();
                }
              } else if (value == 'copy') {
                // Implement copy logic (show dialog for destination)
              } else if (value == 'move') {
                // Implement move logic (show dialog for destination)
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'delete', child: Text('Delete')),
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'copy', child: Text('Copy')),
              PopupMenuItem(value: 'move', child: Text('Move')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar() {
    if (_status == null) {
      return SizedBox.shrink();
    }
    return ListTile(
      leading: Icon(Icons.info),
      title: Text('Scan: ${_status!.isScanning ? 'In Progress' : 'Idle'}'),
      subtitle: Text(
          'Files Scanned: ${_status!.filesScanned} / ${_status!.totalFiles}'),
      trailing: _status!.isScanning
          ? CircularProgressIndicator(value: _status!.progress)
          : IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadStatus,
            ),
    );
  }

// Dialogs for file/folder creation and renaming
}

class _CreateFileDialog extends StatelessWidget {
  final bool isFolder;
  const _CreateFileDialog({this.isFolder = false});
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: Text(isFolder ? 'Create Folder' : 'Create File'),
      content: TextField(
        controller: controller,
        decoration:
            InputDecoration(hintText: isFolder ? 'Folder name' : 'File name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text('Create'),
        ),
      ],
    );
  }
}

class _RenameFileDialog extends StatelessWidget {
  final String oldName;
  const _RenameFileDialog({required this.oldName});
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: oldName);
    return AlertDialog(
      title: Text('Rename File'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: 'New name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text('Rename'),
        ),
      ],
    );
  }
}
