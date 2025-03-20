import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/file_item.dart';
import '../models/scan_status.dart';

class ApiService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:8080'; // Default Rust backend URL

  Future<List<FileItem>> getFileList(String path) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/files?path=$path'));

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
    try {
      final response = await http.get(Uri.parse('$_baseUrl/status'));

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
    try {
      final response = await http.post(Uri.parse('$_baseUrl/scan/start'));

      if (response.statusCode != 200) {
        throw Exception('Failed to start scan: ${response.statusCode}');
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getConfig() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/config'));

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
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/config'),
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
}
