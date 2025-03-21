import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernDrawer extends StatelessWidget {
  final List<DrawerItem> items;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<Widget>? footerItems;

  const ModernDrawer({
    Key? key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.footerItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: HeaderBackgroundPainter(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.storage,
                            size: 40,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DriveDriver',
                                style: AppTheme.headlineStyle.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              Text(
                                'Disk Space Management',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                return _buildDrawerItem(context, item, isSelected, () {
                  onItemSelected(index);
                });
              },
            ),
          ),
          if (footerItems != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: footerItems!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    DrawerItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
        selected: isSelected,
      ),
    );
  }
}

class DrawerItem {
  final String title;
  final IconData icon;
  final String? badge;

  const DrawerItem({
    required this.title,
    required this.icon,
    this.badge,
  });
}

class HeaderBackgroundPainter extends CustomPainter {
  final Color color;

  HeaderBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Create wave pattern
    final path = Path();
    path.moveTo(0, size.height * 0.8);

    // First curve
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.8,
    );

    // Second curve
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.8,
    );

    // Connect to bottom-right corner
    path.lineTo(size.width, size.height);

    // Connect to bottom-left corner
    path.lineTo(0, size.height);

    // Close the path
    path.close();

    canvas.drawPath(path, paint);

    // Add some circles for decoration
    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      size.width * 0.15,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.3),
      size.width * 0.1,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant HeaderBackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
