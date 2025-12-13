import 'dart:math';
import 'rng_service.dart';
import 'casino_config.dart';

/// Aviator (Crash) game logic
/// Uses exponential distribution to generate crash points
/// House edge is built into the distribution

class AviatorResult {
  final double crashPoint;
  final double? cashoutAt;
  final bool won;
  final double multiplier;

  AviatorResult({
    required this.crashPoint,
    this.cashoutAt,
    required this.won,
    required this.multiplier,
  });
}

class AviatorLogic {
  final CasinoRng _rng;
  final double houseEdge;

  /// Current flight state
  double _currentMultiplier = 1.0;
  double _crashPoint = 0.0;
  bool _hasStarted = false;
  bool _hasCrashed = false;
  bool _hasCashedOut = false;

  AviatorLogic({CasinoRng? rng, this.houseEdge = CasinoConfig.aviatorHouseEdge})
    : _rng = rng ?? CasinoRng.instance;

  double get currentMultiplier => _currentMultiplier;
  double get crashPoint => _crashPoint;
  bool get hasStarted => _hasStarted;
  bool get hasCrashed => _hasCrashed;
  bool get hasCashedOut => _hasCashedOut;
  bool get isFlying => _hasStarted && !_hasCrashed && !_hasCashedOut;

  /// Start a new flight - determines crash point
  void startFlight() {
    _currentMultiplier = 1.0;
    _crashPoint = _rng.generateCrashPoint(houseEdge);
    _hasStarted = true;
    _hasCrashed = false;
    _hasCashedOut = false;
  }

  /// Reset for a new round
  void reset() {
    _currentMultiplier = 1.0;
    _crashPoint = 0.0;
    _hasStarted = false;
    _hasCrashed = false;
    _hasCashedOut = false;
  }

  /// Update multiplier (called each tick, e.g., 50ms)
  /// Returns true if still flying, false if crashed
  bool tick(Duration elapsed) {
    if (!isFlying) return false;

    // Multiplier grows exponentially
    // Using standard aviator formula: 1.0 * e^(0.06t) where t is seconds
    final seconds = elapsed.inMilliseconds / 1000.0;
    _currentMultiplier = pow(
      e,
      CasinoConfig.aviatorGrowthRate * seconds,
    ).toDouble();

    if (_currentMultiplier >= _crashPoint) {
      _currentMultiplier = _crashPoint;
      _hasCrashed = true;
      return false;
    }

    return true;
  }

  /// Cash out at current multiplier
  AviatorResult cashOut() {
    if (!isFlying) {
      return AviatorResult(
        crashPoint: _crashPoint,
        cashoutAt: null,
        won: false,
        multiplier: 0,
      );
    }

    _hasCashedOut = true;
    return AviatorResult(
      crashPoint: _crashPoint,
      cashoutAt: _currentMultiplier,
      won: true,
      multiplier: _currentMultiplier,
    );
  }

  /// Get result after crash (player didn't cash out)
  AviatorResult getCrashResult() {
    return AviatorResult(
      crashPoint: _crashPoint,
      cashoutAt: null,
      won: false,
      multiplier: 0,
    );
  }

  /// Calculate payout for a given bet and result
  int calculatePayout(int betAmount, AviatorResult result) {
    if (!result.won) return 0;
    return (betAmount * result.multiplier).round();
  }

  /// Calculate net winnings
  int calculateWinnings(int betAmount, AviatorResult result) {
    return calculatePayout(betAmount, result) - betAmount;
  }

  /// Generate a crash point without starting flight
  /// Useful for display/preview
  double generatePreviewCrashPoint() {
    return _rng.generateCrashPoint(houseEdge);
  }

  /// Get probability of reaching a specific multiplier
  /// Based on crash distribution: P(x) = (1-houseEdge)/x for x >= 1
  double getProbabilityOfReaching(double multiplier) {
    if (multiplier < 1.0) return 1.0;
    return (1 - houseEdge) / multiplier;
  }

  /// Get probability display string
  String getProbabilityDisplay(double multiplier) {
    return '${(getProbabilityOfReaching(multiplier) * 100).toStringAsFixed(1)}%';
  }

  /// Simulate n rounds with auto-cashout at target multiplier
  double simulateRtp(int numRounds, double targetCashout) {
    int totalBet = 0;
    int totalReturn = 0;
    const betAmount = 100;

    for (int i = 0; i < numRounds; i++) {
      totalBet += betAmount;
      final crash = _rng.generateCrashPoint(houseEdge);

      if (crash >= targetCashout) {
        // Won - cashed out before crash
        totalReturn += (betAmount * targetCashout).round();
      }
      // Lost - no return
    }

    return totalReturn / totalBet;
  }

  /// Get theoretical RTP for a given cashout target
  /// RTP = P(crash >= target) * target
  /// P(crash >= target) = (1-houseEdge)/target
  /// So: RTP = (1-houseEdge)/target * target = 1 - houseEdge
  double getTheoreticalRtp(double targetCashout) {
    // RTP is always 1 - houseEdge regardless of cashout target!
    // This is the beauty of the crash distribution
    return 1 - houseEdge;
  }

  /// Get expected value multiplier for survival probability
  double getExpectedMultiplierAt(double survivalProbability) {
    // If P(reach x) = p, then x = (1-houseEdge)/p
    return (1 - houseEdge) / survivalProbability;
  }
}

/// Helper class for auto-cashout settings
class AutoCashoutConfig {
  final bool enabled;
  final double targetMultiplier;
  final double? stopLossPercent;
  final double? takeProfitPercent;

  const AutoCashoutConfig({
    this.enabled = false,
    this.targetMultiplier = 2.0,
    this.stopLossPercent,
    this.takeProfitPercent,
  });
}
