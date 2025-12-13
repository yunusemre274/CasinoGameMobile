import 'rng_service.dart';
import 'casino_config.dart';

/// European Roulette Logic
/// 37 numbers (0-36), single zero
/// House edge arises naturally from zero

enum RouletteBetType {
  single, // Single number: 35:1
  red, // Red: 1:1
  black, // Black: 1:1
  odd, // Odd: 1:1
  even, // Even: 1:1
  low, // 1-18: 1:1
  high, // 19-36: 1:1
  dozen1, // 1-12: 2:1
  dozen2, // 13-24: 2:1
  dozen3, // 25-36: 2:1
  column1, // 1,4,7,10..34: 2:1
  column2, // 2,5,8,11..35: 2:1
  column3, // 3,6,9,12..36: 2:1
  green, // 0 only: 35:1 (same as single)
}

class RouletteBet {
  final RouletteBetType type;
  final int? number; // Only for single number bets
  final int amount;

  RouletteBet({required this.type, this.number, required this.amount});

  /// Get payout multiplier for this bet type
  int get payoutMultiplier {
    switch (type) {
      case RouletteBetType.single:
      case RouletteBetType.green:
        return CasinoConfig.rouletteSingleNumberPayout;
      case RouletteBetType.red:
      case RouletteBetType.black:
      case RouletteBetType.odd:
      case RouletteBetType.even:
      case RouletteBetType.low:
      case RouletteBetType.high:
        return CasinoConfig.rouletteColorPayout;
      case RouletteBetType.dozen1:
      case RouletteBetType.dozen2:
      case RouletteBetType.dozen3:
      case RouletteBetType.column1:
      case RouletteBetType.column2:
      case RouletteBetType.column3:
        return CasinoConfig.rouletteDozenPayout;
    }
  }
}

class RouletteResult {
  final int number;
  final String color; // 'red', 'black', 'green'
  final bool isOdd;
  final bool isLow; // 1-18
  final int dozen; // 1, 2, or 3 (0 for zero)
  final int column; // 1, 2, or 3 (0 for zero)
  final List<RouletteBet> bets;
  final int totalBetAmount;
  int _calculatedPayout = 0;

  RouletteResult({
    required this.number,
    required this.color,
    required this.isOdd,
    required this.isLow,
    required this.dozen,
    required this.column,
    this.bets = const [],
    this.totalBetAmount = 0,
  });

  /// Whether the player won any bet
  bool get won => _calculatedPayout > 0;

  /// Total payout for all bets
  int get payout => _calculatedPayout;

  /// Set calculated payout (called by logic after evaluating bets)
  void setPayout(int value) {
    _calculatedPayout = value;
  }
}

class RouletteLogic {
  final CasinoRng _rng;

  RouletteLogic({CasinoRng? rng}) : _rng = rng ?? CasinoRng.instance;

