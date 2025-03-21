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
  final ValueNotifier<Map<String, dynamic>> systemStatus =
      ValueNotifier<Map<String, dynamic>>({});
  final ValueNotifier<Map<String, dynamic>> configSettings =
      ValueNotifier<Map<String, dynamic>>({});
  final ValueNotifier<Map<String, dynamic>> fileListData =
      ValueNotifier<Map<String, dynamic>>({
    'total': 0,
    'page': 1,
    'page_size': 50,
    'total_pages': 0,
    'files': [],
  });

  // Singleton pattern
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  // Add file listing filtering state
  int _currentPage = 1;
  int _pageSize = 50;
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String? _filterCategory;
  int? _filterSizeMin;
  int? _filterSizeMax;
  String? _searchTerm;

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
      print('Checking backend at $_baseUrl/health');
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
          )
          .timeout(Duration(seconds: _connectionTimeout));

      print('Backend response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed: $e');
      // Try alternate port or localhost specifically
      try {
        print('Trying alternate address 10.0.2.2:8080 (for emulators)');
        final altResponse = await http
            .get(
              Uri.parse('http://10.0.2.2:8080/health'),
            )
            .timeout(Duration(seconds: _connectionTimeout));

        if (altResponse.statusCode == 200) {
          // If this works, update the base URL
          _updateBaseUrl('http://10.0.2.2:8080');
          return true;
        }
      } catch (e2) {
        print('Alternate health check failed: $e2');
      }
      return false;
    }
  }

  // Add method to update base URL if needed
  void _updateBaseUrl(String newUrl) {
    print('Updating base URL to $newUrl');
    // Using a static variable to update the singleton's base URL
    _overriddenBaseUrl = newUrl;
  }

  // Getter for base URL that allows for runtime override
  String get baseUrl => _overriddenBaseUrl ?? _baseUrl;
  static String? _overriddenBaseUrl;

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
      final response = await http.get(Uri.parse('${baseUrl}/drives'));

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
      final response = await http.get(Uri.parse('${baseUrl}/stats'));

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
      final response = await http.get(Uri.parse('${baseUrl}/metadata'));

      if (response.statusCode == 200) {
        // Expecting a list of metadata
        fileMetadata.value = List<dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('Failed to fetch file metadata: $e');
    }
  }

  /// Get system status from the backend
  Future<void> fetchSystemStatus() async {
    if (!isBackendRunning.value) return;

    try {
      final response = await http.get(Uri.parse('${baseUrl}/status'));

      if (response.statusCode == 200) {
        systemStatus.value = jsonDecode(response.body);
      }
    } catch (e) {
      print('Failed to fetch system status: $e');
    }
  }

  /// Get configuration from the backend
  Future<void> fetchConfig() async {
    if (!isBackendRunning.value) return;

    try {
      final response = await http.get(Uri.parse('${baseUrl}/config'));

      if (response.statusCode == 200) {
        configSettings.value = jsonDecode(response.body);
      }
    } catch (e) {
      print('Failed to fetch config: $e');
    }
  }

  /// Update configuration on the backend
  Future<bool> updateConfig(Map<String, dynamic> newConfig) async {
    if (!isBackendRunning.value) return false;

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newConfig),
      );

      if (response.statusCode == 200) {
        // Update local config
        await fetchConfig();
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to update config: $e');
      return false;
    }
  }

  /// Get file list with filtering and pagination
  Future<void> fetchFileList({
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    String? filterCategory,
    int? filterSizeMin,
    int? filterSizeMax,
    String? searchTerm,
  }) async {
    if (!isBackendRunning.value) return;

    // Update state with provided parameters or use existing values
    _currentPage = page ?? _currentPage;
    _pageSize = pageSize ?? _pageSize;
    _sortBy = sortBy ?? _sortBy;
    _sortOrder = sortOrder ?? _sortOrder;
    _filterCategory = filterCategory ?? _filterCategory;
    _filterSizeMin = filterSizeMin ?? _filterSizeMin;
    _filterSizeMax = filterSizeMax ?? _filterSizeMax;
    _searchTerm = searchTerm ?? _searchTerm;

    try {
      // Build query parameters
      final queryParams = {
        'page': _currentPage.toString(),
        'page_size': _pageSize.toString(),
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
      };

      if (_filterCategory != null) {
        queryParams['filter_category'] = _filterCategory!;
      }

      if (_filterSizeMin != null) {
        queryParams['filter_size_min'] = _filterSizeMin.toString();
      }

      if (_filterSizeMax != null) {
        queryParams['filter_size_max'] = _filterSizeMax.toString();
      }

      if (_searchTerm != null && _searchTerm!.isNotEmpty) {
        queryParams['search_term'] = _searchTerm!;
      }

      final uri =
          Uri.parse('${baseUrl}/files').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        fileListData.value = jsonDecode(response.body);
      } else {
        print('Error fetching file list: ${response.statusCode}');
        throw Exception('Failed to load file list: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch file list: $e');
      throw Exception('Failed to load file list: $e');
    }
  }

  /// Get detailed information about a specific file
  Future<Map<String, dynamic>> getFileDetails(String filePath) async {
    if (!isBackendRunning.value) {
      return {'error': 'Backend not running'};
    }

    try {
      // Encode the path for URL
      final encodedPath = Uri.encodeComponent(filePath);
      final response =
          await http.get(Uri.parse('${baseUrl}/files/$encodedPath'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error fetching file details: ${response.statusCode}');
        return {'error': 'Failed to load file details: ${response.statusCode}'};
      }
    } catch (e) {
      print('Failed to fetch file details: $e');
      return {'error': 'Exception: $e'};
    }
  }

  /// Initiate a scan of a specific drive
  Future<bool> scanDrive(String path) async {
    if (!isBackendRunning.value) return false;

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'path': path}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to initiate scan: $e');
      return false;
    }
  }

  /// Enhanced refresh method that updates all data
  Future<void> refreshAllData() async {
    try {
      await Future.wait([
        fetchDrives(),
        fetchScanStats(),
        fetchSystemStatus(),
        fetchConfig(),
        fetchFileList(),
      ]);
    } catch (e) {
      print('Error during data refresh: $e');
    }
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
