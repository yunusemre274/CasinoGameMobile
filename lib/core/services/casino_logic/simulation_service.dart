import 'dart:math';
import 'casino_config.dart';
import 'rng_service.dart';
import 'roulette_logic.dart';
import 'blackjack_logic.dart';
import 'slot_logic.dart';
import 'coin_flip_logic.dart';
import 'horse_race_logic.dart';
import 'aviator_logic.dart';

/// =============================================================================
/// RTP SIMULATION SERVICE - Statistically Correct Casino Odds Verification
/// =============================================================================
///
/// DEFINITIONS:
/// - RTP (Return To Player) = totalReturnedToPlayer / totalBetPlaced
/// - totalReturnedToPlayer includes: all payouts + stake returns on push + cashouts
/// - Variance = statistical spread of outcomes (risk indicator)
/// - RTP ≠ Variance: High RTP can still have high variance (risky feel)
///
/// This service uses a DEDICATED RNG instance for simulations,
/// completely separate from gameplay RNG to ensure:
/// 1. Gameplay randomness is never affected by simulations
/// 2. Simulations are reproducible with seeds
/// 3. Statistical validity of results

/// Comprehensive simulation result with variance metrics
class SimulationResult {
  final String gameName;
  final int numSimulations;
  final double observedRtp;
  final double theoreticalRtp;
  final double rtpDifference;
  final Duration elapsed;

  // Variance & Risk Metrics
  final double hitRate; // % of winning rounds
  final double avgWinAmount; // Average win when winning
  final double stdDeviation; // Standard deviation of returns
  final double maxDrawdown; // Worst consecutive loss streak value
  final int longestLosingStreak; // Most consecutive losses
  final int longestWinningStreak; // Most consecutive wins

  // Detailed tracking
  final int totalWins;
  final int totalLosses;
  final int totalPushes; // Ties/pushes (stake returned)
  final double netProfit; // Total profit/loss

  final Map<String, dynamic>? additionalStats;

  SimulationResult({
    required this.gameName,
    required this.numSimulations,
    required this.observedRtp,
    required this.theoreticalRtp,
    required this.elapsed,
    required this.hitRate,
    required this.avgWinAmount,
    required this.stdDeviation,
    required this.maxDrawdown,
    required this.longestLosingStreak,
    required this.longestWinningStreak,
    required this.totalWins,
    required this.totalLosses,
    required this.totalPushes,
    required this.netProfit,
    this.additionalStats,
  }) : rtpDifference = (observedRtp - theoreticalRtp).abs();

  double get observedHouseEdge => 1 - observedRtp;
  double get theoreticalHouseEdge => 1 - theoreticalRtp;

  /// Statistical tolerance based on simulation size
  /// Larger samples = tighter tolerance expected
  double get expectedTolerance {
    // 95% confidence interval approximation
    // For binomial-like outcomes: ~1.96 * sqrt(p*(1-p)/n)
    return 1.96 * sqrt(0.25 / numSimulations);
  }

  bool get withinTolerance => rtpDifference < expectedTolerance;

  /// Risk classification based on variance metrics
  String get riskLevel {
    if (stdDeviation < 0.5) return 'LOW';
    if (stdDeviation < 1.5) return 'MEDIUM';
    if (stdDeviation < 3.0) return 'HIGH';
    return 'VERY HIGH';
  }

  /// Volatility index (combines multiple risk factors)
  double get volatilityIndex {
    // Normalized volatility score 0-100
    final streakFactor = longestLosingStreak / 20.0; // Normalize to ~20 max
    final stdFactor = stdDeviation / 5.0; // Normalize to ~5 max
    final drawdownFactor = maxDrawdown.abs() / 50.0; // Normalize
    return ((streakFactor + stdFactor + drawdownFactor) / 3 * 100).clamp(
      0,
      100,
    );
  }