  /// European roulette wheel order (for animation reference)
  static const List<int> wheelOrder = [
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

  /// Red numbers in European roulette
  static const Set<int> redNumbers = {
    1,
    3,
    5,
    7,
    9,
    12,
    14,
    16,
    18,
    19,
    21,
    23,
    25,
    27,
    30,
    32,
    34,
    36,
  };

  /// Black numbers (all non-red, non-zero)
  static Set<int> get blackNumbers {
    return {
      for (int i = 1; i <= 36; i++)
        if (!redNumbers.contains(i)) i,
    };
  }

  /// Get color for a number
  static String getColor(int number) {
    if (number == 0) return 'green';
    return redNumbers.contains(number) ? 'red' : 'black';
  }

  /// Alias for getColor (UI compatibility)
  static String getNumberColor(int number) => getColor(number);

  /// Spin the wheel and get result
  RouletteResult spin([RouletteBet? bet]) {
    final number = _rng.nextInt(37); // 0-36
    final result = _createResult(number, bet);

    // Calculate payout if a bet was provided
    if (bet != null) {
      final payout = calculatePayout(bet, result);
      result.setPayout(payout);
    }

    return result;
  }

  /// Create result from number
  RouletteResult _createResult(int number, [RouletteBet? bet]) {
    return RouletteResult(
      number: number,
      color: getColor(number),
      isOdd: number > 0 && number % 2 == 1,
      isLow: number >= 1 && number <= 18,
      dozen: number == 0 ? 0 : ((number - 1) ~/ 12) + 1,
      column: number == 0 ? 0 : ((number - 1) % 3) + 1,
      bets: bet != null ? [bet] : const [],
      totalBetAmount: bet?.amount ?? 0,
    );
  }

  /// Check if bet wins against result
  bool checkWin(RouletteBet bet, RouletteResult result) {
    switch (bet.type) {
      case RouletteBetType.single:
        return result.number == bet.number;
      case RouletteBetType.green:
        return result.number == 0;
      case RouletteBetType.red:
        return result.color == 'red';
      case RouletteBetType.black:
        return result.color == 'black';
      case RouletteBetType.odd:
        return result.number > 0 && result.isOdd;
      case RouletteBetType.even:
        return result.number > 0 && !result.isOdd;
      case RouletteBetType.low:
        return result.isLow;
      case RouletteBetType.high:
        return result.number >= 19 && result.number <= 36;
      case RouletteBetType.dozen1:
        return result.dozen == 1;
      case RouletteBetType.dozen2:
        return result.dozen == 2;
      case RouletteBetType.dozen3:
        return result.dozen == 3;
      case RouletteBetType.column1:
        return result.column == 1;
      case RouletteBetType.column2:
        return result.column == 2;
      case RouletteBetType.column3:
        return result.column == 3;
    }
  }

  /// Calculate payout for a winning bet
  /// Returns total return (bet + winnings)
  int calculatePayout(RouletteBet bet, RouletteResult result) {
    if (!checkWin(bet, result)) return 0;
    return bet.amount + (bet.amount * bet.payoutMultiplier);
  }

  /// Calculate net winnings (payout - bet)
  int calculateWinnings(RouletteBet bet, RouletteResult result) {
    if (!checkWin(bet, result)) return -bet.amount;
    return bet.amount * bet.payoutMultiplier;
  }

  /// Simulate n spins with a bet type and return observed RTP
  double simulateRtp(
    RouletteBetType betType,
    int numSpins, {
    int? singleNumber,
  }) {
    int totalBet = 0;
    int totalReturn = 0;
    const betAmount = 100;

    for (int i = 0; i < numSpins; i++) {
      final bet = RouletteBet(
        type: betType,
        number: singleNumber,
        amount: betAmount,
      );
      totalBet += betAmount;

      final result = spin();
      totalReturn += calculatePayout(bet, result);
    }

    return totalReturn / totalBet;
  }

  /// Get theoretical RTP for a bet type
  double getTheoreticalRtp(RouletteBetType betType) {
    // For European roulette with 37 numbers
    switch (betType) {
      case RouletteBetType.single:
      case RouletteBetType.green:
        // 1/37 chance to win, pays 35:1
        return (1 / 37) * 36; // 36/37 ≈ 0.973
      case RouletteBetType.red:
      case RouletteBetType.black:
        // 18/37 chance to win, pays 1:1
        return (18 / 37) * 2; // 36/37 ≈ 0.973
      case RouletteBetType.odd:
      case RouletteBetType.even:
      case RouletteBetType.low:
      case RouletteBetType.high:
        return (18 / 37) * 2; // 36/37 ≈ 0.973
      case RouletteBetType.dozen1:
      case RouletteBetType.dozen2:
      case RouletteBetType.dozen3:
      case RouletteBetType.column1:
      case RouletteBetType.column2:
      case RouletteBetType.column3:
        // 12/37 chance to win, pays 2:1
        return (12 / 37) * 3; // 36/37 ≈ 0.973
    }
  }
}
