import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/animated_button.dart';
import '../../shared/widgets/game_card.dart';

class MathQuizPage extends ConsumerStatefulWidget {
  const MathQuizPage({super.key});

  @override
  ConsumerState<MathQuizPage> createState() => _MathQuizPageState();
}

class _MathQuizPageState extends ConsumerState<MathQuizPage> {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();

  int _currentQuestion = 0;
  int _correctAnswers = 0;
  int _num1 = 0;
  int _num2 = 0;
  String _operator = '+';
  int _correctAnswer = 0;
  bool _isFinished = false;
  bool? _lastAnswerCorrect;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    _num1 = _random.nextInt(20) + 1;
    _num2 = _random.nextInt(20) + 1;

    final operators = ['+', '-', '×'];
    _operator = operators[_random.nextInt(operators.length)];

    switch (_operator) {
      case '+':
        _correctAnswer = _num1 + _num2;
        break;
      case '-':
        // Ensure positive result
        if (_num2 > _num1) {
          final temp = _num1;
          _num1 = _num2;
          _num2 = temp;
        }
        _correctAnswer = _num1 - _num2;
        break;
      case '×':
        _num1 = _random.nextInt(10) + 1;
        _num2 = _random.nextInt(10) + 1;
        _correctAnswer = _num1 * _num2;
        break;
    }

    _answerController.clear();
    _lastAnswerCorrect = null;
  }

  void _submitAnswer() {
    final userAnswer = int.tryParse(_answerController.text.trim());
    if (userAnswer == null) return;

    HapticFeedback.mediumImpact();

    final isCorrect = userAnswer == _correctAnswer;
    if (isCorrect) {
      _correctAnswers++;
    }

    setState(() {
      _lastAnswerCorrect = isCorrect;
      _currentQuestion++;
    });

    if (_currentQuestion >= 5) {
      // Quiz finished
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isFinished = true);
          final reward = ref
              .read(gameProvider.notifier)
              .completeMathQuiz(_correctAnswers);
          if (reward > 0) {
            HapticFeedback.heavyImpact();
          }
        }
      });
    } else {
      // Next question after brief delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _generateQuestion());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🧮 Math Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isFinished ? _buildResultScreen() : _buildQuizScreen(),
    );
  }

  Widget _buildQuizScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress
          GameCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestion + 1}/5',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.money.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_correctAnswers correct',
                        style: TextStyle(
                          color: AppColors.money,
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
                    value: (_currentQuestion + 1) / 5,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Question
          GameCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  'Solve:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_num1 $_operator $_num2 = ?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Answer input
                TextField(
                  controller: _answerController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your answer',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (_) => _submitAnswer(),
                ),
                const SizedBox(height: 16),

                // Feedback
                if (_lastAnswerCorrect != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _lastAnswerCorrect!
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _lastAnswerCorrect!
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _lastAnswerCorrect!
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _lastAnswerCorrect! ? 'Correct! +\$10' : 'Wrong!',
                          style: TextStyle(
                            color: _lastAnswerCorrect!
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          AnimatedButton(
            onPressed: _answerController.text.isNotEmpty ? _submitAnswer : null,
            backgroundColor: _answerController.text.isNotEmpty
                ? AppColors.info
                : AppColors.surfaceLight,
            child: Text(
              'Submit Answer',
              style: TextStyle(
                color: _answerController.text.isNotEmpty
                    ? Colors.white
                    : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final reward = _correctAnswers * 10;
    final isPerfect = _correctAnswers == 5;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GameCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPerfect ? '🎉' : '✅',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                isPerfect ? 'Perfect Score!' : 'Quiz Complete!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You got $_correctAnswers/5 correct',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
                      '+\$$reward',
                      style: TextStyle(
                        color: AppColors.money,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AnimatedButton(
                onPressed: () => context.pop(),
                backgroundColor: AppColors.info,
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
