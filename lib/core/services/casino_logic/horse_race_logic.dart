import 'rng_service.dart';
import 'casino_config.dart';

/// Horse Race logic with weighted probabilities
/// Each horse has a weight determining win probability
/// Payout reflects odds (lower probability = higher payout)

class Horse {
  final int id;
  final String name;
  final int weight;
  final int colorValue;

  const Horse({
    required this.id,
    required this.name,
    required this.weight,
    required this.colorValue,
  });

  /// Calculate win probability given total weight
  double winProbability(int totalWeight) {
    return weight / totalWeight;
  }

  /// Calculate payout multiplier with house edge
  /// Fair odds = 1/probability, then reduce by house edge
  double payoutMultiplier(int totalWeight, double houseEdge) {
    final prob = winProbability(totalWeight);
    final fairOdds = 1 / prob;
    return fairOdds * (1 - houseEdge);
  }
}

class HorseRaceResult {
  final int winnerIndex;
  final Horse winner;
  final bool playerWins;
  final double payoutMultiplier;
  final List<double> finalPositions; // For animation (0.0 to 1.0 per horse)

  HorseRaceResult({
    required this.winnerIndex,
    required this.winner,
    required this.playerWins,
    required this.payoutMultiplier,
    required this.finalPositions,
  });
}

class HorseRaceLogic {
  final CasinoRng _rng;
  final double houseEdge;
  late List<Horse> horses;
  late int totalWeight;

  HorseRaceLogic({
    CasinoRng? rng,
    this.houseEdge = CasinoConfig.horseRaceHouseEdge,
  }) : _rng = rng ?? CasinoRng.instance {
    _initHorses();
  }

  void _initHorses() {
    horses = [];
    totalWeight = 0;

    CasinoConfig.horseConfigs.forEach((id, config) {
      horses.add(
        Horse(
          id: id,
          name: config.name,
          weight: config.weight,
          colorValue: config.color,
        ),
      );
      totalWeight += config.weight;
    });
  }

  /// Get horse by index
  Horse getHorse(int index) => horses[index];

  /// Get payout multiplier for a horse
  double getPayoutMultiplier(int horseIndex) {
    return horses[horseIndex].payoutMultiplier(totalWeight, houseEdge);
  }

  /// Get odds display string (e.g., "2.5x")
  String getOddsDisplay(int horseIndex) {
    return '${getPayoutMultiplier(horseIndex).toStringAsFixed(1)}x';
  }

  /// Get win probability for a horse
  double getWinProbability(int horseIndex) {
    return horses[horseIndex].winProbability(totalWeight);
  }

  /// Get probability display string (e.g., "25%")
  String getProbabilityDisplay(int horseIndex) {
    return '${(getWinProbability(horseIndex) * 100).toStringAsFixed(0)}%';
  }

  /// Run the race and determine winner
  HorseRaceResult race(int? selectedHorse) {
    // Select winner using weighted random
    final weights = <int, double>{};
    for (int i = 0; i < horses.length; i++) {
      weights[i] = horses[i].weight.toDouble();
    }
    final winnerIndex = _rng.selectWeighted(weights);
    final winner = horses[winnerIndex];

    // Generate final positions for animation
    // Winner is at 1.0, others are distributed randomly behind
    final positions = List<double>.filled(horses.length, 0);
    positions[winnerIndex] = 1.0;

    for (int i = 0; i < horses.length; i++) {
      if (i != winnerIndex) {
        // Random position between 0.6 and 0.99
        positions[i] = 0.6 + _rng.nextDouble() * 0.39;
      }
    }

    final playerWins = selectedHorse == winnerIndex;
    final payout = playerWins ? getPayoutMultiplier(selectedHorse!) : 0.0;

    return HorseRaceResult(
      winnerIndex: winnerIndex,
      winner: winner,
      playerWins: playerWins,
      payoutMultiplier: payout,
      finalPositions: positions,
    );
  }

  /// Calculate payout
  int calculatePayout(int betAmount, HorseRaceResult result) {
    if (!result.playerWins) return 0;
    return (betAmount * result.payoutMultiplier).round();
  }

  /// Calculate net winnings
  int calculateWinnings(int betAmount, HorseRaceResult result) {
    return calculatePayout(betAmount, result) - betAmount;
  }

  /// Simulate n races and return observed RTP
  /// Simulates betting on each horse proportionally
  double simulateRtp(int numRaces) {
    int totalBet = 0;
    int totalReturn = 0;
    const betAmount = 100;

    for (int i = 0; i < numRaces; i++) {
      // For simulation, always bet on horse 0 (favorite)
      totalBet += betAmount;
      final result = race(0);
      totalReturn += calculatePayout(betAmount, result);
    }

    return totalReturn / totalBet;
  }

  /// Get theoretical RTP
  /// For any horse: P(win) * payout = P(win) * (1/P(win)) * (1-houseEdge) = 1 - houseEdge
  double getTheoreticalRtp() {
    return 1 - houseEdge;
  }
}
