import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/animated_button.dart';

// Casino Page - Main casino tab with game selection
class CasinoPage extends StatelessWidget {
  const CasinoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🎰 Casino',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Row(
                  children: [
                    // Dev simulation button (for testing)
                    AnimatedIconButton(
                      icon: Icons.science,
                      onPressed: () => context.push('/dev-simulation'),
                      backgroundColor: AppColors.info.withValues(alpha: 0.2),
                      iconColor: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    AnimatedIconButton(
                      icon: Icons.work,
                      onPressed: () => context.push('/street-jobs'),
                      backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                      iconColor: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    AnimatedIconButton(
                      icon: Icons.person,
                      onPressed: () => context.push('/stats'),
                      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                      iconColor: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Casino Games Grid
            Text(
              'Choose a Game',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppConstants.defaultPadding,
              crossAxisSpacing: AppConstants.defaultPadding,
              childAspectRatio: 1.1,
              children: [
                _CasinoGameCard(
                  icon: '🎡',
                  title: 'Roulette',
                  subtitle: 'Spin the wheel',
                  color: AppColors.danger,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/roulette');
                  },
                ),
                _CasinoGameCard(
                  icon: '🃏',
                  title: 'Blackjack',
                  subtitle: 'Beat the dealer',
                  color: AppColors.success,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/blackjack');
                  },
                ),
                _CasinoGameCard(
                  icon: '🏇',
                  title: 'Horse Race',
                  subtitle: 'Pick a winner',
                  color: AppColors.warning,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/horse-race');
                  },
                ),
                _CasinoGameCard(
                  icon: '🪙',
                  title: 'Tail-Head',
                  subtitle: 'Flip the coin',
                  color: AppColors.info,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/coin-flip');
                  },
                ),
                _CasinoGameCard(
                  icon: '🎰',
                  title: 'Slot 777',
                  subtitle: 'Try your luck',
                  color: AppColors.level,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/slot-machine');
                  },
                ),
                _CasinoGameCard(
                  icon: '✈️',
                  title: 'Aviator',
                  subtitle: 'Cash out in time',
                  color: AppColors.happiness,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/aviator');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CasinoGameCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CasinoGameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CasinoGameCard> createState() => _CasinoGameCardState();
}

class _CasinoGameCardState extends State<_CasinoGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with glow
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.icon,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
