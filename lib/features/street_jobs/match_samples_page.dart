import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../shared/widgets/animated_button.dart';
import '../../shared/widgets/game_card.dart';

class MatchSamplesPage extends ConsumerStatefulWidget {
  const MatchSamplesPage({super.key});

  @override
  ConsumerState<MatchSamplesPage> createState() => _MatchSamplesPageState();
}

class _MatchSamplesPageState extends ConsumerState<MatchSamplesPage> {
  final List<String> _emojis = ['🍎', '🍊', '🍋', '🍇', '🍓', '🍑'];
  late List<String> _cards;
  final Set<int> _flipped = {};
  final Set<int> _matched = {};
  int? _firstSelection;
  bool _isProcessing = false;
  bool _isFinished = false;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Create pairs
    _cards = [..._emojis, ..._emojis];
    _cards.shuffle(Random());
    _flipped.clear();
    _matched.clear();
    _firstSelection = null;
    _isProcessing = false;
    _moves = 0;
  }

  void _onCardTap(int index) {
    if (_isProcessing) return;
    if (_matched.contains(index)) return;
    if (_flipped.contains(index)) return;

    HapticFeedback.selectionClick();

    setState(() {
      _flipped.add(index);
    });

    if (_firstSelection == null) {
      _firstSelection = index;
    } else {
      _moves++;
      _isProcessing = true;

      final first = _firstSelection!;
      final second = index;

      if (_cards[first] == _cards[second]) {
        // Match found!
        HapticFeedback.mediumImpact();
        setState(() {
          _matched.add(first);
          _matched.add(second);
          _firstSelection = null;
          _isProcessing = false;
        });

        // Check if game complete
        if (_matched.length == _cards.length) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _isFinished = true);
              final reward = ref
                  .read(gameProvider.notifier)
                  .completeMatchSamples();
              if (reward > 0) {
                HapticFeedback.heavyImpact();
              }
            }
          });
        }
      } else {
        // No match - flip back after delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _flipped.remove(first);
              _flipped.remove(second);
              _firstSelection = null;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🔍 Match Samples'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isFinished ? _buildResultScreen() : _buildGameScreen(),
    );
  }

  Widget _buildGameScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats
          GameCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Moves', '$_moves'),
                _buildStat(
                  'Matched',
                  '${_matched.length ~/ 2}/${_emojis.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Find all matching pairs to complete the job!',
                    style: TextStyle(color: AppColors.success, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Game grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              final isFlipped =
                  _flipped.contains(index) || _matched.contains(index);
              final isMatched = _matched.contains(index);

              return GestureDetector(
                onTap: () => _onCardTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isMatched
                        ? AppColors.success.withValues(alpha: 0.2)
                        : isFlipped
                        ? AppColors.info.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMatched
                          ? AppColors.success
                          : isFlipped
                          ? AppColors.info
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isFlipped
                          ? Text(
                              _cards[index],
                              key: ValueKey('emoji_$index'),
                              style: const TextStyle(fontSize: 28),
                            )
                          : Icon(
                              Icons.question_mark,
                              key: ValueKey('question_$index'),
                              color: AppColors.textMuted,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
              const Text('🎯', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'All Matched!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completed in $_moves moves',
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
                      '+\$50',
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
                backgroundColor: AppColors.success,
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
