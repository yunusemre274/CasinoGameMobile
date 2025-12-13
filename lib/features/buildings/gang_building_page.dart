import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/animated_button.dart';
import '../../shared/widgets/game_card.dart';

class GangBuildingPage extends ConsumerStatefulWidget {
  const GangBuildingPage({super.key});

  @override
  ConsumerState<GangBuildingPage> createState() => _GangBuildingPageState();
}

class _GangBuildingPageState extends ConsumerState<GangBuildingPage> {
  int _recruitCount = 1;

  void _recruitGangMembers() {
    HapticFeedback.mediumImpact();
    final gameState = ref.read(gameProvider);
    final cost = _recruitCount * 2000;

    // Check money
    if (gameState.money < cost) {
      _showMessage(
        '💸 Not Enough Money!',
        'You need \$$cost to recruit $_recruitCount member(s).',
        AppColors.danger,
      );
      return;
    }

    // Recruit gang members
    ref.read(gameProvider.notifier).recruitGangMembers(_recruitCount, cost);

    final newState = ref.read(gameProvider);
    _showMessage(
      '👥 Members Recruited!',
      'You now have ${newState.gangMates} gang members.',
      AppColors.success,
    );
  }

  void _showMessage(String title, String message, Color color) {
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
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final cost = _recruitCount * 2000;
    final canRecruit = gameState.money >= cost;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('👥 Gang Building'),
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
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('👥', style: TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gang Headquarters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Build your crew for ultimate protection',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Gang Status Card
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.groups, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Your Gang',
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
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text('🤵', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '${gameState.gangMates}',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gang member visualization (show up to 20, then just count)
                  if (gameState.gangMates > 0) ...[
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(
                        gameState.gangMates > 20 ? 20 : gameState.gangMates,
                        (index) => Text('🤵', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    if (gameState.gangMates > 20) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+${gameState.gangMates - 20} more members',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No gang members yet',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Protection info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gameState.gangMates > 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: gameState.gangMates > 0
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          gameState.gangMates > 0
                              ? Icons.verified_user
                              : Icons.warning_amber,
                          color: gameState.gangMates > 0
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gameState.gangMates > 0
                                    ? 'Full Protection Active'
                                    : 'No Protection',
                                style: TextStyle(
                                  color: gameState.gangMates > 0
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                gameState.gangMates > 0
                                    ? 'Gang absorbs all damage from attacks'
                                    : 'Recruit members to absorb damage',
                                style: TextStyle(
                                  color: gameState.gangMates > 0
                                      ? AppColors.success
                                      : AppColors.warning,
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

            // Recruit Card
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_add_alt_1,
                          color: AppColors.warning,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recruit Members',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$2,000 per member',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Recruit count selector
                  Row(
                    children: [
                      Text(
                        'Recruit:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [1, 5, 10, 20].map((count) {
                            final isSelected = _recruitCount == count;
                            final countCost = count * 2000;
                            final canAffordThis = gameState.money >= countCost;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _recruitCount = count);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.warning
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: !canAffordThis && !isSelected
                                      ? Border.all(
                                          color: AppColors.danger.withValues(
                                            alpha: 0.3,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : canAffordThis
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                          'Total Cost ($_recruitCount members)',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          '\$$cost',
                          style: TextStyle(
                            color: canRecruit
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
                    onPressed: canRecruit ? _recruitGangMembers : null,
                    backgroundColor: canRecruit
                        ? AppColors.warning
                        : AppColors.surfaceLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_add,
                          color: canRecruit
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          canRecruit
                              ? 'Recruit $_recruitCount Member${_recruitCount > 1 ? 's' : ''}'
                              : 'Not Enough Money',
                          style: TextStyle(
                            color: canRecruit
                                ? Colors.white
                                : AppColors.textMuted,
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
                    '📋 How Gang Protection Works',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.shield, 'Gang members absorb ALL damage'),
                  _buildInfoRow(
                    Icons.warning_amber,
                    '1-5 members may die per attack',
                  ),
                  _buildInfoRow(
                    Icons.all_inclusive,
                    'No maximum limit on members',
                  ),
                  _buildInfoRow(
                    Icons.priority_high,
                    'Gang protection > Bodyguard protection',
                  ),
                ],
              ),
            ),

            // Warning note
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.dangerous, color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gang members will die protecting you from mafia attacks!',
                      style: TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
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
          Icon(icon, size: 18, color: AppColors.warning),
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
