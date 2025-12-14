import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/game_provider.dart';
import '../../../core/services/casino_logic/casino_logic.dart';
import '../../../shared/widgets/casino_widgets.dart';

/// Slot Machine (Slot 777) Game Page - Spin the reels and win!
class SlotMachinePage extends ConsumerStatefulWidget {
  const SlotMachinePage({super.key});

  @override
  ConsumerState<SlotMachinePage> createState() => _SlotMachinePageState();
}

class _SlotMachinePageState extends ConsumerState<SlotMachinePage>
    with TickerProviderStateMixin {
  // Casino logic
  final SlotLogic _slotLogic = SlotLogic();
  SlotResult? _slotResult;

  // Get emoji list from slot logic
  List<String> get _symbols => _slotLogic.symbols.map((s) => s.emoji).toList();

  // Animation controllers for each reel
  late List<AnimationController> _reelControllers;
  late List<Animation<double>> _reelAnimations;

  // Game state
  int _betAmount = 100;
  List<int> _reelResults = [0, 0, 0]; // Symbol indices
  bool _isSpinning = false;
  bool _showResult = false;
  int _winAmount = 0;

  // Preset bet amounts
  final List<int> _betPresets = [50, 100, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Staggered durations: first reel stops fastest, last reel has anticipation pause
    _reelControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: 1200 + (index * 600),
        ), // 1.2s, 1.8s, 2.4s - more dramatic stagger
        vsync: this,
      ),
    );

    // Different curves for each reel - last reel has anticipation
    _reelAnimations = _reelControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;

      // Last reel has special curve with anticipation pause
      final curve = index == 2
          ? const _AnticipationCurve() // Custom curve with pause
          : Curves.easeOutCubic;

      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: controller, curve: curve));
    }).toList();

    // Add listeners for haptic feedback as each reel stops
    for (int i = 0; i < _reelControllers.length; i++) {
      _reelControllers[i].addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.mediumImpact(); // Thud as each reel stops

          // Only show result after last reel
          if (i == 2) {
            setState(() {
              _isSpinning = false;
              _showResult = true;
            });
            _handleResult();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _reelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectBet(int amount) {
    if (_isSpinning) return;
    HapticFeedback.selectionClick();
    setState(() => _betAmount = amount);
  }

  void _spin() {
    if (_isSpinning) return;

    final gameState = ref.read(gameProvider);
    if (gameState.money < _betAmount) {
      _showInsufficientFundsSnackbar();
      return;
    }

    // Deduct bet
    ref.read(gameProvider.notifier).spendMoney(_betAmount);

    HapticFeedback.heavyImpact();

    // Use casino logic for realistic odds
    _slotResult = _slotLogic.spin(_betAmount);

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _winAmount = 0;

      // Map slot result to reel indices for display
      _reelResults = _slotResult!.reels.map((symbol) {
        return _slotLogic.symbols.indexWhere((s) => s.symbol == symbol);
      }).toList();
    });

    // Start all reels
    for (final controller in _reelControllers) {
      controller.reset();
      controller.forward();
    }
  }

  void _handleResult() {
    HapticFeedback.mediumImpact();

    // Use casino logic result with proper paytable
    if (_slotResult != null) {
      _winAmount = _slotResult!.payout;
      if (_winAmount > 0) {
        ref.read(gameProvider.notifier).addMoney(_winAmount);
        HapticFeedback.heavyImpact();
      }
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
      _showResult = false;
      _winAmount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final bool canPlay = gameState.money >= _betAmount && !_isSpinning;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text('🎰 Slot 777'),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Bet amount selector
              BetSelector(
                presets: _betPresets,
                currentBet: _betAmount,
                playerMoney: gameState.money,
                isDisabled: _isSpinning,
                onSelect: _selectBet,
              ),
              const SizedBox(height: 16),

              // Slot machine
              Expanded(
                child: GameArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Jackpot display
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: _isSpinning ? (0.95 + (value * 0.1)) : 1.0,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.money,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.money.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('💰', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                'JACKPOT: \$${_betAmount * 50}',
                                style: TextStyle(
                                  color: AppColors.money,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('💰', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SizedBox(height: 32),

                      // Reels with enhanced visuals
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.level.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: _SlotReel(
                                animation: _reelAnimations[index],
                                resultIndex: _reelResults[index],
                                symbols: _symbols,
                                isSpinning: _isSpinning,
                                reelIndex: index,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Result message
                      if (_showResult)
                        ResultCard(
                          isWin: _winAmount > 0,
                          title: _winAmount > 0
                              ? '🎉 ${_slotResult?.winType ?? 'WIN'}!'
                              : '😢 NO LUCK',
                          amount: _winAmount > 0
                              ? '+\$$_winAmount'
                              : '-\$$_betAmount',
                          onPlayAgain: _playAgain,
                        )
                      else if (!_isSpinning)
                        Text(
                          'Match 3 symbols to win!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Spin button
              GameButton(
                text: _isSpinning ? 'SPINNING...' : 'SPIN',
                icon: _isSpinning ? Icons.hourglass_top : Icons.rotate_right,
                color: AppColors.level,
                enabled: canPlay && !_showResult,
                isLoading: _isSpinning,
                onPressed: _spin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotReel extends StatelessWidget {
  final Animation<double> animation;
  final int resultIndex;
  final List<String> symbols;
  final bool isSpinning;
  final int reelIndex;

  const _SlotReel({
    required this.animation,
    required this.resultIndex,
    required this.symbols,
    required this.isSpinning,
    required this.reelIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.level, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          // Inner glow when spinning
          if (isSpinning)
            BoxShadow(
              color: AppColors.level.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: -2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          children: [
            // Gradient overlay for depth
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            // Reel content
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                // Calculate which symbols to show based on animation progress
                final totalSpins =
                    8 + (reelIndex * 3); // More spins for later reels
                final currentPosition =
                    (animation.value * totalSpins * symbols.length) %
                    symbols.length;

                // When spinning, show rapidly changing symbols
                // When stopped, show the result
                final displayIndex = isSpinning
                    ? currentPosition.floor() % symbols.length
                    : resultIndex;

                final prevIndex =
                    (displayIndex - 1 + symbols.length) % symbols.length;
                final nextIndex = (displayIndex + 1) % symbols.length;

                // Calculate offset for smooth scrolling effect
                final offset = isSpinning ? (currentPosition % 1) : 0.0;

                return Stack(
                  children: [
                    // Previous symbol (faded, top)
                    Positioned(
                      top: -45 + (offset * 45),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Opacity(
                          opacity: 0.25,
                          child: Text(
                            symbols[prevIndex],
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    ),
                    // Current symbol (center) with highlight
                    Positioned(
                      top: 42 - (offset * 45),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.level.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.level.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            symbols[displayIndex],
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    ),
                    // Next symbol (faded, bottom)
                    Positioned(
                      bottom: -45 + (offset * 45),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Opacity(
                          opacity: 0.25,
                          child: Text(
                            symbols[nextIndex],
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Shine effect
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom curve with anticipation pause at 80%
class _AnticipationCurve extends Curve {
  const _AnticipationCurve();

  @override
  double transformInternal(double t) {
    // Fast spin from 0-70%, pause at 70-85%, then slow finish 85-100%
    if (t < 0.7) {
      // Fast spin phase - ease out
      return Curves.easeOut.transform(t / 0.7) * 0.85;
    } else if (t < 0.85) {
      // Pause/anticipation phase - very slow
      final pauseT = (t - 0.7) / 0.15;
      return 0.85 + (pauseT * 0.05); // Only move 5% during pause
    } else {
      // Final reveal - slow ease out
      final finalT = (t - 0.85) / 0.15;
      return 0.9 + (Curves.easeOutCubic.transform(finalT) * 0.1);
    }
  }
}