  @override
  String toString() {
    return '''
╔═══════════════════════════════════════════════════════════════╗
║ $gameName - SIMULATION REPORT
╠═══════════════════════════════════════════════════════════════╣
║ SAMPLE SIZE: ${_formatNumber(numSimulations)} rounds
║ TIME: ${elapsed.inMilliseconds}ms
╠═══════════════════════════════════════════════════════════════╣
║ RTP (EXPECTED VALUE)
║ ├─ Observed:    ${(observedRtp * 100).toStringAsFixed(3)}%
║ ├─ Theoretical: ${(theoreticalRtp * 100).toStringAsFixed(3)}%
║ ├─ Difference:  ${(rtpDifference * 100).toStringAsFixed(3)}%
║ ├─ Tolerance:   ±${(expectedTolerance * 100).toStringAsFixed(3)}%
║ └─ Status:      ${withinTolerance ? '✓ PASS' : '✗ FAIL'}
╠═══════════════════════════════════════════════════════════════╣
║ VARIANCE (RISK INDICATORS) - NOT RTP!
║ ├─ Hit Rate:        ${(hitRate * 100).toStringAsFixed(2)}% of rounds won
║ ├─ Avg Win Amount:  ${avgWinAmount.toStringAsFixed(2)}x bet
║ ├─ Std Deviation:   ${stdDeviation.toStringAsFixed(3)}
║ ├─ Max Drawdown:    ${maxDrawdown.toStringAsFixed(2)} units
║ ├─ Longest Loss:    $longestLosingStreak consecutive
║ ├─ Longest Win:     $longestWinningStreak consecutive
║ └─ Risk Level:      $riskLevel (Volatility: ${volatilityIndex.toStringAsFixed(1)})
╠═══════════════════════════════════════════════════════════════╣
║ OUTCOME DISTRIBUTION
║ ├─ Wins:   $totalWins (${(totalWins / numSimulations * 100).toStringAsFixed(1)}%)
║ ├─ Losses: $totalLosses (${(totalLosses / numSimulations * 100).toStringAsFixed(1)}%)
║ ├─ Pushes: $totalPushes (${(totalPushes / numSimulations * 100).toStringAsFixed(1)}%)
║ └─ Net:    ${netProfit >= 0 ? '+' : ''}${netProfit.toStringAsFixed(2)} units
╚═══════════════════════════════════════════════════════════════╝
''';
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

/// Individual round result for variance calculation
class _RoundResult {
  final double betAmount;
  final double
  returnAmount; // Total returned (0 if lost, bet if push, bet+win if won)
  final bool isWin;
  final bool isPush;

  _RoundResult({
    required this.betAmount,
    required this.returnAmount,
    required this.isWin,
    required this.isPush,
  });

  double get rtp => returnAmount / betAmount;
  double get profit => returnAmount - betAmount;
}

class CasinoSimulationService {
  final int? seed;

  /// DEDICATED RNG for simulations - completely separate from gameplay RNG
  /// This ensures simulations never affect actual gameplay randomness
  late final CasinoRng _simulationRng;

  /// Minimum recommended simulation size for statistical significance
  static const int minRecommendedSimulations = 100000;

  /// Default simulation size
  static const int defaultSimulations = 100000;

  CasinoSimulationService({this.seed}) {
    // Create a dedicated RNG instance for simulations
    // Never use CasinoRng.instance here - that's for gameplay
    _simulationRng = seed != null
        ? CasinoRng.seeded(seed!)
        : CasinoRng.seeded(DateTime.now().microsecondsSinceEpoch);
  }

  /// Calculate comprehensive statistics from round results
  SimulationResult _calculateStats({
    required String gameName,
    required List<_RoundResult> rounds,
    required double theoreticalRtp,
    required Duration elapsed,
    Map<String, dynamic>? additionalStats,
  }) {
    if (rounds.isEmpty) {
      return SimulationResult(
        gameName: gameName,
        numSimulations: 0,
        observedRtp: 0,
        theoreticalRtp: theoreticalRtp,
        elapsed: elapsed,
        hitRate: 0,
        avgWinAmount: 0,
        stdDeviation: 0,
        maxDrawdown: 0,
        longestLosingStreak: 0,
        longestWinningStreak: 0,
        totalWins: 0,
        totalLosses: 0,
        totalPushes: 0,
        netProfit: 0,
        additionalStats: additionalStats,
      );
    }

    // RTP Calculation: totalReturnedToPlayer / totalBetPlaced
    double totalBet = 0;
    double totalReturn = 0;

    int wins = 0;
    int losses = 0;
    int pushes = 0;

    double totalWinAmount = 0;

    // For variance calculation
    List<double> rtpPerRound = [];

    // For streak calculation
    int currentLosingStreak = 0;
    int currentWinningStreak = 0;
    int maxLosingStreak = 0;
    int maxWinningStreak = 0;

    // For drawdown calculation
    double runningProfit = 0;
    double peakProfit = 0;
    double maxDrawdown = 0;

    for (final round in rounds) {
      totalBet += round.betAmount;
      totalReturn += round.returnAmount;
      rtpPerRound.add(round.rtp);

      // Count outcomes
      if (round.isPush) {
        pushes++;
        // Push resets streaks
        currentLosingStreak = 0;
        currentWinningStreak = 0;
      } else if (round.isWin) {
        wins++;
        totalWinAmount += round.returnAmount;
        currentWinningStreak++;
        currentLosingStreak = 0;
        maxWinningStreak = max(maxWinningStreak, currentWinningStreak);
      } else {
        losses++;
        currentLosingStreak++;
        currentWinningStreak = 0;
        maxLosingStreak = max(maxLosingStreak, currentLosingStreak);
      }

      // Drawdown calculation
      runningProfit += round.profit;
      if (runningProfit > peakProfit) {
        peakProfit = runningProfit;
      }
      final currentDrawdown = peakProfit - runningProfit;
      if (currentDrawdown > maxDrawdown) {
        maxDrawdown = currentDrawdown;
      }
    }

    // Calculate RTP
    final observedRtp = totalReturn / totalBet;

    // Calculate hit rate
    final hitRate = wins / rounds.length;

    // Calculate average win amount (as multiplier of bet)
    final avgWinAmount = wins > 0
        ? (totalWinAmount / wins) / (totalBet / rounds.length)
        : 0.0;

    // Calculate standard deviation
    final meanRtp = rtpPerRound.reduce((a, b) => a + b) / rtpPerRound.length;
    double sumSquaredDiff = 0;
    for (final rtp in rtpPerRound) {
      sumSquaredDiff += pow(rtp - meanRtp, 2);
    }
    final stdDeviation = sqrt(sumSquaredDiff / rtpPerRound.length);

    return SimulationResult(
      gameName: gameName,
      numSimulations: rounds.length,
      observedRtp: observedRtp,
      theoreticalRtp: theoreticalRtp,
      elapsed: elapsed,
      hitRate: hitRate,
      avgWinAmount: avgWinAmount,
      stdDeviation: stdDeviation,
      maxDrawdown: maxDrawdown,
      longestLosingStreak: maxLosingStreak,
      longestWinningStreak: maxWinningStreak,
      totalWins: wins,
      totalLosses: losses,
      totalPushes: pushes,
      netProfit: runningProfit,
      additionalStats: additionalStats,
    );
  }

  /// Simulate roulette with full variance tracking
  Future<SimulationResult> simulateRoulette({
    int numSimulations = defaultSimulations,
    RouletteBetType betType = RouletteBetType.red,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = RouletteLogic(rng: _simulationRng);

    const betAmount = 100.0;
    final rounds = <_RoundResult>[];

    for (int i = 0; i < numSimulations; i++) {
      final bet = RouletteBet(type: betType, amount: betAmount.toInt());
      final result = logic.spin();
      final payout = logic.calculatePayout(bet, result);

      rounds.add(
        _RoundResult(
          betAmount: betAmount,
          returnAmount: payout.toDouble(),
          isWin: payout > 0,
          isPush: false, // Roulette has no push
        ),
      );
    }

    stopwatch.stop();

    return _calculateStats(
      gameName: 'Roulette (${betType.name})',
      rounds: rounds,
      theoreticalRtp: logic.getTheoreticalRtp(betType),
      elapsed: stopwatch.elapsed,
      additionalStats: {'betType': betType.name},
    );
  }

  /// Simulate blackjack with basic strategy and push tracking
  Future<SimulationResult> simulateBlackjack({
    int numSimulations = defaultSimulations,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = BlackjackLogic(rng: _simulationRng);

    const betAmount = 100.0;
    final rounds = <_RoundResult>[];

    for (int i = 0; i < numSimulations; i++) {
      logic.newRound();

      // Simple strategy: hit until 17+
      while (logic.playerHand.value < 17 && logic.playerHand.canHit) {
        logic.playerHit();
      }

      if (!logic.playerHand.isBust) {
        logic.dealerPlay();
      }

      final result = logic.determineOutcome(betAmount: betAmount.toInt());
      final payout = logic.calculatePayout(betAmount.toInt(), result);

      // Blackjack push: bet is returned, not won or lost
      final isPush =
          result.payoutMultiplier == 0.0 &&
          result.outcome == BlackjackOutcome.push;

      rounds.add(
        _RoundResult(
          betAmount: betAmount,
          returnAmount: payout.toDouble(),
          isWin: result.payoutMultiplier > 0,
          isPush: isPush,
        ),
      );
    }

    stopwatch.stop();

    return _calculateStats(
      gameName: 'Blackjack',
      rounds: rounds,
      theoreticalRtp: CasinoConfig.blackjackTheoreticalRtp,
      elapsed: stopwatch.elapsed,
    );
  }

  /// Simulate slot machine
  Future<SimulationResult> simulateSlots({
    int numSimulations = defaultSimulations,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = SlotLogic(rng: _simulationRng);

    const betAmount = 100.0;
    final rounds = <_RoundResult>[];

    for (int i = 0; i < numSimulations; i++) {
      final result = logic.spin();
      final payout = logic.calculatePayout(betAmount.toInt(), result);

      rounds.add(
        _RoundResult(
          betAmount: betAmount,
          returnAmount: payout.toDouble(),
          isWin: payout > 0,
          isPush: false,
        ),
      );
    }

    stopwatch.stop();

    return _calculateStats(
      gameName: 'Slot Machine',
      rounds: rounds,
      theoreticalRtp: CasinoConfig.slotTargetRtp,
      elapsed: stopwatch.elapsed,
    );
  }

  /// Simulate coin flip
  Future<SimulationResult> simulateCoinFlip({
    int numSimulations = defaultSimulations,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = CoinFlipLogic(rng: _simulationRng);

    const betAmount = 100.0;
    final rounds = <_RoundResult>[];

    for (int i = 0; i < numSimulations; i++) {
      final result = logic.play(CoinSide.heads);
      final payout = logic.calculatePayout(betAmount.toInt(), result);

      rounds.add(
        _RoundResult(
          betAmount: betAmount,
          returnAmount: payout.toDouble(),
          isWin: result.playerWins,
          isPush: false,
        ),
      );
    }

    stopwatch.stop();

    return _calculateStats(
      gameName: 'Coin Flip',
      rounds: rounds,
      theoreticalRtp: logic.getTheoreticalRtp(),
      elapsed: stopwatch.elapsed,
    );
  }

  /// Simulate horse race
  Future<SimulationResult> simulateHorseRace({
    int numSimulations = defaultSimulations,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = HorseRaceLogic(rng: _simulationRng);

    const betAmount = 100.0;
    final rounds = <_RoundResult>[];

    for (int i = 0; i < numSimulations; i++) {
      // Bet on favorite (horse 0) for consistent testing
      final result = logic.race(0);
      final payout = logic.calculatePayout(betAmount.toInt(), result);

      rounds.add(
        _RoundResult(
          betAmount: betAmount,
          returnAmount: payout.toDouble(),
          isWin: result.playerWins,
          isPush: false,
        ),
      );
    }

    stopwatch.stop();

    return _calculateStats(
      gameName: 'Horse Race',
      rounds: rounds,
      theoreticalRtp: logic.getTheoreticalRtp(),
      elapsed: stopwatch.elapsed,
    );
  }

  /// Simulate aviator with cashout strategy
  Future<SimulationResult> simulateAviator({
    int numSimulations = defaultSimulations,
    double targetCashout = 2.0,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = AviatorLogic(rng: _simulationRng);

    const betAmount = 100.0;
    final rounds = <_RoundResult>[];

    for (int i = 0; i < numSimulations; i++) {
      final crashPoint = _simulationRng.generateCrashPoint(logic.houseEdge);
      final won = crashPoint >= targetCashout;

      // Cashout returns bet * multiplier if won, 0 if crashed
      final returnAmount = won ? betAmount * targetCashout : 0.0;

      rounds.add(
        _RoundResult(
          betAmount: betAmount,
          returnAmount: returnAmount,
          isWin: won,
          isPush: false,
        ),
      );
    }

    stopwatch.stop();

    return _calculateStats(
      gameName: 'Aviator (${targetCashout}x)',
      rounds: rounds,
      theoreticalRtp: logic.getTheoreticalRtp(targetCashout),
      elapsed: stopwatch.elapsed,
      additionalStats: {'targetCashout': targetCashout},
    );
  }

  /// Run all simulations
  Future<List<SimulationResult>> runAllSimulations({
    int numSimulations = defaultSimulations,
  }) async {
    return [
      await simulateRoulette(numSimulations: numSimulations),
      await simulateBlackjack(numSimulations: numSimulations),
      await simulateSlots(numSimulations: numSimulations),
      await simulateCoinFlip(numSimulations: numSimulations),
      await simulateHorseRace(numSimulations: numSimulations),
      await simulateAviator(numSimulations: numSimulations),
    ];
  }

  /// Generate comprehensive summary report
  Future<String> generateReport({
    int numSimulations = defaultSimulations,
  }) async {
    final results = await runAllSimulations(numSimulations: numSimulations);

    final buffer = StringBuffer();
    buffer.writeln(
      '╔════════════════════════════════════════════════════════════════╗',
    );
    buffer.writeln(
      '║         CASINO RTP SIMULATION REPORT (CORRECTED)               ║',
    );
    buffer.writeln(
      '╠════════════════════════════════════════════════════════════════╣',
    );
    buffer.writeln(
      '║ Simulations per game: ${SimulationResult._formatNumber(numSimulations).padRight(10)}                        ║',
    );
    buffer.writeln(
      '║ Statistical confidence: 95%                                    ║',
    );
    buffer.writeln(
      '╠════════════════════════════════════════════════════════════════╣',
    );
    buffer.writeln(
      '║                                                                ║',
    );
    buffer.writeln(
      '║ IMPORTANT: RTP ≠ Risk! High RTP games can still feel risky    ║',
    );
    buffer.writeln(
      '║ due to variance. Check Risk Level for perceived risk.          ║',
    );
    buffer.writeln(
      '║                                                                ║',
    );
    buffer.writeln(
      '╠═══════════════════════════════════════════════════════════════╣',
    );

    for (final result in results) {
      final status = result.withinTolerance ? '✓' : '✗';
      buffer.writeln(
        '║ $status ${result.gameName.padRight(22)} '
        'RTP: ${(result.observedRtp * 100).toStringAsFixed(2).padLeft(6)}% '
        '(${(result.theoreticalRtp * 100).toStringAsFixed(2)}%) '
        '${result.riskLevel.padRight(6)}',
      );
    }

    buffer.writeln(
      '╠════════════════════════════════════════════════════════════════╣',
    );
    buffer.writeln(
      '║ Legend: ✓ = within tolerance, ✗ = outside tolerance           ║',
    );
    buffer.writeln(
      '║ Risk: LOW = smooth returns, HIGH = volatile swings            ║',
    );
    buffer.writeln(
      '╚════════════════════════════════════════════════════════════════╝',
    );

    return buffer.toString();
  }
}

/// Quick verification helper
Future<void> verifyCasinoOdds({int simulations = 100000}) async {
  final service = CasinoSimulationService(seed: 42);
  print(await service.generateReport(numSimulations: simulations));
}
