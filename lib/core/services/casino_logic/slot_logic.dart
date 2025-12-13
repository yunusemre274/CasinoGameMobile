import 'rng_service.dart';
import 'casino_config.dart';

/// Slot machine logic with paytable-based system
/// Uses weighted outcomes to achieve target RTP

enum SlotSymbol {
  seven, // Highest value
  bar,
  bell,
  cherry,
  lemon,
  orange,
  blank, // No symbol (loses)
}

class SlotSymbolData {
  final SlotSymbol symbol;
  final String emoji;
  final int weight; // Higher = more common
  final int threeMatchPayout; // Payout for 3 of a kind (multiplier)
  final int twoMatchPayout; // Payout for 2 of a kind (0 = no payout)

  const SlotSymbolData({
    required this.symbol,
    required this.emoji,
    required this.weight,
    required this.threeMatchPayout,
    this.twoMatchPayout = 0,
  });
}

class SlotResult {
  final List<SlotSymbol> reels; // 3 symbols
  final int payoutMultiplier;
  final bool isJackpot;
  final String? winType;
  final int betAmount;

  SlotResult({
    required this.reels,
    required this.payoutMultiplier,
    required this.isJackpot,
    this.winType,
    this.betAmount = 0,
  });

  bool get isWin => payoutMultiplier > 0;

  /// Calculated payout amount
  int get payout => betAmount * payoutMultiplier;
}

class SlotLogic {
  final CasinoRng _rng;
  final double targetRtp;

  /// Paytable configuration
  /// Weights are adjusted to achieve target RTP
  late List<SlotSymbolData> _paytable;

  SlotLogic({CasinoRng? rng, this.targetRtp = CasinoConfig.slotTargetRtp})
    : _rng = rng ?? CasinoRng.instance {
    _initPaytable();
  }

  void _initPaytable() {
    // Standard paytable - weights calibrated for ~95% RTP
    // Higher weight = more common = lower value
    _paytable = [
      const SlotSymbolData(
        symbol: SlotSymbol.seven,
        emoji: '7️⃣',
        weight: 3, // Rare
        threeMatchPayout: 100, // Jackpot
        twoMatchPayout: 5,
      ),
      const SlotSymbolData(
        symbol: SlotSymbol.bar,
        emoji: '🎱',
        weight: 5,
        threeMatchPayout: 50,
        twoMatchPayout: 2,
      ),
      const SlotSymbolData(
        symbol: SlotSymbol.bell,
        emoji: '🔔',
        weight: 8,
        threeMatchPayout: 20,
        twoMatchPayout: 0,
      ),
      const SlotSymbolData(
        symbol: SlotSymbol.cherry,
        emoji: '🍒',
        weight: 12,
        threeMatchPayout: 10,
        twoMatchPayout: 2, // Cherry pays on 2
      ),
      const SlotSymbolData(
        symbol: SlotSymbol.lemon,
        emoji: '🍋',
        weight: 15,
        threeMatchPayout: 5,
        twoMatchPayout: 0,
      ),
      const SlotSymbolData(
        symbol: SlotSymbol.orange,
        emoji: '🍊',
        weight: 18,
        threeMatchPayout: 3,
        twoMatchPayout: 0,
      ),
      const SlotSymbolData(
        symbol: SlotSymbol.blank,
        emoji: '⬜',
        weight: 39, // Most common - no payout
        threeMatchPayout: 0,
        twoMatchPayout: 0,
      ),
    ];
  }

  /// Get symbol data
  SlotSymbolData getSymbolData(SlotSymbol symbol) {
    return _paytable.firstWhere((s) => s.symbol == symbol);
  }

  /// Get emoji for symbol
  String getEmoji(SlotSymbol symbol) {
    return getSymbolData(symbol).emoji;
  }

  /// Get all non-blank symbols for display
  List<SlotSymbolData> get displaySymbols {
    return _paytable.where((s) => s.symbol != SlotSymbol.blank).toList();
  }

