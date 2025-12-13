import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/game_provider.dart';
import '../../../core/services/casino_logic/casino_logic.dart';
import '../../../shared/widgets/casino_widgets.dart';

/// Coin Flip (Tail-Head) Game Page - Flip the coin and win!
class CoinFlipPage extends ConsumerStatefulWidget {
  const CoinFlipPage({super.key});

  @override
  ConsumerState<CoinFlipPage> createState() => _CoinFlipPageState();
}

class _CoinFlipPageState extends ConsumerState<CoinFlipPage>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _anticipationController;
  late Animation<double> _flipAnimation;
  late Animation<double> _anticipationAnimation;

  // Casino logic
  final CoinFlipLogic _coinFlipLogic = CoinFlipLogic();
  CoinFlipResult? _flipResult;

  // Game state
  int _betAmount = 100;
  CoinSide? _playerChoice;
  CoinSide? _result;
  bool _isFlipping = false;
  bool _showResult = false;
  bool _inAnticipation = false;

  // Preset bet amounts
  final List<int> _betPresets = [50, 100, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    // Main flip - fast spins
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Anticipation - slow final rotation
    _anticipationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0,
      end: 6 * pi,
    ).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeOut));

    _anticipationAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(
        parent: _anticipationController,
        curve: Curves.easeInOutBack,
      ),
    );

    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Pause for anticipation before final reveal
        setState(() => _inAnticipation = true);
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _anticipationController.forward();
        });
      }
    });

    _anticipationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showResult = true;
          _isFlipping = false;
          _inAnticipation = false;
        });
        _handleResult();
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _anticipationController.dispose();
    super.dispose();
  }

  void _selectChoice(CoinSide choice) {
    if (_isFlipping) return;
    HapticFeedback.selectionClick();
    setState(() {
      _playerChoice = choice;
      _showResult = false;
      _result = null;
      _flipResult = null;
    });
  }

  void _selectBet(int amount) {
    if (_isFlipping) return;
    HapticFeedback.selectionClick();
    setState(() => _betAmount = amount);
  }

  void _flipCoin() {
    if (_isFlipping || _playerChoice == null) return;

    final gameState = ref.read(gameProvider);
    if (gameState.money < _betAmount) {
      _showInsufficientFundsSnackbar();
      return;
    }

    // Deduct bet
    ref.read(gameProvider.notifier).spendMoney(_betAmount);

    HapticFeedback.heavyImpact();

    // Use casino logic for realistic odds
    _flipResult = _coinFlipLogic.play(_playerChoice!, betAmount: _betAmount);

    setState(() {
      _isFlipping = true;
      _showResult = false;
      _result = _flipResult!.result;
    });

    _flipController.reset();
    _anticipationController.reset();
    _flipController.forward();
  }

  void _handleResult() {
    HapticFeedback.heavyImpact();

    // Use casino logic result - payout already calculated with house edge
    if (_flipResult != null && _flipResult!.won) {
      ref.read(gameProvider.notifier).addMoney(_flipResult!.payout);
      // Extra haptic celebration for wins
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.heavyImpact();
      });
    }
  }

  void _showInsufficientFundsSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('💸 Not enough money!'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _playAgain() {
    HapticFeedback.selectionClick();
    setState(() {
      _playerChoice = null;
      _result = null;
      _flipResult = null;
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final bool canPlay =
        _playerChoice != null && gameState.money >= _betAmount && !_isFlipping;
    final bool isWin = _showResult && _flipResult?.won == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text('🪙 Tail-Head'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '\$${gameState.money}',
                style: TextStyle(
                  color: AppColors.money,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bet amount selector
            BetSelector(
              presets: _betPresets,
              currentBet: _betAmount,
              playerMoney: gameState.money,
              isDisabled: _isFlipping || _inAnticipation,
              onSelect: _selectBet,
            ),
            const SizedBox(height: 16),

            // Coin area
            Expanded(
              child: GameArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated coin with anticipation
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _flipAnimation,
                        _anticipationAnimation,
                      ]),
                      builder: (context, child) {
                        // Calculate total rotation with anticipation
                        double rotation = _flipAnimation.value;
                        if (_inAnticipation ||
                            _anticipationController.isAnimating) {
                          rotation = 6 * pi + _anticipationAnimation.value;
                        }

                        // Determine which face to show
                        final normalizedRotation = (rotation / pi) % 2;
                        final showHeads = normalizedRotation < 1;
                        final coinFace = _showResult
                            ? (_result == CoinSide.heads)
                            : (showHeads || (!_isFlipping && !_inAnticipation));

                        // Coin scale based on rotation
                        final scale = (cos(rotation) * 0.3).abs() + 0.7;

                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateX(rotation)
                            ..scale(scale, 1.0, 1.0),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.3, -0.3),
                                radius: 1.2,
                                colors: coinFace
                                    ? [
                                        const Color(0xFFFFE066),
                                        const Color(0xFFFFD700),
                                        const Color(0xFFDAA520),
                                        const Color(0xFFB8860B),
                                      ]
                                    : [
                                        const Color(0xFFE8E8E8),
                                        const Color(0xFFC0C0C0),
                                        const Color(0xFFA0A0A0),
                                        const Color(0xFF808080),
                                      ],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (coinFace
                                              ? const Color(0xFFFFD700)
                                              : const Color(0xFFC0C0C0))
                                          .withValues(alpha: 0.5),
                                  blurRadius: _isFlipping ? 30 : 20,
                                  spreadRadius: _isFlipping ? 5 : 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: coinFace
                                    ? const Color(0xFFB8860B)
                                    : const Color(0xFF808080),
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: _showResult
                                  ? TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.5, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.elasticOut,
                                      builder: (context, iconScale, _) {
                                        return Transform.scale(
                                          scale: iconScale,
                                          child: Text(
                                            _result == CoinSide.heads
                                                ? '👑'
                                                : '🦅',
                                            style: const TextStyle(
                                              fontSize: 72,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Text(
                                      '?',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 64,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            offset: const Offset(2, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Result message using new ResultCard
                    if (_showResult) ...[
                      ResultCard(
                        isWin: isWin,
                        title: isWin ? 'YOU WIN!' : 'YOU LOSE',
                        amount: isWin
                            ? '+\$${_flipResult!.payout}'
                            : '-\$$_betAmount',
                        subtitle: _result == CoinSide.heads
                            ? 'It landed on HEADS'
                            : 'It landed on TAILS',
                        onPlayAgain: _playAgain,
                      ),
                    ] else ...[
                      // Instruction text
                      Column(
                        children: [
                          Icon(
                            _playerChoice == null
                                ? Icons.touch_app_rounded
                                : Icons.swipe_up_rounded,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _playerChoice == null
                                ? 'Choose your side below'
                                : 'Ready to flip!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          if (_playerChoice != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'You chose ${_playerChoice == CoinSide.heads ? 'HEADS 👑' : 'TAILS 🦅'}',
                              style: TextStyle(
                                color: _playerChoice == CoinSide.heads
                                    ? AppColors.warning
                                    : AppColors.info,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Choice buttons using SelectionChip
            if (!_showResult) ...[
              Row(
                children: [
                  Expanded(
                    child: SelectionChip(
                      label: 'HEADS',
                      emoji: '👑',
                      isSelected: _playerChoice == CoinSide.heads,
                      isDisabled: _isFlipping,
                      selectedColor: AppColors.warning,
                      onTap: () => _selectChoice(CoinSide.heads),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SelectionChip(
                      label: 'TAILS',
                      emoji: '🦅',
                      isSelected: _playerChoice == CoinSide.tails,
                      isDisabled: _isFlipping,
                      selectedColor: AppColors.info,
                      onTap: () => _selectChoice(CoinSide.tails),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Flip button using GameButton
              GameButton(
                text: _isFlipping ? 'FLIPPING...' : 'FLIP COIN',
                emoji: '🎲',
                color: AppColors.success,
                enabled: canPlay,
                isLoading: _isFlipping,
                disabledReason: _playerChoice == null
                    ? 'Select HEADS or TAILS first'
                    : (gameState.money < _betAmount
                          ? 'Not enough money'
                          : null),
                onPressed: _flipCoin,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
