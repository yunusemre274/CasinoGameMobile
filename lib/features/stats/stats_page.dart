import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/game_card.dart';
import '../../shared/widgets/animated_button.dart';

// Stats Page - Character statistics overview
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: AnimatedIconButton(
          icon: Icons.arrow_back,
          onPressed: () => context.pop(),
          backgroundColor: Colors.transparent,
          iconColor: AppColors.textPrimary,
        ),
        title: const Text('Character Stats'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Character avatar card
            GameCard(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 3),
                    ),
                    child: const Center(
                      child: Text('🎭', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Level ${gameState.level}',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: AppColors.level),
                  ),
                  const SizedBox(height: 4),
                  // XP Progress bar
                  SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.level.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: gameState.xpProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.level,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${gameState.xp}/${gameState.xpToNextLevel} XP',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.level),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Casino Mafia Player',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppConstants.defaultPadding,
              crossAxisSpacing: AppConstants.defaultPadding,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  icon: Icons.favorite,
                  label: 'HP',
                  value: '${gameState.hp}/${gameState.effectiveMaxHp}',
                  color: AppColors.health,
                ),
                _StatCard(
                  icon: Icons.restaurant,
                  label: 'Hunger',
                  value: '${gameState.hunger}/${gameState.maxHunger}',
                  color: AppColors.hunger,
                ),
                _StatCard(
                  icon: Icons.home_filled,
                  label: 'Family',
                  value:
                      '${gameState.familyHappiness}/${gameState.maxFamilyHappiness}',
                  color: AppColors.happiness,
                  warning: gameState.familyBroken,
                ),
                _StatCard(
                  icon: Icons.attach_money,
                  label: 'Money',
                  value: '\$${gameState.money}',
                  color: AppColors.money,
                ),
                _StatCard(
                  icon: Icons.shield,
                  label: 'Bodyguards',
                  value: '${gameState.bodyguards}/10',
                  color: AppColors.info,
                ),
                _StatCard(
                  icon: Icons.groups,
                  label: 'Gang Mates',
                  value: '${gameState.gangMates}',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Warning if family is broken
            if (gameState.familyBroken)
              GameCard(
                backgroundColor: AppColors.danger.withOpacity(0.2),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.danger, size: 32),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Broken',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.danger),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Max HP capped at 75. Visit Home to restore family happiness.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Mafia warning if money > 10k
            if (gameState.isMafiaActive)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppConstants.defaultPadding,
                ),
                child: GameCard(
                  backgroundColor: AppColors.warning.withOpacity(0.2),
                  child: Row(
                    children: [
                      const Text('🔫', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: AppConstants.defaultPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mafia Active!',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppColors.warning),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You have over \$10,000. The mafia may visit you anytime.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool warning;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return GameCard(
      margin: EdgeInsets.zero,
      backgroundColor: warning
          ? AppColors.danger.withOpacity(0.1)
          : color.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: warning ? AppColors.danger : color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: warning ? AppColors.danger : color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
