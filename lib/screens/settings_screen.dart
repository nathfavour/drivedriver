import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/placeholder_content.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _config = {};
  final _formKey = GlobalKey<FormState>();
  final _pathsController = TextEditingController();
  String? _error;
  late AnimationController _animController;
  bool _isDarkMode = false;
  bool _autoScan = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadConfig();
  }

  @override
  void dispose() {
    _pathsController.dispose();
    _animController.dispose();
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

          // Initialize settings
          _isDarkMode = _config['dark_mode'] ?? false;
          _autoScan = _config['auto_scan'] ?? false;
        });

        _animController.forward();
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
      updatedConfig['dark_mode'] = _isDarkMode;
      updatedConfig['auto_scan'] = _autoScan;

      await api.updateConfig(updatedConfig);

      if (mounted) {
        setState(() {
          _config = updatedConfig;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.settings),
            const SizedBox(width: 12),
            const Text('Settings'),
          ],
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildSettingsForm(),
    );
  }

  Widget _buildErrorView() {
    return PlaceholderContent(
      icon: Icons.error_outline,
      title: 'Error Loading Settings',
      message: 'An error occurred while loading settings: $_error',
      actionText: 'Retry',
      onAction: _loadConfig,
    );
  }

  Widget _buildSettingsForm() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Scan Paths',
                  icon: Icons.folder_open,
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter one path per line to be scanned',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pathsController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: '/home/user\n/media/data',
                          filled: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter at least one path';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                _buildSectionCard(
                  title: 'App Settings',
                  icon: Icons.tune,
                  index: 1,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle:
                            const Text('Use dark theme throughout the app'),
                        value: _isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                        },
                        secondary: const Icon(Icons.dark_mode),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Auto Scan'),
                        subtitle: const Text(
                            'Automatically scan drives when connected'),
                        value: _autoScan,
                        onChanged: (value) {
                          setState(() {
                            _autoScan = value;
                          });
                        },
                        secondary: const Icon(Icons.loop),
                      ),
                    ],
                  ),
                ),
                _buildSectionCard(
                  title: 'Advanced',
                  icon: Icons.code,
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete_forever),
                        title: const Text('Clear All Data'),
                        subtitle:
                            const Text('Delete all scan results and settings'),
                        onTap: () {
                          _showConfirmDialog(
                            title: 'Clear All Data?',
                            message:
                                'This will erase all scan results and reset all settings. This cannot be undone.',
                            onConfirm: () {
                              // Implement data clearing
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('All data cleared')),
                              );
                            },
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.restart_alt),
                        title: const Text('Reset Settings'),
                        subtitle: const Text('Reset all settings to defaults'),
                        onTap: () {
                          _showConfirmDialog(
                            title: 'Reset Settings?',
                            message:
                                'This will reset all settings to their default values.',
                            onConfirm: () {
                              // Implement settings reset
                              setState(() {
                                _pathsController.text = '';
                                _isDarkMode = false;
                                _autoScan = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Settings reset to defaults')),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required int index,
  }) {
    final delay = index * 0.2;
    final slideValue = _animController.value > delay
        ? (((_animController.value - delay) / (1 - delay)).clamp(0.0, 1.0))
        : 0.0;

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).transform(Curves.easeOutCubic.transform(slideValue));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).transform(Curves.easeOut.transform(slideValue));

    return Opacity(
      opacity: fadeAnimation,
      child: Transform.translate(
        offset: Offset(slideAnimation.dx * 100, 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
