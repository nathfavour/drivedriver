import 'package:flutter/material.dart';
import 'dart:io';

class FileDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> fileDetails;

  const FileDetailsDialog({
    Key? key,
    required this.fileDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (fileDetails.containsKey('error')) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(fileDetails['error']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      );
    }

    final fileName = fileDetails['name'] as String;
    final filePath = fileDetails['path'] as String;
    final created = _formatTimestamp(fileDetails['created'] as int);
    final modified = _formatTimestamp(fileDetails['modified'] as int);
    final size = fileDetails['size_formatted'] as String;
    final category = fileDetails['category'] as String;
    final mimeType = fileDetails['mime_type'] as String;
    final importance = fileDetails['importance'] as int;
    final isDuplicate = fileDetails['is_duplicate'] as bool;
    final duplicateOf = fileDetails['duplicate_of'];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getCategoryIcon(category),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        filePath,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Size', size),
                    _buildDetailRow('Created', created),
                    _buildDetailRow('Modified', modified),
                    _buildDetailRow('Category', category),
                    _buildDetailRow('MIME Type', mimeType),
                    _buildDetailRow(
                        'Importance', _getImportanceText(importance)),
                    if (isDuplicate)
                      _buildDetailRow('Duplicate',
                          'Yes - Original: ${duplicateOf ?? "Unknown"}'),
                    SizedBox(height: 16),
                    Text(
                      'Technical Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Path: $filePath'),
                          Text('Full Size: ${fileDetails['size']} bytes'),
                          Text('Extension: ${fileDetails['extension']}'),
                          if (fileDetails['ai_analysis'] != null) ...[
                            SizedBox(height: 12),
                            Text('AI Analysis:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                'Purpose: ${fileDetails['ai_analysis']['file_purpose']}'),
                            Text(
                                'Recommendation: ${fileDetails['ai_analysis']['deletion_recommendation'] ? 'Consider deleting' : 'Keep'}'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.folder),
                  label: Text('Open Location'),
                  onPressed: () {
                    _openFolder(filePath);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(Icons.open_in_new),
                  label: Text('Open File'),
                  onPressed: () {
                    _openFile(filePath);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 32, color: color),
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
    if (importance >= 80) return '$importance - Critical';
    if (importance >= 60) return '$importance - High';
    if (importance >= 40) return '$importance - Medium';
    if (importance >= 20) return '$importance - Low';
    return '$importance - Minimal';
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
