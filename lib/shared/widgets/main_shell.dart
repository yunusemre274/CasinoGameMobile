import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/mafia_event_service.dart';
import 'hud_widget.dart';
import 'mafia_event_dialog.dart';

// Main Shell - Contains HUD and bottom navigation
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _checkedOnStart = false;

  @override
  void initState() {
    super.initState();
    // Check for mafia event on app start (delayed to ensure context is ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMafiaEventOnStart();
    });
  }

  Future<void> _checkMafiaEventOnStart() async {
    if (_checkedOnStart) return;
    _checkedOnStart = true;

    // Small delay to ensure everything is initialized
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      _tryTriggerMafiaEvent();
    }
  }

  void _tryTriggerMafiaEvent() {
    final mafiaNotifier = ref.read(mafiaEventProvider.notifier);
    if (mafiaNotifier.checkAndTrigger()) {
      _showMafiaDialog();
    }
  }

  Future<void> _showMafiaDialog() async {
    if (!mounted) return;
    await MafiaEventDialog.show(context, ref);
  }

  void _onTabTap(String route) {
    // Navigate first
    context.go(route);

    // Then check for mafia event (with small delay for smoother UX)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _tryTriggerMafiaEvent();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Global HUD at top
          const HudWidget(),
          // Main content
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(onTabTap: _onTabTap),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final void Function(String route) onTabTap;

  const _BottomNavBar({required this.onTabTap});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/casino')) {
      currentIndex = 0;
    } else if (location.startsWith('/inventory')) {
      currentIndex = 1;
    } else if (location.startsWith('/market')) {
      currentIndex = 2;
    } else if (location.startsWith('/buildings')) {
      currentIndex = 3;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.casino,
                label: 'Casino',
                isSelected: currentIndex == 0,
                onTap: () => onTabTap('/casino'),
              ),
              _NavItem(
                icon: Icons.inventory_2,
                label: 'Inventory',
                isSelected: currentIndex == 1,
                onTap: () => onTabTap('/inventory'),
              ),
              _NavItem(
                icon: Icons.store,
                label: 'Market',
                isSelected: currentIndex == 2,
                onTap: () => onTabTap('/market'),
              ),
              _NavItem(
                icon: Icons.apartment,
                label: 'Buildings',
                isSelected: currentIndex == 3,
                onTap: () => onTabTap('/buildings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppColors.accent : AppColors.textMuted;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
