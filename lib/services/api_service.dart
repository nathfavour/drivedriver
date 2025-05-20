import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/file_item.dart'; // Ensure this file exists and is correctly implemented
import '../models/scan_status.dart'; // Ensure this file exists and is correctly implemented

class ApiService extends ChangeNotifier {
  String? _baseUrl;

  Future<String> _getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl!;
    try {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final configFile = File('$home/.drivedriverb/config.json');
        if (await configFile.exists()) {
          final content = await configFile.readAsString();
          final json = jsonDecode(content);
          if (json is Map && json['port'] != null) {
            _baseUrl = 'http://127.0.0.1:${json['port']}';
            return _baseUrl!;
          }
        }
      }
    } catch (_) {}
    _baseUrl = 'http://127.0.0.1:8080';
    return _baseUrl!;
  }

  Future<List<FileItem>> getFileList(String path) async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.get(Uri.parse('$baseUrl/files?path=$path'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => FileItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load file list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<ScanStatus> getStatus() async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.get(Uri.parse('$baseUrl/status'));
      if (response.statusCode == 200) {
        return ScanStatus.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> startScan() async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(Uri.parse('$baseUrl/scan/start'));
      if (response.statusCode != 200) {
        throw Exception('Failed to start scan: ${response.statusCode}');
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getConfig() async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.get(Uri.parse('$baseUrl/config'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateConfig(Map<String, dynamic> config) async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update config: ${response.statusCode}');
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Create a file
  Future<bool> createFile(String path, {String? content}) async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/file/create'),
        headers: {'Content-Type': 'application/json'},
        body: json
            .encode({'path': path, if (content != null) 'content': content}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String path) async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/file/delete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': path}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Rename a file
  Future<bool> renameFile(String oldPath, String newPath) async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/file/rename'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': oldPath, 'new_path': newPath}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Copy a file
  Future<bool> copyFile(String srcPath, String destPath) async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/file/copy'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': srcPath, 'new_path': destPath}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Move a file
  Future<bool> moveFile(String srcPath, String destPath) async {
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/file/move'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'path': srcPath, 'new_path': destPath}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
