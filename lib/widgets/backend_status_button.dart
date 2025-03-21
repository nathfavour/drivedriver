import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class BackendStatusButton extends StatefulWidget {
  final BackendService backendService;

  const BackendStatusButton({
    Key? key,
    required this.backendService,
  }) : super(key: key);

  @override
  State<BackendStatusButton> createState() => _BackendStatusButtonState();
}

class _BackendStatusButtonState extends State<BackendStatusButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleBackendState() async {
    final isRunning = widget.backendService.isBackendRunning.value;

    setState(() {
      _isLoading = true;
    });

    if (isRunning) {
      await widget.backendService.stopBackend();
    } else {
      await widget.backendService.startBackend();

      // Give backend time to start
      await Future.delayed(const Duration(seconds: 3));

      // Refresh data if backend is now running
      if (widget.backendService.isBackendRunning.value) {
        await widget.backendService.refreshAllData();
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.backendService.isBackendRunning,
      builder: (context, isRunning, _) {
        final Color statusColor = isRunning ? Colors.green : Colors.blue;
        final String statusText = isRunning ? 'Running' : 'Stopped';
        final IconData statusIcon =
            isRunning ? Icons.cloud_done : Icons.cloud_off;

        return Tooltip(
          message:
              'Backend is $statusText. Tap to ${isRunning ? 'stop' : 'start'}.',
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isRunning ? 1.0 : _pulseAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _toggleBackendState,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: statusColor),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 100,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Backend: $statusText',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
