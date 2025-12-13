import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/game_provider.dart';

// HUD Widget - Global top bar showing player stats
class HudWidget extends ConsumerWidget {
  const HudWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppConstants.smallPadding,
        left: AppConstants.defaultPadding,
        right: AppConstants.defaultPadding,
        bottom: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Money and Level with XP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Money
              _StatChip(
                icon: Icons.attach_money,
                value: _formatMoney(gameState.money),
                color: AppColors.money,
              ),
              // Level with XP progress
              _LevelChip(
                level: gameState.level,
                xp: gameState.xp,
                xpToNext: gameState.xpToNextLevel,
                color: AppColors.level,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          // Bottom row: HP, Hunger, Family Happiness
          Row(
            children: [
              // HP Bar
              Expanded(
                child: _StatBar(
                  icon: Icons.favorite,
                  value: gameState.hp,
                  maxValue: gameState.effectiveMaxHp,
                  color: AppColors.health,
                  label: 'HP',
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              // Hunger Bar
              Expanded(
                child: _StatBar(
                  icon: Icons.restaurant,
                  value: gameState.hunger,
                  maxValue: gameState.maxHunger,
                  color: AppColors.hunger,
                  label: 'Hunger',
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              // Family Happiness Bar
              Expanded(
                child: _StatBar(
                  icon: Icons.home_filled,
                  value: gameState.familyHappiness,
                  maxValue: gameState.maxFamilyHappiness,
                  color: AppColors.happiness,
                  label: 'Family',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(int money) {
    if (money >= 1000000) {
      return '\$${(money / 1000000).toStringAsFixed(1)}M';
    } else if (money >= 1000) {
      return '\$${(money / 1000).toStringAsFixed(1)}K';
    }
    return '\$$money';
  }
}

// Stat Chip - Compact display for money and level
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Level Chip with XP progress bar
class _LevelChip extends StatelessWidget {
  final int level;
  final int xp;
  final int xpToNext;
  final Color color;

  const _LevelChip({
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = xpToNext > 0 ? (xp / xpToNext).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                'LVL $level',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$xp/$xpToNext XP',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Stat Bar - Enhanced progress bar display for HP, Hunger, Family
class _StatBar extends StatelessWidget {
  final IconData icon;
  final int value;
  final int maxValue;
  final Color color;
  final String label;

  const _StatBar({
    required this.icon,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.label,
  });

  // Get color based on percentage (low = danger, medium = warning, high = original)
  Color _getIndicatorColor(double percentage) {
    if (percentage <= 0.25) {
      return AppColors.danger; // Red for critical
    } else if (percentage <= 0.5) {
      return AppColors.warning; // Yellow/orange for warning
    }
    return color; // Original color when healthy
  }

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final indicatorColor = _getIndicatorColor(percentage);
    final isLow = percentage <= 0.25;
    final isMedium = percentage > 0.25 && percentage <= 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Animated icon for low stats
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: isLow ? 1.2 : 1.0),
              duration: Duration(milliseconds: isLow ? 500 : 200),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(icon, color: indicatorColor, size: 12),
                );
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$value/$maxValue',
                style: TextStyle(
                  color: indicatorColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Enhanced progress bar with glow effect
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, animatedPercentage, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animatedPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          indicatorColor,
                          indicatorColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: indicatorColor.withValues(alpha: 0.5),
                          blurRadius: isLow ? 6 : 4,
                          spreadRadius: isLow ? 1 : 0,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Warning text for low/medium stats
        if (isLow || isMedium) ...[
          const SizedBox(height: 2),
          Text(
            isLow ? '⚠️ Critical!' : 'Low',
            style: TextStyle(
              color: indicatorColor,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
