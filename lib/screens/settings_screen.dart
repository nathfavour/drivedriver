import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _config = {};
  final _formKey = GlobalKey<FormState>();
  final _pathsController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _pathsController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final config = await api.getConfig();

      if (mounted) {
        setState(() {
          _config = config;
          _isLoading = false;

          // Initialize controllers
          if (_config.containsKey('scan_paths')) {
            _pathsController.text =
                (_config['scan_paths'] as List<dynamic>).join('\n');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);

      // Update config with form values
      final updatedConfig = Map<String, dynamic>.from(_config);
      updatedConfig['scan_paths'] = _pathsController.text
          .split('\n')
          .where((path) => path.trim().isNotEmpty)
          .toList();

      await api.updateConfig(updatedConfig);

      if (mounted) {
        setState(() {
          _config = updatedConfig;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Settings saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildSettingsForm(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $_error'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadConfig,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Paths',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Enter one path per line to be scanned',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _pathsController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: '/home/user\n/media/data',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter at least one path';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _saveConfig,
                child: Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
