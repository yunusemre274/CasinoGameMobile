import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/animated_button.dart';
import '../../shared/widgets/game_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  int? _lastReward;
  int? _lastHappinessGain;
  int _donationAmount = 100;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _visitHome() {
    HapticFeedback.mediumImpact();
    final gameNotifier = ref.read(gameProvider.notifier);
    final stateBefore = ref.read(gameProvider);
    final reward = gameNotifier.visitHome();
    final stateAfter = ref.read(gameProvider);

    final happinessGain =
        stateAfter.familyHappiness - stateBefore.familyHappiness;

    setState(() {
      _lastReward = reward;
      _lastHappinessGain = happinessGain;
    });

    _showResultSnackbar(
      '🏠 Welcome Home! +\$$reward and +$happinessGain happiness!',
      AppColors.success,
    );
  }

  void _giveMoney() {
    HapticFeedback.mediumImpact();
    final gameNotifier = ref.read(gameProvider.notifier);
    final stateBefore = ref.read(gameProvider);

    if (stateBefore.money < _donationAmount) {
      _showResultSnackbar(
        '❌ Not enough money! You need \$$_donationAmount',
        AppColors.danger,
      );
      return;
    }

    final success = gameNotifier.leaveMoneyForFamily(_donationAmount);

    if (success) {
      final stateAfter = ref.read(gameProvider);
      final happinessGain =
          stateAfter.familyHappiness - stateBefore.familyHappiness;

      setState(() {
        _lastHappinessGain = happinessGain;
      });

      _showResultSnackbar(
        '💝 Family appreciates you! +$happinessGain happiness',
        AppColors.happiness,
      );
    }
  }

  void _showResultSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🏠 Home'),
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
            // Family Status Card
            _buildFamilyStatusCard(gameState),
            const SizedBox(height: 16),

            // Visit Home Card
            _buildVisitHomeCard(gameState),
            const SizedBox(height: 16),

            // Leave Money Card
            _buildLeaveMoneyCard(gameState),
            const SizedBox(height: 16),

            // Stats Card
            _buildStatsCard(gameState),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyStatusCard(gameState) {
    final happinessPercent =
        gameState.familyHappiness / gameState.maxFamilyHappiness;
    final isFamilyBroken = gameState.familyBroken;

    return GameCard(
      child: Column(
        children: [
          // Animated heart
          ScaleTransition(
            scale: _heartAnimation,
            child: Icon(
              isFamilyBroken ? Icons.heart_broken : Icons.favorite,
              size: 64,
              color: isFamilyBroken ? AppColors.danger : AppColors.happiness,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            isFamilyBroken ? 'Family is Unhappy 😢' : 'Family Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isFamilyBroken ? AppColors.danger : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Happiness bar
          Row(
            children: [
              const Text('❤️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: happinessPercent,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getHappinessColor(happinessPercent),
                    ),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${gameState.familyHappiness}/${gameState.maxFamilyHappiness}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isFamilyBroken)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Max HP reduced to ${gameState.effectiveMaxHp}! '
                      'Increase happiness to restore it.',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getHappinessColor(double percent) {
    if (percent > 0.6) return AppColors.happiness;
    if (percent > 0.3) return AppColors.warning;
    return AppColors.danger;
  }

  Widget _buildVisitHomeCard(gameState) {
    final reward = gameState.homeVisitReward;

    return GameCard(
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
                child: const Text('🏠', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spend Time with Family',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Earn \$$reward and restore happiness',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          AnimatedButton(
            onPressed: _visitHome,
            backgroundColor: AppColors.money,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Visit Family (+\$$reward)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          if (_lastReward != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last visit: +\$$_lastReward, +$_lastHappinessGain ❤️',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaveMoneyCard(gameState) {
    final suggested = ref.read(gameProvider.notifier).getSuggestedDonation();
    final canAfford = gameState.money >= _donationAmount;

    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.happiness.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('💝', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Money for Family',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Every \$100 = +5 happiness',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount selector
          Row(
            children: [
              const Text(
                'Amount:',
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
                  children: [100, 500, 1000, suggested].map((amount) {
                    final isSelected = _donationAmount == amount;
                    final isSuggested =
                        amount == suggested &&
                        amount != 100 &&
                        amount != 500 &&
                        amount != 1000;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _donationAmount = amount);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.happiness
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: isSuggested && !isSelected
                              ? Border.all(
                                  color: AppColors.happiness.withValues(
                                    alpha: 0.5,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(
                          isSuggested ? '\$$amount ⭐' : '\$$amount',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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

          AnimatedButton(
            onPressed: canAfford ? _giveMoney : null,
            backgroundColor: canAfford
                ? AppColors.happiness
                : AppColors.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  color: canAfford ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'Give \$$_donationAmount to Family',
                  style: TextStyle(
                    color: canAfford ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          if (!canAfford) ...[
            const SizedBox(height: 8),
            Text(
              'You need \$$_donationAmount (have \$${gameState.money})',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(gameState) {
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '📊 Family Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Total Home Visits',
            '${gameState.homeVisitCount}',
            Icons.home,
          ),
          _buildStatRow(
            'Money Given to Family',
            '\$${gameState.totalMoneyGivenToFamily}',
            Icons.attach_money,
          ),
          _buildStatRow(
            'Visit Reward (Lvl ${gameState.level})',
            '\$${gameState.homeVisitReward}',
            Icons.card_giftcard,
          ),
          _buildStatRow(
            'Current Max HP',
            '${gameState.effectiveMaxHp}',
            Icons.favorite,
            valueColor: gameState.familyBroken ? AppColors.danger : null,
          ),
        ],
      ),
    );
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
              style: const TextStyle(color: AppColors.textSecondary),
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
