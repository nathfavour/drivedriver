import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import 'dart:io';
import '../widgets/placeholder_content.dart';
import '../widgets/file_details_dialog.dart';

class FilesPage extends StatefulWidget {
  final BackendService backendService;

  const FilesPage({Key? key, required this.backendService}) : super(key: key);

  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  // Filtering options
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

  // Size filter values in MB
  double _minSize = 0;
  double _maxSize = 1000;
  bool _sizeFilterEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (!widget.backendService.isBackendRunning.value) {
      setState(() {
        _errorMessage = "Backend not running";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.backendService.fetchFileList(
        filterCategory: _selectedCategory == 'All' ? null : _selectedCategory,
        filterSizeMin:
            _sizeFilterEnabled ? (_minSize * 1024 * 1024).round() : null,
        filterSizeMax:
            _sizeFilterEnabled ? (_maxSize * 1024 * 1024).round() : null,
        searchTerm:
            _searchController.text.isEmpty ? null : _searchController.text,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePage(int page) async {
    if (!widget.backendService.isBackendRunning.value) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.backendService.fetchFileList(page: page);
    } catch (e) {
      // Error handling
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _loadFiles();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _sizeFilterEnabled = false;
      _minSize = 0;
      _maxSize = 1000;
    });
    _loadFiles();
  }

  Future<void> _viewFileDetails(Map<String, dynamic> file) async {
    final filePath = file['path'].toString();

    try {
      final details = await widget.backendService.getFileDetails(filePath);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => FileDetailsDialog(fileDetails: details),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading file details: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFiles,
              child: _buildFileListView(),
            ),
          ),
          _buildPaginationControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFiles,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh files',
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Files',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadFiles();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _loadFiles(),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
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
                  _loadFiles();
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterDialog();
                },
                tooltip: 'Advanced filters',
              ),
            ],
          ),
          if (_sizeFilterEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Size filter: '),
                Expanded(
                  child: Text(
                    '${_minSize.round()} MB to ${_maxSize.round()} MB',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.clear),
                  label: Text('Clear'),
                  onPressed: () {
                    setState(() {
                      _sizeFilterEnabled = false;
                    });
                    _loadFiles();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileListView() {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: widget.backendService.fileListData,
      builder: (context, fileData, child) {
        if (_errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading files',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadFiles,
                  child: Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (_isLoading && (fileData['files'] as List).isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (!widget.backendService.isBackendRunning.value) {
          return PlaceholderContent(
            icon: Icons.cloud_off,
            title: 'Backend Not Running',
            message: 'Start the backend to browse your files.',
            actionText: 'Start Backend',
            onAction: () async {
              await widget.backendService.startBackend();
              await Future.delayed(Duration(seconds: 3));
              if (await widget.backendService.checkBackendRunning()) {
                _loadFiles();
              }
            },
          );
        }

        final files = fileData['files'] as List;

        if (files.isEmpty) {
          return PlaceholderContent(
            icon: Icons.folder_open,
            title: 'No Files Found',
            message: 'Try changing your filters or scan a drive.',
            actionText: 'Reset Filters',
            onAction: _resetFilters,
          );
        }

        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index] as Map<String, dynamic>;
            final name = file['name'] as String;
            final path = file['path'] as String;
            final size = file['size_formatted'] as String;
            final category = file['category'] as String;
            final importance = file['importance'] as int;

            // Determine icon based on category
            IconData icon;
            Color iconColor;

            switch (category.toLowerCase()) {
              case 'document':
                icon = Icons.description;
                iconColor = Colors.blue;
                break;
              case 'image':
                icon = Icons.image;
                iconColor = Colors.green;
                break;
              case 'video':
                icon = Icons.videocam;
                iconColor = Colors.red;
                break;
              case 'audio':
                icon = Icons.audiotrack;
                iconColor = Colors.purple;
                break;
              case 'archive':
                icon = Icons.folder_zip;
                iconColor = Colors.amber;
                break;
              case 'application':
                icon = Icons.apps;
                iconColor = Colors.cyan;
                break;
              default:
                icon = Icons.insert_drive_file;
                iconColor = Colors.grey;
            }

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(icon, color: iconColor, size: 36),
                title: Text(name, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  path,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(size),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Importance: '),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _getImportanceColor(importance),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new),
                              SizedBox(width: 8),
                              Text('Open'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'folder',
                          child: Row(
                            children: [
                              Icon(Icons.folder),
                              SizedBox(width: 8),
                              Text('Show in folder'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info),
                              SizedBox(width: 8),
                              Text('View details'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'open':
                            _openFile(path);
                            break;
                          case 'folder':
                            final directory = path.substring(
                              0,
                              path.lastIndexOf(Platform.pathSeparator),
                            );
                            _openFile(directory);
                            break;
                          case 'details':
                            _viewFileDetails(file);
                            break;
                        }
                      },
                    ),
                  ],
                ),
                onTap: () => _viewFileDetails(file),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationControls() {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: widget.backendService.fileListData,
      builder: (context, fileData, child) {
        final totalPages = fileData['total_pages'] as int? ?? 0;
        final currentPage = fileData['page'] as int? ?? 1;

        if (totalPages <= 1) return SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.first_page),
                onPressed: currentPage > 1 ? () => _changePage(1) : null,
              ),
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed:
                    currentPage > 1 ? () => _changePage(currentPage - 1) : null,
              ),
              SizedBox(width: 16),
              Text('Page $currentPage of $totalPages'),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => _changePage(currentPage + 1)
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.last_page),
                onPressed: currentPage < totalPages
                    ? () => _changePage(totalPages)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Advanced Filters'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text('Filter by size'),
                    value: _sizeFilterEnabled,
                    onChanged: (value) {
                      setState(() {
                        _sizeFilterEnabled = value;
                      });
                    },
                  ),
                  if (_sizeFilterEnabled) ...[
                    Text(
                        'Size range (MB): ${_minSize.round()} - ${_maxSize.round()}'),
                    RangeSlider(
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      labels: RangeLabels(
                        '${_minSize.round()} MB',
                        '${_maxSize.round()} MB',
                      ),
                      values: RangeValues(_minSize, _maxSize),
                      onChanged: (values) {
                        setState(() {
                          _minSize = values.start;
                          _maxSize = values.end;
                        });
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Update the state in the parent
                    this.setState(() {});
                    _loadFiles();
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getImportanceColor(int importance) {
    if (importance >= 80) return Colors.red;
    if (importance >= 60) return Colors.orange;
    if (importance >= 40) return Colors.amber;
    if (importance >= 20) return Colors.blue;
    return Colors.grey;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
