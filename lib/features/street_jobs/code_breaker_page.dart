import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/animated_button.dart';
import '../../shared/widgets/game_card.dart';

class CodeBreakerPage extends ConsumerStatefulWidget {
  const CodeBreakerPage({super.key});

  @override
  ConsumerState<CodeBreakerPage> createState() => _CodeBreakerPageState();
}

class _CodeBreakerPageState extends ConsumerState<CodeBreakerPage> {
  late List<int> _secretCode;
  final List<List<int>> _guesses = [];
  final List<String> _feedback = [];
  List<int> _currentGuess = [];
  bool _isWon = false;
  bool _isLost = false;
  static const int _maxAttempts = 6;
  static const int _codeLength = 4;
  static const int _maxDigit = 6; // 1-6

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final random = Random();
    _secretCode = List.generate(
      _codeLength,
      (_) => random.nextInt(_maxDigit) + 1,
    );
    _guesses.clear();
    _feedback.clear();
    _currentGuess = [];
    _isWon = false;
    _isLost = false;
  }

  void _addDigit(int digit) {
    if (_currentGuess.length >= _codeLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentGuess.add(digit);
    });
  }

  void _removeDigit() {
    if (_currentGuess.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentGuess.removeLast();
    });
  }

  void _submitGuess() {
    if (_currentGuess.length != _codeLength) return;
    HapticFeedback.mediumImpact();

    // Calculate feedback
    int correctPosition = 0;
    int correctDigit = 0;
    final secretCopy = List<int>.from(_secretCode);
    final guessCopy = List<int>.from(_currentGuess);

    // First pass: exact matches
    for (int i = 0; i < _codeLength; i++) {
      if (guessCopy[i] == secretCopy[i]) {
        correctPosition++;
        secretCopy[i] = -1;
        guessCopy[i] = -2;
      }
    }

    // Second pass: correct digits in wrong position
    for (int i = 0; i < _codeLength; i++) {
      if (guessCopy[i] != -2) {
        final index = secretCopy.indexOf(guessCopy[i]);
        if (index != -1) {
          correctDigit++;
          secretCopy[index] = -1;
        }
      }
    }

    setState(() {
      _guesses.add(List.from(_currentGuess));
      _feedback.add('🟢$correctPosition 🟡$correctDigit');
      _currentGuess = [];

      if (correctPosition == _codeLength) {
        _isWon = true;
        final reward = ref.read(gameProvider.notifier).completeCodeBreaker();
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
        title: const Text('🔐 Code Breaker'),
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
        // Instructions
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Crack the 4-digit code (1-6). 🟢=Right place, 🟡=Wrong place',
                  style: TextStyle(color: AppColors.info, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Attempts left
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Attempts: ${_guesses.length}/$_maxAttempts',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Previous guesses
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _guesses.length + 1,
            itemBuilder: (context, index) {
              if (index == _guesses.length) {
                // Current guess row
                return _buildGuessRow(_currentGuess, null, isCurrent: true);
              }
              return _buildGuessRow(_guesses[index], _feedback[index]);
            },
          ),
        ),

        // Digit buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _maxDigit,
                  (i) => _buildDigitButton(i + 1),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      onPressed: _removeDigit,
                      backgroundColor: AppColors.danger,
                      child: const Icon(Icons.backspace, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AnimatedButton(
                      onPressed: _currentGuess.length == _codeLength
                          ? _submitGuess
                          : null,
                      backgroundColor: _currentGuess.length == _codeLength
                          ? AppColors.success
                          : AppColors.surfaceLight,
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: _currentGuess.length == _codeLength
                              ? Colors.white
                              : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuessRow(
    List<int> guess,
    String? feedback, {
    bool isCurrent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent ? Border.all(color: AppColors.info, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_codeLength, (i) {
              final hasDigit = i < guess.length;
              return Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: hasDigit
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasDigit ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    hasDigit ? '${guess[i]}' : '',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (feedback != null)
            Text(feedback, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDigitButton(int digit) {
    return GestureDetector(
      onTap: () => _addDigit(digit),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            '$digit',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
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
              Text(_isWon ? '🎉' : '💔', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                _isWon ? 'Code Cracked!' : 'Failed!',
                style: TextStyle(
                  color: _isWon ? AppColors.success : AppColors.danger,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (!_isWon)
                Text(
                  'The code was: ${_secretCode.join('')}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              if (_isWon) ...[
                Text(
                  'Solved in ${_guesses.length} attempts',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
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
                        '+\$30',
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
