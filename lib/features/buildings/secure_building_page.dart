import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/animated_button.dart';
import '../../shared/widgets/game_card.dart';

class SecureBuildingPage extends ConsumerWidget {
  const SecureBuildingPage({super.key});

  void _hireBodyguard(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    final gameState = ref.read(gameProvider);

    // Check max bodyguards
    if (gameState.bodyguards >= 10) {
      _showMessage(
        context,
        '🛡️ Maximum Reached!',
        'You already have 10 bodyguards.',
        AppColors.warning,
      );
      return;
    }

    // Check money
    if (gameState.money < 5000) {
      _showMessage(
        context,
        '💸 Not Enough Money!',
        'You need \$5,000 to hire a bodyguard.',
        AppColors.danger,
      );
      return;
    }

    // Hire bodyguard
    final success = ref.read(gameProvider.notifier).addBodyguard();

    if (success) {
      final newState = ref.read(gameProvider);
      _showMessage(
        context,
        '🛡️ Bodyguard Hired!',
        'You now have ${newState.bodyguards}/10 bodyguards.',
        AppColors.success,
      );
    }
  }

  void _showMessage(
    BuildContext context,
    String title,
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final canHire = gameState.money >= 5000 && gameState.bodyguards < 10;
    final damageReduction = gameState.bodyguards * 5;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🛡️ Secure Building'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            GameCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🛡️', style: TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Secure Building',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hire professional bodyguards for protection',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bodyguards Status Card
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: AppColors.info),
                          const SizedBox(width: 8),
                          Text(
                            'Your Bodyguards',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${gameState.bodyguards}/10',
                          style: TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bodyguard slots visualization
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(10, (index) {
                      final isActive = index < gameState.bodyguards;
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.info.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? AppColors.info : AppColors.border,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: isActive
                              ? Text('🕴️', style: TextStyle(fontSize: 24))
                              : Icon(
                                  Icons.person_outline,
                                  color: AppColors.textMuted,
                                  size: 24,
                                ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Protection info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Damage Reduction',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                damageReduction > 0
                                    ? '-$damageReduction damage from attacks'
                                    : 'Hire bodyguards for protection',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hire Card
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.money.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_add,
                          color: AppColors.money,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hire Bodyguard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Each reduces incoming damage by 5',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cost display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cost per Bodyguard',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          '\$5,000',
                          style: TextStyle(
                            color: gameState.money >= 5000
                                ? AppColors.money
                                : AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Balance',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '\$${gameState.money}',
                        style: TextStyle(
                          color: AppColors.money,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AnimatedButton(
                    onPressed: canHire
                        ? () => _hireBodyguard(context, ref)
                        : null,
                    backgroundColor: canHire
                        ? AppColors.info
                        : AppColors.surfaceLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add,
                          color: canHire ? Colors.white : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          gameState.bodyguards >= 10
                              ? 'Maximum Reached'
                              : gameState.money < 5000
                              ? 'Not Enough Money'
                              : 'Hire Bodyguard (\$5,000)',
                          style: TextStyle(
                            color: canHire ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Card
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 How Bodyguards Work',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.shield,
                    'Each bodyguard reduces damage by 5',
                  ),
                  _buildInfoRow(Icons.group, 'Maximum of 10 bodyguards'),
                  _buildInfoRow(
                    Icons.warning_amber,
                    'Bodyguards don\'t die in fights',
                  ),
                  _buildInfoRow(
                    Icons.attach_money,
                    'One-time cost of \$5,000 each',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
