import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendService {
  static const String _baseUrl = 'http://127.0.0.1:8080';
  static const int _connectionTimeout = 5; // seconds

  // Current port the backend is running on
  int _currentPort = 8080;

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
    // First try to locate any existing backend by checking multiple ports
    if (!await _findRunningBackend()) {
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

  // Try to find a running backend on various ports
  Future<bool> _findRunningBackend() async {
    // Try the default port first
    if (await _checkPortRunning(_currentPort)) {
      return true;
    }

    // Try common alternative ports
    final portsToTry = [8081, 8082, 8000, 3000];
    for (final port in portsToTry) {
      if (await _checkPortRunning(port)) {
        _currentPort = port;
        _updateBaseUrl('http://127.0.0.1:$port');
        return true;
      }
    }

    // Also check for Android emulator special IP
    if (Platform.isAndroid) {
      for (final port in [8080, ...(portsToTry)]) {
        final altUrl = 'http://10.0.2.2:$port';
        if (await _checkUrlRunning(altUrl)) {
          _currentPort = port;
          _updateBaseUrl(altUrl);
          return true;
        }
      }
    }

    return false;
  }

  // Check if backend is running on a specific port
  Future<bool> _checkPortRunning(int port) async {
    return await _checkUrlRunning('http://127.0.0.1:$port');
  }

  // Check if backend is running at a specific URL
  Future<bool> _checkUrlRunning(String url) async {
    try {
      print('Checking backend at $url/health');
      final response = await http
          .get(
            Uri.parse('$url/health'),
          )
          .timeout(Duration(seconds: _connectionTimeout));

      return response.statusCode == 200;
    } catch (e) {
      print('Backend check failed at $url: $e');
      return false;
    }
  }

  /// Check if the backend is currently running
  Future<bool> checkBackendRunning() async {
    return await _checkUrlRunning('${baseUrl}/health');
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

  /// Start the backend process using the full path from user home dir
  Future<bool> startBackend({int port = 8080}) async {
    try {
      // Prevent subprocess execution on mobile platforms.
      if (Platform.isAndroid || Platform.isIOS) {
        print(
            "Subprocess execution not allowed on mobile platforms. Please start the backend manually.");
        return false;
      }

      // Check if the backend is already running from health endpoint.
      if (await checkBackendRunning()) {
        print("Backend already running, skipping start command.");
        return true;
      }

      _currentPort = port;
      final List<String> possiblePaths = [
        // User home install
        '${Platform.environment['HOME']}/.drivedriver/drivedriverb',
        // System-wide install
        '/usr/local/bin/drivedriverb',
        '/usr/bin/drivedriverb',
        // Project-relative (for dev)
        '${Directory.current.path}/drivedriverb',
        '${Directory.current.path}/bin/drivedriverb',
        './drivedriverb',
        // Just the command (PATH)
        'drivedriverb',
      ];

      String? executablePath;
      for (final path in possiblePaths) {
        try {
          final file = File(path);
          if (path == 'drivedriverb') {
            // Try running directly from PATH
            final result = await Process.run('which', ['drivedriverb']);
            if (result.exitCode == 0 &&
                (result.stdout as String).trim().isNotEmpty) {
              executablePath = 'drivedriverb';
              break;
            }
          } else if (await file.exists()) {
            executablePath = path;
            break;
          }
        } catch (_) {}
      }

      if (executablePath == null) {
        print(
            'Could not find drivedriverb backend executable in any known location.');
        return false;
      }

      print(
          'Backend: Attempting to start backend service using $executablePath on port $_currentPort...');
      final result = await Process.run(
        executablePath,
        ['start', '--port', port.toString()],
        runInShell: true,
      );

      print('Backend stdout: \n${result.stdout}');
      print('Backend stderr: \n${result.stderr}');

      if (result.exitCode != 0) {
        print('Backend failed to start with exit code: \n${result.exitCode}');
        return false;
      }

      // Update the base URL to use the new port
      _updateBaseUrl('http://127.0.0.1:$port');

      print('Backend start command executed successfully on port $port');
      return true;
    } catch (e, stackTrace) {
      print('Failed to start backend: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Stop the backend process using the full path from user home dir
  Future<bool> stopBackend() async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null) {
        print("HOME environment variable not set.");
        return false;
      }
      final executablePath = '$home/.drivedriver/drivedriverb';
      print(
          'Backend: Attempting to stop backend service using $executablePath ...');

      final result =
          await Process.run(executablePath, ['stop'], runInShell: true);
      print('Backend stop stdout: ${result.stdout}');
      print('Backend stop stderr: ${result.stderr}');
      isBackendRunning.value = await checkBackendRunning();
      if (result.exitCode != 0) {
        print('Backend stop command failed with exit code: ${result.exitCode}');
        return false;
      }
      print('Backend stopped successfully');
      return true;
    } catch (e, stackTrace) {
      print('Failed to stop backend: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Launch verbose monitoring mode
  Future<Process?> launchVerboseMonitor() async {
    if (Platform.isAndroid || Platform.isIOS) {
      print("Verbose monitoring not available on mobile platforms.");
      return null;
    }

    try {
      final home = Platform.environment['HOME'];
      if (home == null) {
        print("HOME environment variable not set.");
        return null;
      }

      final executablePath = '$home/.drivedriver/drivedriverb';
      print(
          'Launching verbose monitor using $executablePath on port $_currentPort...');

      // Start process but don't wait for it to complete
      final process = await Process.start(
          executablePath, ['verbose', '--port', _currentPort.toString()],
          mode: ProcessStartMode.inheritStdio);

      return process;
    } catch (e) {
      print('Failed to launch verbose monitor: $e');
      return null;
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
        // Cast response as a List<dynamic>
        fileMetadata.value = jsonDecode(response.body) as List<dynamic>;
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

    // Local project-specific path first (most likely to work)
    final String projectPath = '${Directory.current.path}/drivedriverb';

    // Default locations to check
    final List<String> possibleLocations = [
      projectPath,
      '${Directory.current.path}/bin/drivedriverb',
      './drivedriverb', // Relative to current directory
      'drivedriverb', // If in PATH
      '/usr/local/bin/drivedriverb',
      '/usr/bin/drivedriverb',
      '${Platform.environment['HOME']}/drivedriverb',
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

    // Print all possible locations for debugging
    print('Checking for backend executable in these locations:');
    for (final location in possibleLocations) {
      print('- $location');
    }

    // Check each location
    for (final location in possibleLocations) {
      try {
        final file = File(location);
        if (await file.exists()) {
          print('Found backend executable at: $location');
          return location;
        }
      } catch (e) {
        print('Error checking path $location: $e');
      }
    }

    print('Could not find backend executable in any standard location');
    // Fallback: assume just the command name which might be in PATH
    return 'drivedriverb';
  }

  /// Set up periodic health checks and data refresh
  void _startPeriodicChecks() {
    // Check backend health every 30 seconds and attempt restart only if confirmed not running.
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      final isRunning = await checkBackendRunning();

      if (!isRunning) {
        // Double-check before attempting restart
        final confirmedNotRunning = !(await checkBackendRunning());
        if (confirmedNotRunning) {
          print("Backend not running; attempting restart...");
          final started = await startBackend();
          if (started) {
            print("Backend restarted successfully.");
            // Wait a bit before re-checking
            await Future.delayed(const Duration(seconds: 3));
          } else {
            print("Failed to restart backend.");
          }
        } else {
          print("Backend is running; skipping restart.");
        }
      }

      if (isRunning != isBackendRunning.value) {
        isBackendRunning.value = isRunning;
        if (isRunning) {
          await refreshAllData();
        }
      }

      return true; // Continue indefinitely.
    });

    // Refresh data every 2 minutes if backend is running.
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 2));
      if (isBackendRunning.value) {
        await refreshAllData();
      }
      return true;
    });
  }
}
