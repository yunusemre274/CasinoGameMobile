import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/animated_button.dart';
import '../../shared/widgets/game_card.dart';

class GuessGamePage extends ConsumerStatefulWidget {
  const GuessGamePage({super.key});

  @override
  ConsumerState<GuessGamePage> createState() => _GuessGamePageState();
}

class _GuessGamePageState extends ConsumerState<GuessGamePage> {
  late int _secretNumber;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _guesses = [];
  bool _isWon = false;
  bool _isLost = false;
  static const int _maxAttempts = 7;
  static const int _minNumber = 1;
  static const int _maxNumber = 100;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _secretNumber = Random().nextInt(_maxNumber - _minNumber + 1) + _minNumber;
    _guesses.clear();
    _controller.clear();
    _isWon = false;
    _isLost = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitGuess() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final guess = int.tryParse(text);
    if (guess == null || guess < _minNumber || guess > _maxNumber) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a number between $_minNumber and $_maxNumber'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    String hint;
    IconData icon;
    Color color;

    if (guess == _secretNumber) {
      hint = 'Correct!';
      icon = Icons.check_circle;
      color = AppColors.success;
    } else if (guess < _secretNumber) {
      hint = 'Too low!';
      icon = Icons.arrow_upward;
      color = AppColors.info;
    } else {
      hint = 'Too high!';
      icon = Icons.arrow_downward;
      color = AppColors.warning;
    }

    setState(() {
      _guesses.add({
        'guess': guess,
        'hint': hint,
        'icon': icon,
        'color': color,
      });
      _controller.clear();

      if (guess == _secretNumber) {
        _isWon = true;
        final reward = ref.read(gameProvider.notifier).completeGuessGame();
        if (reward > 0) {
          HapticFeedback.heavyImpact();
        }
      } else if (_guesses.length >= _maxAttempts) {
        _isLost = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🎲 Guess Game'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: (_isWon || _isLost) ? _buildResultScreen() : _buildGameScreen(),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions
                GameCard(
                  child: Column(
                    children: [
                      const Text('🤔', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'I\'m thinking of a number...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Between $_minNumber and $_maxNumber',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Attempts left: ${_maxAttempts - _guesses.length}',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Previous guesses
                if (_guesses.isNotEmpty) ...[
                  Text(
                    'Your guesses:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_guesses.length, (index) {
                    final g = _guesses[_guesses.length - 1 - index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (g['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: g['color'] as Color),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            g['icon'] as IconData,
                            color: g['color'] as Color,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${g['guess']}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            g['hint'] as String,
                            style: TextStyle(
                              color: g['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter guess',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _submitGuess(),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedButton(
                onPressed: _submitGuess,
                backgroundColor: AppColors.success,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GameCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isWon ? '🎯' : '😢', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                _isWon ? 'You Got It!' : 'Game Over!',
                style: TextStyle(
                  color: _isWon ? AppColors.success : AppColors.danger,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isWon
                    ? 'Found in ${_guesses.length} guesses'
                    : 'The number was $_secretNumber',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              if (_isWon) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.money.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Reward',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+\$20',
                        style: TextStyle(
                          color: AppColors.money,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AnimatedButton(
                onPressed: () => context.pop(),
                backgroundColor: _isWon ? AppColors.success : AppColors.accent,
                child: const Text(
                  'Back to Jobs',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
