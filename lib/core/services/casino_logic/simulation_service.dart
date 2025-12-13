import 'casino_config.dart';
import 'rng_service.dart';
import 'roulette_logic.dart';
import 'blackjack_logic.dart';
import 'slot_logic.dart';
import 'coin_flip_logic.dart';
import 'horse_race_logic.dart';
import 'aviator_logic.dart';

/// Simulation service for testing and verifying casino odds
/// Provides batch simulation capabilities for each game

class SimulationResult {
  final String gameName;
  final int numSimulations;
  final double observedRtp;
  final double theoreticalRtp;
  final double rtpDifference;
  final Duration elapsed;
  final Map<String, dynamic>? additionalStats;

  SimulationResult({
    required this.gameName,
    required this.numSimulations,
    required this.observedRtp,
    required this.theoreticalRtp,
    required this.elapsed,
    this.additionalStats,
  }) : rtpDifference = (observedRtp - theoreticalRtp).abs();

  double get observedHouseEdge => 1 - observedRtp;
  double get theoreticalHouseEdge => 1 - theoreticalRtp;

  bool get withinTolerance => rtpDifference < 0.02; // 2% tolerance

  @override
  String toString() {
    return '''
$gameName Simulation Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Simulations: $numSimulations
Observed RTP: ${(observedRtp * 100).toStringAsFixed(2)}%
Theoretical RTP: ${(theoreticalRtp * 100).toStringAsFixed(2)}%
Difference: ${(rtpDifference * 100).toStringAsFixed(2)}%
House Edge: ${(observedHouseEdge * 100).toStringAsFixed(2)}%
Status: ${withinTolerance ? '✓ Within tolerance' : '✗ Outside tolerance'}
Time: ${elapsed.inMilliseconds}ms
''';
  }
}

class CasinoSimulationService {
  final int? seed;
  late final CasinoRng _rng;

  CasinoSimulationService({this.seed}) {
    _rng = seed != null ? CasinoRng.seeded(seed!) : CasinoRng.instance;
  }

  /// Simulate roulette
  Future<SimulationResult> simulateRoulette({
    int numSimulations = 10000,
    RouletteBetType betType = RouletteBetType.red,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = RouletteLogic(rng: _rng);

    final observedRtp = logic.simulateRtp(betType, numSimulations);
    final theoreticalRtp = logic.getTheoreticalRtp(betType);

    stopwatch.stop();

    return SimulationResult(
      gameName: 'Roulette (${betType.name})',
      numSimulations: numSimulations,
      observedRtp: observedRtp,
      theoreticalRtp: theoreticalRtp,
      elapsed: stopwatch.elapsed,
      additionalStats: {'betType': betType.name},
    );
  }

  /// Simulate blackjack with basic strategy
  Future<SimulationResult> simulateBlackjack({
    int numSimulations = 10000,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = BlackjackLogic(rng: _rng);

    final observedRtp = logic.simulateRtp(numSimulations);
    const theoreticalRtp = CasinoConfig.blackjackTheoreticalRtp;

    stopwatch.stop();

    return SimulationResult(
      gameName: 'Blackjack',
      numSimulations: numSimulations,
      observedRtp: observedRtp,
      theoreticalRtp: theoreticalRtp,
      elapsed: stopwatch.elapsed,
    );
  }

  /// Simulate slot machine
  Future<SimulationResult> simulateSlots({int numSimulations = 10000}) async {
    final stopwatch = Stopwatch()..start();
    final logic = SlotLogic(rng: _rng);

    final observedRtp = logic.simulateRtp(numSimulations);
    final theoreticalRtp = CasinoConfig.slotTargetRtp;

    stopwatch.stop();

    return SimulationResult(
      gameName: 'Slot Machine',
      numSimulations: numSimulations,
      observedRtp: observedRtp,
      theoreticalRtp: theoreticalRtp,
      elapsed: stopwatch.elapsed,
    );
  }

  /// Simulate coin flip
  Future<SimulationResult> simulateCoinFlip({
    int numSimulations = 10000,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = CoinFlipLogic(rng: _rng);

    final observedRtp = logic.simulateRtp(numSimulations);
    final theoreticalRtp = logic.getTheoreticalRtp();

    stopwatch.stop();

    return SimulationResult(
      gameName: 'Coin Flip',
      numSimulations: numSimulations,
      observedRtp: observedRtp,
      theoreticalRtp: theoreticalRtp,
      elapsed: stopwatch.elapsed,
    );
  }

  /// Simulate horse race
  Future<SimulationResult> simulateHorseRace({
    int numSimulations = 10000,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = HorseRaceLogic(rng: _rng);

    final observedRtp = logic.simulateRtp(numSimulations);
    final theoreticalRtp = logic.getTheoreticalRtp();

    stopwatch.stop();

    return SimulationResult(
      gameName: 'Horse Race',
      numSimulations: numSimulations,
      observedRtp: observedRtp,
      theoreticalRtp: theoreticalRtp,
      elapsed: stopwatch.elapsed,
    );
  }

  /// Simulate aviator
  Future<SimulationResult> simulateAviator({
    int numSimulations = 10000,
    double targetCashout = 2.0,
  }) async {
    final stopwatch = Stopwatch()..start();
    final logic = AviatorLogic(rng: _rng);

    final observedRtp = logic.simulateRtp(numSimulations, targetCashout);
    final theoreticalRtp = logic.getTheoreticalRtp(targetCashout);

    stopwatch.stop();

    return SimulationResult(
      gameName: 'Aviator (${targetCashout}x)',
      numSimulations: numSimulations,
      observedRtp: observedRtp,
      theoreticalRtp: theoreticalRtp,
      elapsed: stopwatch.elapsed,
      additionalStats: {'targetCashout': targetCashout},
    );
  }

  /// Run all simulations
  Future<List<SimulationResult>> runAllSimulations({
    int numSimulations = 10000,
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

  /// Generate summary report
  Future<String> generateReport({int numSimulations = 10000}) async {
    final results = await runAllSimulations(numSimulations: numSimulations);

    final buffer = StringBuffer();
    buffer.writeln('╔═══════════════════════════════════════════╗');
    buffer.writeln('║     CASINO RTP SIMULATION REPORT          ║');
    buffer.writeln('╠═══════════════════════════════════════════╣');
    buffer.writeln('║ Simulations per game: $numSimulations');
    buffer.writeln('╠═══════════════════════════════════════════╣');

    for (final result in results) {
      final status = result.withinTolerance ? '✓' : '✗';
      buffer.writeln(
        '║ $status ${result.gameName.padRight(20)} '
        'RTP: ${(result.observedRtp * 100).toStringAsFixed(1)}% '
        '(${(result.theoreticalRtp * 100).toStringAsFixed(1)}%)',
      );
    }

    buffer.writeln('╚═══════════════════════════════════════════╝');

    return buffer.toString();
  }
}

/// Quick verification helper
Future<void> verifyCasinoOdds({int simulations = 10000}) async {
  final service = CasinoSimulationService(seed: 42);
  print(await service.generateReport(numSimulations: simulations));
}
