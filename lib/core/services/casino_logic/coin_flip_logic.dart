import 'rng_service.dart';
import 'casino_config.dart';

/// Coin Flip logic with transparent house edge
/// True 50/50 probability, house edge via payout adjustment

enum CoinSide { heads, tails }

class CoinFlipResult {
  final CoinSide result;
  final bool playerWins;
  final double payoutMultiplier;
  final int betAmount;

  CoinFlipResult({
    required this.result,
    required this.playerWins,
    required this.payoutMultiplier,
    this.betAmount = 0,
  });

  /// Alias for playerWins (UI compatibility)
  bool get won => playerWins;

  /// Calculate payout amount
  int get payout => won ? (betAmount * payoutMultiplier).round() : 0;
}

class CoinFlipLogic {
  final CasinoRng _rng;
  final double houseEdge;

  CoinFlipLogic({
    CasinoRng? rng,
    this.houseEdge = CasinoConfig.coinFlipHouseEdge,
  }) : _rng = rng ?? CasinoRng.instance;

  /// Get payout multiplier (displayed to user for transparency)
  /// For 2% house edge: 2.0 * 0.98 = 1.96
  double get payoutMultiplier => 2.0 * (1 - houseEdge);

  /// Display payout string (e.g., "1.96x")
  String get payoutDisplay => '${payoutMultiplier.toStringAsFixed(2)}x';

  /// Flip the coin - true 50/50 probability
  CoinSide flip() {
    return _rng.nextBool() ? CoinSide.heads : CoinSide.tails;
  }

  /// Play a round
  CoinFlipResult play(CoinSide playerChoice, {int betAmount = 0}) {
    final result = flip();
    final playerWins = result == playerChoice;

    return CoinFlipResult(
      result: result,
      playerWins: playerWins,
      payoutMultiplier: playerWins ? payoutMultiplier : 0,
      betAmount: betAmount,
    );
  }

  /// Calculate payout
  /// If win: bet * payoutMultiplier (includes original bet)
  /// If lose: 0
  int calculatePayout(int betAmount, CoinFlipResult result) {
    if (!result.playerWins) return 0;
    return (betAmount * result.payoutMultiplier).round();
  }

  /// Calculate net winnings
  int calculateWinnings(int betAmount, CoinFlipResult result) {
    return calculatePayout(betAmount, result) - betAmount;
  }

  /// Simulate n flips and return observed RTP
  double simulateRtp(int numFlips) {
    int totalBet = 0;
    int totalReturn = 0;
    const betAmount = 100;

    for (int i = 0; i < numFlips; i++) {
      totalBet += betAmount;
      final result = play(CoinSide.heads); // Always bet heads for simulation
      totalReturn += calculatePayout(betAmount, result);
    }

    return totalReturn / totalBet;
  }

  /// Get theoretical RTP
  /// 50% chance to win * payoutMultiplier = 0.5 * (2 - 2*houseEdge) = 1 - houseEdge
  double getTheoreticalRtp() {
    return 0.5 * payoutMultiplier;
  }
}
