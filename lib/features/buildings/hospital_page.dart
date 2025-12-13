import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/animated_button.dart';
import '../../shared/widgets/game_card.dart';

class HospitalPage extends ConsumerStatefulWidget {
  const HospitalPage({super.key});

  @override
  ConsumerState<HospitalPage> createState() => _HospitalPageState();
}

class _HospitalPageState extends ConsumerState<HospitalPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _healPatient() {
    HapticFeedback.mediumImpact();
    final gameState = ref.read(gameProvider);

    // Check if already at full HP
    if (gameState.hp >= gameState.effectiveMaxHp) {
      _showMessage(
        '💚 You\'re already healthy!',
        'No treatment needed.',
        AppColors.success,
      );
      return;
    }

    // Check if enough money
    if (gameState.money < gameState.hospitalCost) {
      _showMessage(
        '💸 Not enough money!',
        'You need \$${gameState.hospitalCost} for treatment.',
        AppColors.danger,
      );
      return;
    }

    // Heal the player
    final success = ref.read(gameProvider.notifier).healToFull();

    if (success) {
      final newState = ref.read(gameProvider);
      _showMessage(
        '🏥 Fully Healed!',
        'HP restored to ${newState.effectiveMaxHp}. Next visit: \$${newState.hospitalCost}',
        AppColors.success,
      );
    }
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
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final isFullHp = gameState.hp >= gameState.effectiveMaxHp;
    final canAfford = gameState.money >= gameState.hospitalCost;
    final hpPercent = gameState.hp / gameState.effectiveMaxHp;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🏥 Hospital'),
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
            // Hospital Icon Card
            GameCard(
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.health.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🏥', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'City Hospital',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional medical care for the underground',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // HP Status Card
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isFullHp ? Icons.favorite : Icons.healing,
                            color: isFullHp
                                ? AppColors.success
                                : AppColors.health,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Health',
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
                          color: isFullHp
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.health.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${gameState.hp}/${gameState.effectiveMaxHp}',
                          style: TextStyle(
                            color: isFullHp
                                ? AppColors.success
                                : AppColors.health,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: hpPercent,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getHpColor(hpPercent),
                      ),
                      minHeight: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isFullHp)
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
                          Icon(Icons.check_circle, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You\'re in perfect health! No treatment needed.',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You need ${gameState.effectiveMaxHp - gameState.hp} HP to be fully healed.',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Treatment Card
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.health.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medical_services,
                          color: AppColors.health,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Treatment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Restore HP to maximum',
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
                          'Treatment Cost',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          '\$${gameState.hospitalCost}',
                          style: TextStyle(
                            color: canAfford
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
                    onPressed: (canAfford && !isFullHp) ? _healPatient : null,
                    backgroundColor: (canAfford && !isFullHp)
                        ? AppColors.health
                        : AppColors.surfaceLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.healing,
                          color: (canAfford && !isFullHp)
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFullHp
                              ? 'Already Healthy'
                              : canAfford
                              ? 'Get Treatment'
                              : 'Not Enough Money',
                          style: TextStyle(
                            color: (canAfford && !isFullHp)
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

            // Statistics Card
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Hospital Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Total Visits',
                    '${gameState.hospitalUseCount}',
                    Icons.local_hospital,
                  ),
                  _buildStatRow(
                    'Current Cost',
                    '\$${gameState.hospitalCost}',
                    Icons.attach_money,
                  ),
                  _buildStatRow(
                    'Next Visit Cost',
                    '\$${gameState.hospitalCost + 1000}',
                    Icons.trending_up,
                    valueColor: AppColors.warning,
                  ),
                ],
              ),
            ),

            // Info note
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hospital costs increase by \$1,000 after each visit. Stay safe!',
                      style: TextStyle(color: AppColors.info, fontSize: 13),
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

  Color _getHpColor(double percent) {
    if (percent > 0.6) return AppColors.success;
    if (percent > 0.3) return AppColors.warning;
    return AppColors.danger;
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
