import '../models/file_item.dart';
import '../models/scan_status.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class FileListScreen extends StatefulWidget {
  final String path;
  const FileListScreen({Key? key, required this.path}) : super(key: key);
  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  bool _isLoading = true;
  List<FileItem> _files = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      _files = await api.getFileList(widget.path);
    } catch (e) {
      _error = e.toString();
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Files in ${widget.path}')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FileListScreen(path: file.path),
                            ),
                          );
                        } else {
                          // Show file details
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: _loadFiles,
      ),
    );
  }
}
