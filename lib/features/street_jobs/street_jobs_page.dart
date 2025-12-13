import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/game_state.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/game_card.dart';
import '../../shared/widgets/animated_button.dart';

// Street Jobs Page - Mini-games to earn money
class StreetJobsPage extends ConsumerWidget {
  const StreetJobsPage({super.key});

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
        title: const Text('Street Jobs'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            GameCard(
              backgroundColor: AppColors.warning.withOpacity(0.1),
              child: Row(
                children: [
                  const Text('💼', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earn money legally',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.warning),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete jobs to earn cash without gambling',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Jobs list
            _JobCard(
              icon: '🧮',
              name: 'Math Quiz',
              description: '5 questions, \$10 per correct answer',
              reward: 50,
              color: AppColors.info,
              attemptsLeft: gameState.mathQuizAttemptsLeft,
              maxAttempts: GameState.maxJobAttempts,
              canPlay: gameState.canPlayMathQuiz,
              onStart: () {
                HapticFeedback.mediumImpact();
                context.push('/math-quiz');
              },
            ),
            _JobCard(
              icon: '🔍',
              name: 'Match Samples',
              description: 'Find matching pairs',
              reward: 50,
              color: AppColors.success,
              attemptsLeft: gameState.matchSamplesAttemptsLeft,
              maxAttempts: GameState.maxJobAttempts,
              canPlay: gameState.canPlayMatchSamples,
              onStart: () {
                HapticFeedback.mediumImpact();
                context.push('/match-samples');
              },
            ),
            _JobCard(
              icon: '🔐',
              name: 'Code Breaker',
              description: 'Crack the secret code',
              reward: 30,
              color: AppColors.level,
              attemptsLeft: gameState.codeBreakerAttemptsLeft,
              maxAttempts: GameState.maxJobAttempts,
              canPlay: gameState.canPlayCodeBreaker,
              onStart: () {
                HapticFeedback.mediumImpact();
                context.push('/code-breaker');
              },
            ),
            _JobCard(
              icon: '❓',
              name: 'Guess Game',
              description: 'Guess the hidden number',
              reward: 20,
              color: AppColors.happiness,
              attemptsLeft: gameState.guessGameAttemptsLeft,
              maxAttempts: GameState.maxJobAttempts,
              canPlay: gameState.canPlayGuessGame,
              onStart: () {
                HapticFeedback.mediumImpact();
                context.push('/guess-game');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String icon;
  final String name;
  final String description;
  final int reward;
  final Color color;
  final int attemptsLeft;
  final int maxAttempts;
  final bool canPlay;
  final VoidCallback onStart;

  const _JobCard({
    required this.icon,
    required this.name,
    required this.description,
    required this.reward,
    required this.color,
    required this.attemptsLeft,
    required this.maxAttempts,
    required this.canPlay,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return GameCard(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: canPlay ? color.withOpacity(0.2) : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 28,
                  color: canPlay ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: canPlay
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: canPlay
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Reward: up to \$$reward',
                      style: TextStyle(
                        color: canPlay ? AppColors.money : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: canPlay
                            ? AppColors.info.withOpacity(0.15)
                            : AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$attemptsLeft/$maxAttempts left',
                        style: TextStyle(
                          color: canPlay ? AppColors.info : AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Start Button
          AnimatedButton(
            onPressed: canPlay ? onStart : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: canPlay ? color : AppColors.surfaceLight,
            child: Text(
              canPlay ? 'Start' : 'Done',
              style: TextStyle(
                color: canPlay ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
