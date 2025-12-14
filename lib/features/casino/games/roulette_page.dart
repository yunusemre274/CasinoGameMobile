import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/game_provider.dart';
import '../../../core/services/casino_logic/casino_logic.dart';
import '../../../shared/widgets/casino_widgets.dart';

/// Roulette Game Page - Spin the wheel and win!
class RoulettePage extends ConsumerStatefulWidget {
  const RoulettePage({super.key});

  @override
  ConsumerState<RoulettePage> createState() => _RoulettePageState();
}

class _RoulettePageState extends ConsumerState<RoulettePage>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late AnimationController _anticipationController;

  // Casino logic
  final RouletteLogic _rouletteLogic = RouletteLogic();
  RouletteResult? _rouletteResult;

  // European roulette wheel order
  static const List<int> _wheelNumbers = [
    0,
    32,
    15,
    19,
    4,
    21,
    2,
    25,
    17,
    34,
    6,
    27,
    13,
    36,
    11,
    30,
    8,
    23,
    10,
    5,
    24,
    16,
    33,
    1,
    20,
    14,
    31,
    9,
    22,
    18,
    29,
    7,
    28,
    12,
    35,
    3,
    26,
  ];

  // Game state
  int _betAmount = 100;
  RouletteBetType? _betType;
  int? _resultNumber;
  String? _resultColor;
  bool _isSpinning = false;
  bool _showResult = false;
  int _winAmount = 0;

  // Preset bet amounts
  final List<int> _betPresets = [50, 100, 250, 500, 1000];

  // Current wheel rotation angle
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    // Main spin controller with longer duration for dramatic effect
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    // Anticipation controller for the final slow-down
    _anticipationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _showResult = true;
        });
        _handleResult();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _anticipationController.dispose();
    super.dispose();
  }

  String _getNumberColor(int number) {
    // Use casino logic for correct European roulette colors
    return RouletteLogic.getNumberColor(number);
  }

  void _selectBet(RouletteBetType type) {
    if (_isSpinning) return;
    HapticFeedback.selectionClick();
    setState(() {
      _betType = type;
      _showResult = false;
      _resultNumber = null;
      _resultColor = null;
      _rouletteResult = null;
    });
  }

  void _selectBetAmount(int amount) {
    if (_isSpinning) return;
    HapticFeedback.selectionClick();
    setState(() => _betAmount = amount);
  }

  void _spin() {
    if (_isSpinning || _betType == null) return;

    final gameState = ref.read(gameProvider);
    if (gameState.money < _betAmount) {
      _showInsufficientFundsSnackbar();
      return;
    }

    // Deduct bet
    ref.read(gameProvider.notifier).spendMoney(_betAmount);

    HapticFeedback.heavyImpact();

    // Use casino logic for realistic odds
    final bet = RouletteBet(type: _betType!, amount: _betAmount);
    _rouletteResult = _rouletteLogic.spin(bet);

    _resultNumber = _rouletteResult!.number;
    _resultColor = _rouletteResult!.color;

    // Calculate spin angle based on result
    final resultIndex = _wheelNumbers.indexOf(_resultNumber!);
    final segmentAngle = 2 * pi / _wheelNumbers.length;
    final targetAngle = resultIndex * segmentAngle;
    // Add multiple full rotations plus target
    final totalRotation = 6 * 2 * pi + targetAngle;

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _winAmount = 0;
    });

    _spinAnimation =
        Tween<double>(
          begin: _currentAngle,
          end: _currentAngle + totalRotation,
        ).animate(
          CurvedAnimation(
            parent: _spinController,
            curve: const _RouletteDecelerationCurve(),
          ),
        );

    _currentAngle = _currentAngle + totalRotation;

    _spinController.reset();
    _spinController.forward();
  }

  void _handleResult() {
    HapticFeedback.mediumImpact();

    // Use casino logic result with proper payouts
    if (_rouletteResult != null && _rouletteResult!.won) {
      _winAmount = _rouletteResult!.payout;
      ref.read(gameProvider.notifier).addMoney(_winAmount);
      HapticFeedback.heavyImpact();
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
      _betType = null;
      _showResult = false;
      _winAmount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final bool canPlay =
        _betType != null && gameState.money >= _betAmount && !_isSpinning;

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
        title: const Text('🎡 Roulette'),
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
                onSelect: _selectBetAmount,
              ),
              const SizedBox(height: 16),

              // Wheel area
              Expanded(
                child: GameArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pointer with glow effect
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text(
                          '▼',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Animated wheel with enhanced visuals
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) {
                          final angle = _isSpinning
                              ? _spinAnimation.value
                              : _currentAngle;

                          // Add shake effect at very slow speeds (near end)
                          final progress = _spinController.value;
                          final isNearEnd = progress > 0.85;
                          final shakeOffset = isNearEnd
                              ? sin(progress * 80) * (1 - progress) * 3
                              : 0.0;

                          return Transform.translate(
                            offset: Offset(shakeOffset, 0),
                            child: Transform.rotate(
                              angle: angle,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.money,
                                    width: 5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.money.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: CustomPaint(
                                    size: const Size(220, 220),
                                    painter: _RouletteWheelPainter(
                                      numbers: _wheelNumbers,
                                      getColor: _getNumberColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Result message
                      if (_showResult)
                        _RouletteResultCard(
                          resultNumber: _resultNumber!,
                          resultColor: _resultColor!,
                          isWin: _winAmount > 0,
                          winAmount: _winAmount,
                          betAmount: _betAmount,
                          onPlayAgain: _playAgain,
                        )
                      else if (!_isSpinning)
                        Text(
                          _betType == null
                              ? 'Place your bet on a color'
                              : 'Tap SPIN to play!',
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

              // Betting chips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'BET ON COLOR',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BetChip(
                          color: Colors.red,
                          label: 'Red',
                          payout: '2x',
                          isSelected: _betType == RouletteBetType.red,
                          isDisabled: _isSpinning || _showResult,
                          onTap: () => _selectBet(RouletteBetType.red),
                        ),
                        _BetChip(
                          color: Colors.black87,
                          label: 'Black',
                          payout: '2x',
                          isSelected: _betType == RouletteBetType.black,
                          isDisabled: _isSpinning || _showResult,
                          onTap: () => _selectBet(RouletteBetType.black),
                        ),
                        _BetChip(
                          color: Colors.green,
                          label: '0',
                          payout: '36x',
                          isSelected: _betType == RouletteBetType.single,
                          isDisabled: _isSpinning || _showResult,
                          onTap: () => _selectBet(RouletteBetType.single),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Spin button
              GameButton(
                text: _isSpinning ? 'SPINNING...' : 'SPIN',
                icon: Icons.refresh,
                color: AppColors.danger,
                enabled: canPlay && !_showResult,
                isLoading: _isSpinning,
                onPressed: _spin,
                disabledReason: _betType == null ? 'Select a bet first!' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BetChip extends StatefulWidget {
  final Color color;
  final String label;
  final String payout;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _BetChip({
    required this.color,
    required this.label,
    required this.payout,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_BetChip> createState() => _BetChipState();
}

class _BetChipState extends State<_BetChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isDisabled ? null : (_) => _controller.forward(),
      onTapUp: widget.isDisabled
          ? null
          : (_) {
              _controller.reverse();
              HapticFeedback.selectionClick();
              widget.onTap();
            },
      onTapCancel: widget.isDisabled ? null : () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.color.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected ? widget.color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: widget.isDisabled
                          ? widget.color.withValues(alpha: 0.3)
                          : widget.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isDisabled
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.payout,
                    style: TextStyle(
                      color: AppColors.money,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Roulette result card with number ball
class _RouletteResultCard extends StatelessWidget {
  final int resultNumber;
  final String resultColor;
  final bool isWin;
  final int winAmount;
  final int betAmount;
  final VoidCallback onPlayAgain;

  const _RouletteResultCard({
    required this.resultNumber,
    required this.resultColor,
    required this.isWin,
    required this.winAmount,
    required this.betAmount,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final ballColor = resultColor == 'red'
        ? Colors.red
        : resultColor == 'black'
        ? Colors.black
        : Colors.green;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value.clamp(0.0, 1.0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isWin
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWin ? AppColors.success : AppColors.danger,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isWin ? AppColors.success : AppColors.danger).withValues(
                alpha: 0.3,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Result ball
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.bounceOut,
                  builder: (context, bounce, child) {
                    return Transform.scale(
                      scale: bounce,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.3, -0.3),
                            colors: [
                              Color.lerp(ballColor, Colors.white, 0.3)!,
                              ballColor,
                              Color.lerp(ballColor, Colors.black, 0.3)!,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$resultNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWin ? '🎉 YOU WIN!' : '😢 YOU LOSE',
                      style: TextStyle(
                        color: isWin ? AppColors.success : AppColors.danger,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isWin ? '+\$$winAmount' : '-\$$betAmount',
                      style: TextStyle(
                        color: isWin ? AppColors.money : AppColors.danger,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onPlayAgain,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play Again'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouletteWheelPainter extends CustomPainter {
  final List<int> numbers;
  final String Function(int) getColor;

  _RouletteWheelPainter({required this.numbers, required this.getColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / numbers.length;

    for (int i = 0; i < numbers.length; i++) {
      final paint = Paint()
        ..color = getColor(numbers[i]) == 'red'
            ? Colors.red.shade700
            : getColor(numbers[i]) == 'black'
            ? Colors.grey.shade900
            : Colors.green.shade700
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + i * segmentAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw segment border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + i * segmentAngle,
        segmentAngle,
        true,
        borderPaint,
      );
    }

    // Draw center circle
    canvas.drawCircle(
      center,
      radius * 0.3,
      Paint()..color = const Color(0xFF1A1A2E),
    );
    canvas.drawCircle(center, radius * 0.25, Paint()..color = AppColors.money);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom curve for natural roulette wheel deceleration
/// Starts fast, then has a dramatic slowdown with slight anticipation
class _RouletteDecelerationCurve extends Curve {
  const _RouletteDecelerationCurve();

  @override
  double transformInternal(double t) {
    // Phase 1: Fast spin (0-60%) - quick ease-out
    if (t < 0.6) {
      return Curves.easeOut.transform(t / 0.6) * 0.75;
    }
    // Phase 2: Slowing down (60-85%) - linear slow
    else if (t < 0.85) {
      final slowT = (t - 0.6) / 0.25;
      return 0.75 + slowT * 0.15;
    }
    // Phase 3: Final clicks (85-100%) - very slow with slight acceleration at end
    else {
      final finalT = (t - 0.85) / 0.15;
      // Ease-out-back gives slight "settling" feel
      return 0.9 + Curves.easeOutCubic.transform(finalT) * 0.1;
    }
  }
}
