import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import 'accessible_widgets.dart';

class GestureNavigationWidget extends StatelessWidget {
  const GestureNavigationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, service, child) {
        return AccessibleCard(
          semanticLabel: 'Gesture-based navigation settings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gesture Navigation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enable gesture shortcuts for easier navigation',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Gesture navigation toggle
              AccessibleSwitch(
                value: service.gestureNavigationEnabled,
                onChanged: (_) => service.toggleGestureNavigation(),
                label: 'Enable Gesture Navigation',
                semanticLabel: 'Toggle gesture navigation shortcuts',
              ),
              
              if (service.gestureNavigationEnabled) ...[
                const SizedBox(height: 16),
                const GestureShortcutsList(),
                const SizedBox(height: 16),
                const GestureTrainingArea(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class GestureShortcutsList extends StatelessWidget {
  const GestureShortcutsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      GestureShortcut(
        gesture: 'Double Tap',
        action: 'Activate/Select item',
        icon: Icons.touch_app,
        description: 'Tap twice quickly on any element to activate it',
      ),
      GestureShortcut(
        gesture: 'Swipe Right',
        action: 'Navigate forward',
        icon: Icons.swipe_right,
        description: 'Swipe right to go to next page or item',
      ),
      GestureShortcut(
        gesture: 'Swipe Left',
        action: 'Navigate back',
        icon: Icons.swipe_left,
        description: 'Swipe left to go back or previous item',
      ),
      GestureShortcut(
        gesture: 'Swipe Up',
        action: 'Scroll up / Previous',
        icon: Icons.swipe_up,
        description: 'Swipe up to scroll up or move to previous element',
      ),
      GestureShortcut(
        gesture: 'Swipe Down',
        action: 'Scroll down / Next',
        icon: Icons.swipe_down,
        description: 'Swipe down to scroll down or move to next element',
      ),
      GestureShortcut(
        gesture: 'Long Press',
        action: 'Show context menu',
        icon: Icons.more_vert,
        description: 'Press and hold for additional options',
      ),
      GestureShortcut(
        gesture: 'Two-finger Tap',
        action: 'Quick settings',
        icon: Icons.settings,
        description: 'Tap with two fingers for accessibility settings',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gesture,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Available Gestures',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...shortcuts.map((shortcut) => GestureShortcutTile(shortcut: shortcut)),
        ],
      ),
    );
  }
}

class GestureShortcutTile extends StatelessWidget {
  final GestureShortcut shortcut;
  
  const GestureShortcutTile({
    Key? key,
    required this.shortcut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              shortcut.icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortcut.gesture,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  shortcut.action,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  shortcut.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GestureTrainingArea extends StatefulWidget {
  const GestureTrainingArea({Key? key}) : super(key: key);

  @override
  State<GestureTrainingArea> createState() => _GestureTrainingAreaState();
}

class _GestureTrainingAreaState extends State<GestureTrainingArea>
    with TickerProviderStateMixin {
  String _lastGesture = 'Try a gesture...';
  String _gestureDescription = 'Practice gestures in the area below';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleGesture(String gesture, String description) {
    setState(() {
      _lastGesture = gesture;
      _gestureDescription = description;
    });
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    HapticFeedback.lightImpact();
    
    // Announce gesture for screen readers
    if (Provider.of<AccessibilityService>(context, listen: false).screenReaderEnabled) {
      SemanticsService.announce(
        'Gesture detected: $gesture - $description',
        TextDirection.ltr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gesture Practice Area',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Training area
          GestureDetector(
            onTap: () => _handleGesture('Single Tap', 'Basic tap gesture detected'),
            onDoubleTap: () => _handleGesture('Double Tap', 'Double tap - activate action'),
            onLongPress: () => _handleGesture('Long Press', 'Long press - context menu'),
            onPanUpdate: (details) {
              final delta = details.delta;
              if (delta.dx.abs() > delta.dy.abs()) {
                if (delta.dx > 0) {
                  _handleGesture('Swipe Right', 'Swipe right - navigate forward');
                } else {
                  _handleGesture('Swipe Left', 'Swipe left - navigate back');
                }
              } else {
                if (delta.dy > 0) {
                  _handleGesture('Swipe Down', 'Swipe down - scroll down');
                } else {
                  _handleGesture('Swipe Up', 'Swipe up - scroll up');
                }
              }
            },
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastGesture,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _gestureDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Tip: Try different gestures in the area above to see how they work!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class GestureNavigationDemoScreen extends StatefulWidget {
  const GestureNavigationDemoScreen({Key? key}) : super(key: key);

  @override
  State<GestureNavigationDemoScreen> createState() => _GestureNavigationDemoScreenState();
}

class _GestureNavigationDemoScreenState extends State<GestureNavigationDemoScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _statusMessage = 'Try gestures to navigate!';

  final List<String> _pages = [
    'Page 1: Welcome to Gesture Navigation',
    'Page 2: Practice your swipe gestures',
    'Page 3: Try double-tap to activate',
    'Page 4: Long press for options',
    'Page 5: Two-finger tap for settings',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _currentPage++;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateStatus('Navigated to next page');
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateStatus('Navigated to previous page');
    }
  }

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
    
    // Clear status after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Try gestures to navigate!';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, service, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gesture Navigation Demo'),
            leading: AccessibleIconButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Back to accessibility settings',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (!service.gestureNavigationEnabled) return;
              
              if (details.velocity.pixelsPerSecond.dx > 300) {
                _previousPage();
              } else if (details.velocity.pixelsPerSecond.dx < -300) {
                _nextPage();
              }
            },
            onDoubleTap: () {
              if (!service.gestureNavigationEnabled) return;
              _updateStatus('Double tap detected - Activating current page!');
              HapticFeedback.mediumImpact();
            },
            onLongPress: () {
              if (!service.gestureNavigationEnabled) return;
              _showContextMenu(context);
            },
            child: Column(
              children: [
                // Status bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(
                    children: [
                      Text(
                        service.gestureNavigationEnabled 
                          ? 'Gesture Navigation: ON'
                          : 'Gesture Navigation: OFF',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      return Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        ),
                      );
                    }),
                  ),
                ),
                
                // Main content area
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: AccessibleCard(
                          semanticLabel: _pages[index],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gesture,
                                size: 80,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _pages[index],
                                style: Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getPageInstructions(index),
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (service.gestureNavigationEnabled)
                                _buildGestureInstructions(context, index),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Navigation buttons (fallback)
                if (!service.gestureNavigationEnabled)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AccessibleElevatedButton(
                          text: 'Previous',
                          semanticLabel: 'Go to previous page',
                          onPressed: _currentPage > 0 ? _previousPage : null,
                        ),
                        AccessibleElevatedButton(
                          text: 'Next',
                          semanticLabel: 'Go to next page',
                          onPressed: _currentPage < _pages.length - 1 ? _nextPage : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPageInstructions(int index) {
    switch (index) {
      case 0:
        return 'Welcome! This demo shows how gesture navigation works. Swipe left or right to navigate between pages.';
      case 1:
        return 'Try swiping left or right to move between pages. This is the most basic navigation gesture.';
      case 2:
        return 'Double-tap anywhere on the screen to activate or select items. Try it now!';
      case 3:
        return 'Long press (press and hold) to bring up context menus or additional options.';
      case 4:
        return 'Congratulations! You\'ve learned the basic gesture navigation. Use two-finger tap for quick settings access.';
      default:
        return '';
    }
  }

  Widget _buildGestureInstructions(BuildContext context, int index) {
    List<String> instructions = [];
    
    switch (index) {
      case 0:
        instructions = ['→ Swipe left to go forward', '← Swipe right to go back'];
        break;
      case 1:
        instructions = ['→ Try swiping left now', '← Or swipe right to go back'];
        break;
      case 2:
        instructions = ['⚡ Double-tap this card'];
        break;
      case 3:
        instructions = ['👆 Long press this card'];
        break;
      case 4:
        instructions = ['👆👆 Two-finger tap for settings'];
        break;
    }
    
    return Column(
      children: instructions.map((instruction) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            instruction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showContextMenu(BuildContext context) {
    _updateStatus('Long press detected - Opening context menu!');
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Context Menu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Go to Home'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GestureShortcut {
  final String gesture;
  final String action;
  final IconData icon;
  final String description;

  const GestureShortcut({
    required this.gesture,
    required this.action,
    required this.icon,
    required this.description,
  });
}