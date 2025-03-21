import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import 'animated_progress_ring.dart';

class FileDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> fileDetails;

  const FileDetailsDialog({
    Key? key,
    required this.fileDetails,
  }) : super(key: key);

  @override
  State<FileDetailsDialog> createState() => _FileDetailsDialogState();
}

class _FileDetailsDialogState extends State<FileDetailsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fileDetails.containsKey('error')) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(widget.fileDetails['error']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      );
    }

    final fileName = widget.fileDetails['name'] as String;
    final filePath = widget.fileDetails['path'] as String;
    final created = _formatTimestamp(widget.fileDetails['created'] as int);
    final modified = _formatTimestamp(widget.fileDetails['modified'] as int);
    final size = widget.fileDetails['size_formatted'] as String;
    final category = widget.fileDetails['category'] as String;
    final mimeType = widget.fileDetails['mime_type'] as String;
    final importance = widget.fileDetails['importance'] as int;
    final isDuplicate = widget.fileDetails['is_duplicate'] as bool;
    final duplicateOf = widget.fileDetails['duplicate_of'];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Dialog(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 700,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: Row(
                          children: [
                            _getCategoryIcon(category),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    filePath,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(0.8),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Importance Indicator
                                Center(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 24.0),
                                    child: Column(
                                      children: [
                                        AnimatedProgressRing(
                                          progress: importance / 100,
                                          size: 120,
                                          color:
                                              _getImportanceColor(importance),
                                          strokeWidth: 10,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$importance',
                                                style: const TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Text(
                                                'Score',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _getImportanceText(importance),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _getImportanceColor(importance),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Basic Info Card
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Basic Information',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const Divider(),
                                        _buildDetailRow('Size', size),
                                        _buildDetailRow('Created', created),
                                        _buildDetailRow('Modified', modified),
                                        _buildDetailRow('Category', category),
                                        _buildDetailRow('MIME Type', mimeType),
                                        if (isDuplicate)
                                          _buildDetailRow('Duplicate',
                                              'Yes - Original: ${duplicateOf ?? "Unknown"}'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Technical Details Card
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Technical Details',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const Divider(),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Path: $filePath'),
                                              Text(
                                                  'Full Size: ${widget.fileDetails['size']} bytes'),
                                              Text(
                                                  'Extension: ${widget.fileDetails['extension']}'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (widget.fileDetails['ai_analysis'] !=
                                    null) ...[
                                  const SizedBox(height: 16),
                                  // AI Analysis Card
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.psychology),
                                              const SizedBox(width: 8),
                                              Text(
                                                'AI Analysis',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const Divider(),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[800]
                                                  : Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'Purpose: ${widget.fileDetails['ai_analysis']['file_purpose']}'),
                                                Text(
                                                  'Recommendation: ${widget.fileDetails['ai_analysis']['deletion_recommendation'] ? 'Consider deleting' : 'Keep'}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: widget.fileDetails[
                                                                'ai_analysis'][
                                                            'deletion_recommendation']
                                                        ? Colors.red
                                                        : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.folder),
                              label: const Text('Open Location'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.8),
                              ),
                              onPressed: () {
                                _openFolder(filePath);
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open File'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                _openFile(filePath);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;

    switch (category.toLowerCase()) {
      case 'document':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'image':
        icon = Icons.image;
        color = Colors.green;
        break;
      case 'video':
        icon = Icons.videocam;
        color = Colors.red;
        break;
      case 'audio':
        icon = Icons.audiotrack;
        color = Colors.purple;
        break;
      case 'archive':
        icon = Icons.folder_zip;
        color = Colors.amber;
        break;
      case 'application':
        icon = Icons.apps;
        color = Colors.cyan;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 32, color: Colors.white),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)} ${_pad(date.hour)}:${_pad(date.minute)}:${_pad(date.second)}';
  }

  String _pad(int number) {
    return number.toString().padLeft(2, '0');
  }

  String _getImportanceText(int importance) {
    if (importance >= 80) return 'Critical Importance';
    if (importance >= 60) return 'High Importance';
    if (importance >= 40) return 'Medium Importance';
    if (importance >= 20) return 'Low Importance';
    return 'Minimal Importance';
  }

  Color _getImportanceColor(int importance) {
    if (importance >= 80) return Colors.red.shade700;
    if (importance >= 60) return Colors.orange.shade700;
    if (importance >= 40) return Colors.amber.shade700;
    if (importance >= 20) return Colors.blue.shade700;
    return Colors.grey.shade700;
  }

  void _openFile(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer', [path]);
      } else if (Platform.isMacOS) {
        Process.run('open', [path]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [path]);
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  void _openFolder(String filePath) {
    try {
      final directory = filePath.substring(
        0,
        filePath.lastIndexOf(Platform.pathSeparator),
      );

      if (Platform.isWindows) {
        Process.run('explorer', [directory]);
      } else if (Platform.isMacOS) {
        Process.run('open', [directory]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [directory]);
      }
    } catch (e) {
      print('Error opening folder: $e');
    }
  }
}
