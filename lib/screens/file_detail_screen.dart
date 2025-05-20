import '../models/file_item.dart';
import 'package:flutter/material.dart';

class FileDetailScreen extends StatelessWidget {
  final FileItem file;
  const FileDetailScreen({Key? key, required this.file}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(file.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${file.path}'),
            Text(
                'Type: ${file.type == FileType.directory ? 'Directory' : 'File'}'),
            Text('Size: ${file.sizeFormatted}'),
            Text('Modified: ${file.modified}'),
            if (file.metadata != null) ...[
              SizedBox(height: 16),
              Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...file.metadata!.entries
                  .map((e) => Text('${e.key}: ${e.value}')),
            ],
          ],
        ),
      ),
    );
  }
}