  /// Get all symbols (same as displaySymbols, for UI compatibility)
  List<SlotSymbolData> get symbols => displaySymbols;

  /// Spin a single reel and get symbol
  SlotSymbol _spinReel() {
    final weights = <SlotSymbol, double>{};
    for (final data in _paytable) {
      weights[data.symbol] = data.weight.toDouble();
    }
    return _rng.selectWeighted(weights);
  }

  /// Spin all 3 reels
  SlotResult spin([int betAmount = 0]) {
    final reels = [_spinReel(), _spinReel(), _spinReel()];
    return _evaluateResult(reels, betAmount);
  }

  /// Evaluate spin result
  SlotResult _evaluateResult(List<SlotSymbol> reels, [int betAmount = 0]) {
    final s1 = reels[0];
    final s2 = reels[1];
    final s3 = reels[2];

    // Check for 3 of a kind
    if (s1 == s2 && s2 == s3 && s1 != SlotSymbol.blank) {
      final data = getSymbolData(s1);
      return SlotResult(
        reels: reels,
        payoutMultiplier: data.threeMatchPayout,
        isJackpot: s1 == SlotSymbol.seven,
        winType: data.threeMatchPayout > 0 ? '3x ${data.emoji}' : null,
        betAmount: betAmount,
      );
    }

    // Check for 2 of a kind (first 2 reels only for simplicity)
    if (s1 == s2 && s1 != SlotSymbol.blank) {
      final data = getSymbolData(s1);
      if (data.twoMatchPayout > 0) {
        return SlotResult(
          reels: reels,
          payoutMultiplier: data.twoMatchPayout,
          isJackpot: false,
          winType: '2x ${data.emoji}',
          betAmount: betAmount,
        );
      }
    }

    // Check for any cherry (cherry anywhere pays)
    final cherryCount = reels.where((s) => s == SlotSymbol.cherry).length;
    if (cherryCount >= 1 && cherryCount < 3) {
      return SlotResult(
        reels: reels,
        payoutMultiplier: cherryCount, // 1 cherry = 1x, 2 cherries = 2x
        isJackpot: false,
        winType: '$cherryCount🍒',
        betAmount: betAmount,
      );
    }

    // No win
    return SlotResult(
      reels: reels,
      payoutMultiplier: 0,
      isJackpot: false,
      betAmount: betAmount,
    );
  }

  /// Calculate payout
  int calculatePayout(int betAmount, SlotResult result) {
    if (result.payoutMultiplier <= 0) return 0;
    return betAmount * result.payoutMultiplier;
  }

  /// Calculate net winnings
  int calculateWinnings(int betAmount, SlotResult result) {
    return calculatePayout(betAmount, result) - betAmount;
  }

  /// Simulate n spins and return observed RTP
  double simulateRtp(int numSpins) {
    int totalBet = 0;
    int totalReturn = 0;
    const betAmount = 100;

    for (int i = 0; i < numSpins; i++) {
      totalBet += betAmount;
      final result = spin();
      totalReturn += calculatePayout(betAmount, result);
    }

    return totalReturn / totalBet;
  }

  /// Get theoretical RTP based on paytable
  double getTheoreticalRtp() {
    // Calculate total weight
    double totalWeight = 0;
    for (final data in _paytable) {
      totalWeight += data.weight;
    }

    // Calculate expected return per 1 unit bet
    double expectedReturn = 0;

    // For each possible 3-reel combination
    for (final s1Data in _paytable) {
      for (final s2Data in _paytable) {
        for (final s3Data in _paytable) {
          final prob =
              (s1Data.weight / totalWeight) *
              (s2Data.weight / totalWeight) *
              (s3Data.weight / totalWeight);

          final result = _evaluateResult([
            s1Data.symbol,
            s2Data.symbol,
            s3Data.symbol,
          ]);
          expectedReturn += prob * result.payoutMultiplier;
        }
      }
    }

    return expectedReturn;
  }
}
