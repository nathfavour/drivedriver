import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendService {
  static const String _baseUrl = 'http://127.0.0.1:8080';
  static const int _connectionTimeout = 5; // seconds

  final ValueNotifier<bool> isBackendRunning = ValueNotifier<bool>(false);
  final ValueNotifier<List<String>> availableDrives =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<Map<String, dynamic>> scanStats =
      ValueNotifier<Map<String, dynamic>>({});
  final ValueNotifier<List<dynamic>> fileMetadata =
      ValueNotifier<List<dynamic>>([]);

  // Singleton pattern
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  /// Initialize the backend service, checking if the backend is running
  /// and starting it if necessary
  Future<void> initialize() async {
    // Check if backend is running
    if (!await checkBackendRunning()) {
      // Try to start backend
      final started = await startBackend();
      if (started) {
        // Give backend time to start up
        await Future.delayed(const Duration(seconds: 3));
        isBackendRunning.value = await checkBackendRunning();
      }
    } else {
      isBackendRunning.value = true;
    }

    // If backend is running, load initial data
    if (isBackendRunning.value) {
      await refreshAllData();
    }

    // Set up periodic health check and data refresh
    _startPeriodicChecks();
  }

  /// Check if the backend is currently running
  Future<bool> checkBackendRunning() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
          )
          .timeout(Duration(seconds: _connectionTimeout));

      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }

  /// Start the backend process
  Future<bool> startBackend() async {
    try {
      // Get path to the backend executable
      final executablePath = await _getBackendExecutablePath();
      if (executablePath == null) {
        print('Failed to locate backend executable');
        return false;
      }

      // Start the backend process
      final process = await Process.start(
        executablePath,
        ['start'],
        mode: ProcessStartMode.detached,
      );

      // Log process output for debugging
      process.stdout.transform(utf8.decoder).listen((data) {
        print('Backend stdout: $data');
      });
      process.stderr.transform(utf8.decoder).listen((data) {
        print('Backend stderr: $data');
      });

      return true;
    } catch (e) {
      print('Failed to start backend: $e');
      return false;
    }
  }

  /// Stop the backend process
  Future<bool> stopBackend() async {
    try {
      final executablePath = await _getBackendExecutablePath();
      if (executablePath == null) {
        return false;
      }

      final result = await Process.run(executablePath, ['stop']);

      // Update status
      isBackendRunning.value = await checkBackendRunning();

      return result.exitCode == 0;
    } catch (e) {
      print('Failed to stop backend: $e');
      return false;
    }
  }

  /// Get all available drives from the backend
  Future<void> fetchDrives() async {
    if (!isBackendRunning.value) return;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/drives'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        availableDrives.value = List<String>.from(data['drives']);
      }
    } catch (e) {
      print('Failed to fetch drives: $e');
    }
  }

  /// Get scan statistics from the backend
  Future<void> fetchScanStats() async {
    if (!isBackendRunning.value) return;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/stats'));

      if (response.statusCode == 200) {
        scanStats.value = jsonDecode(response.body);
      }
    } catch (e) {
      print('Failed to fetch scan stats: $e');
    }
  }

  /// Get file metadata from the backend
  Future<void> fetchFileMetadata() async {
    if (!isBackendRunning.value) return;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/metadata'));

      if (response.statusCode == 200) {
        fileMetadata.value = jsonDecode(response.body);
      }
    } catch (e) {
      print('Failed to fetch file metadata: $e');
    }
  }

  /// Initiate a scan of a specific drive
  Future<bool> scanDrive(String path) async {
    if (!isBackendRunning.value) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'path': path}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to initiate scan: $e');
      return false;
    }
  }

  /// Refresh all data from the backend
  Future<void> refreshAllData() async {
    await fetchDrives();
    await fetchScanStats();
    await fetchFileMetadata();
  }

  /// Helper method to locate the backend executable
  Future<String?> _getBackendExecutablePath() async {
    // Try to find the executable in different locations based on platform

    // Default locations to check
    final List<String> possibleLocations = [
      'drivedriverb', // If in PATH
      '/usr/local/bin/drivedriverb',
      '/usr/bin/drivedriverb',
    ];

    // Add platform-specific locations
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        possibleLocations.add('$appData\\drivedriverb\\drivedriverb.exe');
      }
    } else if (Platform.isMacOS) {
      possibleLocations.add('/Applications/drivedriverb');
    }

    // Check each location
    for (final location in possibleLocations) {
      try {
        final file = File(location);
        if (await file.exists()) {
          return location;
        }
      } catch (_) {}
    }

    // Fallback: assume just the command name which might be in PATH
    return 'drivedriverb';
  }

  /// Set up periodic health checks and data refresh
  void _startPeriodicChecks() {
    // Check backend health every 30 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      final isRunning = await checkBackendRunning();

      // Only update if there's a change in status
      if (isRunning != isBackendRunning.value) {
        isBackendRunning.value = isRunning;

        // If backend just came online, refresh data
        if (isRunning) {
          await refreshAllData();
        }
      }

      // Continue indefinitely
      return true;
    });

    // Refresh data every 2 minutes if backend is running
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 2));
      if (isBackendRunning.value) {
        await refreshAllData();
      }
      return true;
    });
  }
}
