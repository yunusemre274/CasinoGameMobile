import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/game_provider.dart';
import '../../../core/services/casino_logic/casino_logic.dart';
import '../../../shared/widgets/casino_widgets.dart';

/// Aviator Game Page - Cash out before the plane crashes!
class AviatorPage extends ConsumerStatefulWidget {
  const AviatorPage({super.key});

  @override
  ConsumerState<AviatorPage> createState() => _AviatorPageState();
}

class _AviatorPageState extends ConsumerState<AviatorPage>
    with SingleTickerProviderStateMixin {
  // Casino logic
  final AviatorLogic _aviatorLogic = AviatorLogic();
  AviatorResult? _aviatorResult;

  // Game state
  int _betAmount = 100;
  double _multiplier = 1.0;
  double _crashPoint = 1.0;
  bool _isFlying = false;
  bool _hasCrashed = false;
  bool _hasCashedOut = false;
  bool _showResult = false;
  int _winAmount = 0;

  // Animation
  late AnimationController _planeController;
  Timer? _gameTimer;
  Stopwatch _flightStopwatch = Stopwatch();

  // Flight path points for drawing
  List<Offset> _flightPath = [];

  // Preset bet amounts
  final List<int> _betPresets = [50, 100, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
  }

  @override
  void dispose() {
    _planeController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _selectBetAmount(int amount) {
    if (_isFlying) return;
    HapticFeedback.selectionClick();
    setState(() => _betAmount = amount);
  }

  void _startFlight() {
    if (_isFlying) return;

    final gameState = ref.read(gameProvider);
    if (gameState.money < _betAmount) {
      _showInsufficientFundsSnackbar();
      return;
    }

    // Deduct bet
    ref.read(gameProvider.notifier).spendMoney(_betAmount);

    HapticFeedback.heavyImpact();

    // Use casino logic to start flight and generate crash point
    _aviatorLogic.startFlight();
    _crashPoint = _aviatorLogic.crashPoint;

    setState(() {
      _isFlying = true;
      _hasCrashed = false;
      _hasCashedOut = false;
      _showResult = false;
      _multiplier = 1.0;
      _winAmount = 0;
      _flightPath = [];
      _aviatorResult = null;
    });

    // Start flight stopwatch for multiplier calculation
    _flightStopwatch.reset();
    _flightStopwatch.start();

    // Start the game loop using casino logic for multiplier curve
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Use casino logic tick to update multiplier
      final stillFlying = _aviatorLogic.tick(_flightStopwatch.elapsed);

      setState(() {
        _multiplier = _aviatorLogic.currentMultiplier;

        // Add point to flight path
        if (_flightPath.length < 200) {
          _flightPath.add(
            Offset(_flightPath.length * 2.0, 200 - (_multiplier - 1) * 30),
          );
        }
      });

      // Check for crash
      if (!stillFlying) {
        timer.cancel();
        _flightStopwatch.stop();
        _crash();
      }
    });
  }

  void _cashOut() {
    if (!_isFlying || _hasCrashed || _hasCashedOut) return;

    HapticFeedback.heavyImpact();

    _gameTimer?.cancel();
    _flightStopwatch.stop();

    // Use casino logic for cashout
    _aviatorResult = _aviatorLogic.cashOut();
    _winAmount = _aviatorLogic.calculatePayout(_betAmount, _aviatorResult!);
    ref.read(gameProvider.notifier).addMoney(_winAmount);

    setState(() {
      _hasCashedOut = true;
      _isFlying = false;
      _showResult = true;
    });
  }

  void _crash() {
    HapticFeedback.heavyImpact();

    // Get crash result from casino logic
    _aviatorResult = _aviatorLogic.getCrashResult();

    setState(() {
      _hasCrashed = true;
      _isFlying = false;
      _showResult = true;
    });
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
    _aviatorLogic.reset();
    setState(() {
      _showResult = false;
      _multiplier = 1.0;
      _flightPath = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final bool canPlay =
        !_isFlying && gameState.money >= _betAmount && !_showResult;
    final potentialWin = (_betAmount * _multiplier).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            _gameTimer?.cancel();
            context.pop();
          },
        ),
        title: const Text('✈️ Aviator'),
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
              // Bet amount selector (only when not flying)
              if (!_isFlying && !_showResult)
                BetSelector(
                  presets: _betPresets,
                  currentBet: _betAmount,
                  playerMoney: gameState.money,
                  isDisabled: _isFlying,
                  onSelect: _selectBetAmount,
                ),

              if (!_isFlying && !_showResult) const SizedBox(height: 16),

              // Multiplier display using new widget
              MultiplierDisplay(
                multiplier: _multiplier,
                hasCrashed: _hasCrashed,
                hasCashedOut: _hasCashedOut,
              ),
              const SizedBox(height: 8),

              if (_isFlying)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.money.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.money.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'Potential: \$$potentialWin',
                          style: TextStyle(
                            color: AppColors.money,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Flight area
              Expanded(
                child: GameArea(
                  padding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      // Grid lines
                      CustomPaint(size: Size.infinite, painter: _GridPainter()),

                      // Flight path
                      if (_flightPath.isNotEmpty)
                        CustomPaint(
                          size: Size.infinite,
                          painter: _FlightPathPainter(
                            points: _flightPath,
                            color: _hasCrashed
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                        ),

                      // Airplane with enhanced animation
                      AnimatedBuilder(
                        animation: _planeController,
                        builder: (context, child) {
                          final wobble = _isFlying
                              ? sin(_planeController.value * 2 * pi) * 4
                              : 0.0;

                          // Pulse scale for flying state
                          final pulseScale = _isFlying
                              ? 1.0 +
                                    sin(_planeController.value * 4 * pi) * 0.05
                              : 1.0;

                          return Positioned(
                            left: _isFlying
                                ? min(
                                    60 + (_multiplier - 1) * 30,
                                    MediaQuery.of(context).size.width - 100,
                                  )
                                : 60,
                            bottom: _hasCrashed
                                ? 40
                                : (80 + (_multiplier - 1) * 20 + wobble),
                            child: Transform.scale(
                              scale: _hasCrashed ? 1.0 : pulseScale,
                              child: Transform.rotate(
                                angle: _hasCrashed
                                    ? 0.8
                                    : (_isFlying ? -0.3 : -0.5),
                                child: Text(
                                  _hasCrashed ? '💥' : '✈️',
                                  style: TextStyle(
                                    fontSize: 52,
                                    shadows: _isFlying
                                        ? [
                                            Shadow(
                                              color: AppColors.success
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 20,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Crashed overlay with animation
                      if (_hasCrashed)
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value.clamp(0.0, 1.0),
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '💥 CRASHED!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Flew away at ${_crashPoint.toStringAsFixed(2)}x',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '-\$$_betAmount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Cashed out overlay with animation
                      if (_hasCashedOut)
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value.clamp(0.0, 1.0),
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.95,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🎉 CASHED OUT!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '+\$$_winAmount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'at ${_multiplier.toStringAsFixed(2)}x',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Waiting message
                      if (!_isFlying && !_showResult)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 2000),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, sin(value * 2 * pi) * 8),
                                    child: child,
                                  );
                                },
                                child: Text(
                                  '✈️',
                                  style: TextStyle(
                                    fontSize: 64,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Place bet and take off!',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons with new GameButton
              if (_showResult)
                GameButton(
                  text: 'PLAY AGAIN',
                  icon: Icons.replay,
                  color: AppColors.info,
                  onPressed: _playAgain,
                )
              else if (_isFlying)
                _CashOutButton(potentialWin: potentialWin, onPressed: _cashOut)
              else
                GameButton(
                  text: 'TAKE OFF',
                  icon: Icons.flight_takeoff,
                  color: AppColors.happiness,
                  enabled: canPlay,
                  onPressed: _startFlight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Special pulsing cash out button for urgency
class _CashOutButton extends StatefulWidget {
  final int potentialWin;
  final VoidCallback onPressed;

  const _CashOutButton({required this.potentialWin, required this.onPressed});

  @override
  State<_CashOutButton> createState() => _CashOutButtonState();
}

class _CashOutButtonState extends State<_CashOutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onPressed();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success,
                    AppColors.success.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '💰 CASH OUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${widget.potentialWin}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlightPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  _FlightPathPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points.first.dx, size.height - points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, size.height - points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _FlightPathPainter oldDelegate) =>
      points.length != oldDelegate.points.length;
}
