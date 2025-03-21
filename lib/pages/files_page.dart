import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import 'dart:io';

class FilesPage extends StatefulWidget {
  final BackendService backendService;

  const FilesPage({Key? key, required this.backendService}) : super(key: key);

  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  final List<String> _categories = [
    'All',
    'Document',
    'Image',
    'Video',
    'Audio',
    'Archive',
    'Application',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _refreshFiles();
  }

  Future<void> _refreshFiles() async {
    await widget.backendService.fetchFileMetadata();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _openFile(String path) async {
    if (await File(path).exists()) {
      if (Platform.isWindows) {
        Process.run('explorer', [path]);
      } else if (Platform.isMacOS) {
        Process.run('open', [path]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [path]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Cannot open file on this platform: $path')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('File not found: $path')));
    }
  }

  void _sortFiles(List<dynamic> files, int columnIndex, bool ascending) {
    switch (columnIndex) {
      case 0: // Name
        files.sort((a, b) => ascending
            ? a['name'].compareTo(b['name'])
            : b['name'].compareTo(a['name']));
        break;
      case 1: // Size
        files.sort((a, b) => ascending
            ? a['size'].compareTo(b['size'])
            : b['size'].compareTo(a['size']));
        break;
      case 2: // Category
        files.sort((a, b) => ascending
            ? a['category'].compareTo(b['category'])
            : b['category'].compareTo(a['category']));
        break;
      case 3: // Importance
        files.sort((a, b) => ascending
            ? a['importance'].compareTo(b['importance'])
            : b['importance'].compareTo(a['importance']));
        break;
    }
  }

  List<dynamic> _filterFiles(List<dynamic> files) {
    return files.where((file) {
      // Apply category filter
      if (_selectedCategory != 'All' &&
          file['category'].toString().toLowerCase() !=
              _selectedCategory.toLowerCase()) {
        return false;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final name = file['name'].toString().toLowerCase();
        final path = file['path'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || path.contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Files',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Category filter
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Category',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshFiles,
              child: ValueListenableBuilder<List<dynamic>>(
                valueListenable: widget.backendService.fileMetadata,
                builder: (context, files, child) {
                  if (!widget.backendService.isBackendRunning.value) {
                    return const Center(
                      child: Text(
                          'Backend is not running. Start it to see files.'),
                    );
                  }

                  if (files.isEmpty) {
                    return const Center(
                      child: Text('No file metadata available yet'),
                    );
                  }

                  final filteredFiles = _filterFiles(files);
                  _sortFiles(filteredFiles, _sortColumnIndex, _sortAscending);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        sortAscending: _sortAscending,
                        sortColumnIndex: _sortColumnIndex,
                        columns: [
                          DataColumn(
                            label: const Text('File Name'),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumnIndex = columnIndex;
                                _sortAscending = ascending;
                              });
                            },
                          ),
                          DataColumn(
                            label: const Text('Size'),
                            numeric: true,
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumnIndex = columnIndex;
                                _sortAscending = ascending;
                              });
                            },
                          ),
                          DataColumn(
                            label: const Text('Category'),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumnIndex = columnIndex;
                                _sortAscending = ascending;
                              });
                            },
                          ),
                          DataColumn(
                            label: const Text('Importance'),
                            numeric: true,
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumnIndex = columnIndex;
                                _sortAscending = ascending;
                              });
                            },
                          ),
                          const DataColumn(
                            label: Text('Actions'),
                          ),
                        ],
                        rows: filteredFiles.map((file) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Tooltip(
                                  message: file['path'].toString(),
                                  child: Text(
                                    file['name'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(_formatFileSize(file['size'] as int)),
                              ),
                              DataCell(
                                Text(file['category'].toString()),
                              ),
                              DataCell(
                                ImportanceIndicator(
                                  score: file['importance'] as int,
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new),
                                      tooltip: 'Open file',
                                      onPressed: () =>
                                          _openFile(file['path'].toString()),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.folder),
                                      tooltip: 'Open containing folder',
                                      onPressed: () {
                                        final path = file['path'].toString();
                                        final directory = path.substring(
                                            0,
                                            path.lastIndexOf(
                                                Platform.pathSeparator));
                                        _openFile(directory);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshFiles,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh files',
      ),
    );
  }
}

class ImportanceIndicator extends StatelessWidget {
  final int score;

  const ImportanceIndicator({
    Key? key,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (score >= 80) {
      color = Colors.red;
      label = 'Critical';
    } else if (score >= 60) {
      color = Colors.orange;
      label = 'High';
    } else if (score >= 40) {
      color = Colors.amber;
      label = 'Medium';
    } else if (score >= 20) {
      color = Colors.blue;
      label = 'Low';
    } else {
      color = Colors.grey;
      label = 'Minimal';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('$score ($label)'),
      ],
    );
  }
}
