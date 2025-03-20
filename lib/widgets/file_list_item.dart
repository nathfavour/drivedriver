import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/file_item.dart';

class FileListItem extends StatelessWidget {
  final FileItem file;
  final VoidCallback? onTap;

  const FileListItem({
    Key? key,
    required this.file,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return ListTile(
      leading: Icon(
        file.type == FileType.directory
            ? Icons.folder
            : Icons.insert_drive_file,
        color: file.type == FileType.directory ? Colors.amber : Colors.blue,
      ),
      title: Text(file.name),
      subtitle: Text(
        '${file.type == FileType.file ? file.sizeFormatted : "Directory"} • ${dateFormat.format(file.modified)}',
      ),
      trailing: file.type == FileType.directory
          ? Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }
}
