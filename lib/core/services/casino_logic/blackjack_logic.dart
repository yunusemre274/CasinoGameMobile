import 'rng_service.dart';
import 'casino_config.dart';

/// Blackjack game logic with proper rules
/// Standard 6-deck shoe, dealer stands on soft 17

enum CardSuit { hearts, diamonds, clubs, spades }

enum CardRank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
}

class BlackjackCard {
  final CardSuit suit;
  final CardRank rank;

  const BlackjackCard({required this.suit, required this.rank});

  /// Positional constructor (for backward compatibility)
  factory BlackjackCard.positional(CardSuit suit, CardRank rank) {
    return BlackjackCard(suit: suit, rank: rank);
  }

  /// Get card value (Ace = 11, face cards = 10)
  int get baseValue {
    switch (rank) {
      case CardRank.ace:
        return 11;
      case CardRank.two:
        return 2;
      case CardRank.three:
        return 3;
      case CardRank.four:
        return 4;
      case CardRank.five:
        return 5;
      case CardRank.six:
        return 6;
      case CardRank.seven:
        return 7;
      case CardRank.eight:
        return 8;
      case CardRank.nine:
        return 9;
      case CardRank.ten:
      case CardRank.jack:
      case CardRank.queen:
      case CardRank.king:
        return 10;
    }
  }

  bool get isAce => rank == CardRank.ace;

  /// Alias for baseValue for UI compatibility
  int get value => baseValue;

  String get rankString {
    switch (rank) {
      case CardRank.ace:
        return 'A';
      case CardRank.two:
        return '2';
      case CardRank.three:
        return '3';
      case CardRank.four:
        return '4';
      case CardRank.five:
        return '5';
      case CardRank.six:
        return '6';
      case CardRank.seven:
        return '7';
      case CardRank.eight:
        return '8';
      case CardRank.nine:
        return '9';
      case CardRank.ten:
        return '10';
      case CardRank.jack:
        return 'J';
      case CardRank.queen:
        return 'Q';
      case CardRank.king:
        return 'K';
    }
  }

  String get suitString {
    switch (suit) {
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
      case CardSuit.spades:
        return '♠';
    }
  }

  bool get isRed => suit == CardSuit.hearts || suit == CardSuit.diamonds;

  @override
  String toString() => '$rankString$suitString';
}

class BlackjackHand {
  final List<BlackjackCard> cards = [];

  void addCard(BlackjackCard card) {
    cards.add(card);
  }

  void clear() {
    cards.clear();
  }

  /// Calculate best hand value (adjusting aces as needed)
  int get value {
    int total = 0;
    int aces = 0;

    for (final card in cards) {
      total += card.baseValue;
      if (card.isAce) aces++;
    }

    // Convert aces from 11 to 1 if bust
    while (total > 21 && aces > 0) {
      total -= 10;
      aces--;
    }

    return total;
  }

  /// Check if hand is soft (contains ace counted as 11)
  bool get isSoft {
    int total = 0;
    int aces = 0;

    for (final card in cards) {
      total += card.baseValue;
      if (card.isAce) aces++;
    }

    // If we can use an ace as 11 without busting
    return aces > 0 && total <= 21;
  }

  /// Check for natural blackjack (21 with first two cards)
  bool get isBlackjack => cards.length == 2 && value == 21;

  /// Check if bust
  bool get isBust => value > 21;

  /// Alias for isBust (UI compatibility)
  bool get isBusted => isBust;

  /// Check if hand can hit (not bust, not 21)
  bool get canHit => value < 21;
}

enum BlackjackOutcome {
  playerBlackjack, // Player has natural 21, pays 3:2
  playerWins, // Player wins normally, pays 1:1
  dealerWins, // Dealer wins, player loses bet
  push, // Tie, bet returned
  playerBusts, // Player busts, loses bet
  dealerBusts, // Dealer busts, player wins
}

class BlackjackResult {
  final BlackjackOutcome outcome;
  final int playerValue;
  final int dealerValue;
  final double payoutMultiplier;
  final int betAmount;

  BlackjackResult({
    required this.outcome,
    required this.playerValue,
    required this.dealerValue,
    required this.payoutMultiplier,
    this.betAmount = 0,
  });

  /// Calculate payout based on bet and multiplier
  int get payout {
    if (payoutMultiplier < 0) return 0;
    if (payoutMultiplier == 0) return betAmount; // Push returns bet
    return betAmount + (betAmount * payoutMultiplier).round();
  }

  /// Whether player won (includes push where bet is returned)
  bool get won => payoutMultiplier >= 0;
}

class BlackjackLogic {
  final CasinoRng _rng;
  late List<BlackjackCard> _deck;
  final BlackjackHand playerHand = BlackjackHand();
  final BlackjackHand dealerHand = BlackjackHand();

  BlackjackLogic({CasinoRng? rng}) : _rng = rng ?? CasinoRng.instance {
    _initDeck();
  }

  /// Initialize and shuffle deck(s)
  void _initDeck() {
    _deck = [];
    for (int d = 0; d < CasinoConfig.blackjackDecks; d++) {
      for (final suit in CardSuit.values) {
        for (final rank in CardRank.values) {
          _deck.add(BlackjackCard(suit: suit, rank: rank));
        }
      }
    }
    _shuffleDeck();
  }

  void _shuffleDeck() {
    // Fisher-Yates shuffle using our RNG
    for (int i = _deck.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final temp = _deck[i];
      _deck[i] = _deck[j];
      _deck[j] = temp;
    }
  }

  /// Draw a card from the deck
  BlackjackCard drawCard() {
    if (_deck.isEmpty) {
      _initDeck();
    }
    return _deck.removeLast();
  }

  /// Start a new round
  void newRound() {
    // Reshuffle if deck is getting low
    if (_deck.length < 52) {
      _initDeck();
    }

    playerHand.clear();
    dealerHand.clear();

    // Deal initial cards
    playerHand.addCard(drawCard());
    dealerHand.addCard(drawCard());
    playerHand.addCard(drawCard());
    dealerHand.addCard(drawCard());
  }

  /// Alias for newRound (UI compatibility)
  void newGame() => newRound();

  /// Player hits (takes another card)
  void playerHit() {
    if (playerHand.canHit) {
      playerHand.addCard(drawCard());
    }
  }

  /// Alias for playerHit (UI compatibility)
  void hit() => playerHit();

  /// Dealer plays according to rules
  void dealerPlay() {
    while (_shouldDealerHit()) {
      dealerHand.addCard(drawCard());
    }
  }

  /// Check if dealer should hit based on rules
  bool _shouldDealerHit() {
    final value = dealerHand.value;

    if (value < 17) return true;

    // Soft 17 rule
    if (value == 17 && dealerHand.isSoft) {
      return !CasinoConfig.blackjackDealerStandsOnSoft17;
    }

    return false;
  }

  /// Determine outcome after player stands or busts
  BlackjackResult determineOutcome({int betAmount = 0}) {
    final playerValue = playerHand.value;
    final dealerValue = dealerHand.value;

    // Player bust
    if (playerHand.isBust) {
      return BlackjackResult(
        outcome: BlackjackOutcome.playerBusts,
        playerValue: playerValue,
        dealerValue: dealerValue,
        payoutMultiplier: -1.0, // Lose bet
        betAmount: betAmount,
      );
    }

    // Player blackjack
    if (playerHand.isBlackjack) {
      if (dealerHand.isBlackjack) {
        // Both have blackjack = push
        return BlackjackResult(
          outcome: BlackjackOutcome.push,
          playerValue: playerValue,
          dealerValue: dealerValue,
          payoutMultiplier: 0.0,
          betAmount: betAmount,
        );
      }
      return BlackjackResult(
        outcome: BlackjackOutcome.playerBlackjack,
        playerValue: playerValue,
        dealerValue: dealerValue,
        payoutMultiplier: CasinoConfig.blackjackNaturalPayout, // 1.5 (3:2)
        betAmount: betAmount,
      );
    }

    // Dealer bust
    if (dealerHand.isBust) {
      return BlackjackResult(
        outcome: BlackjackOutcome.dealerBusts,
        playerValue: playerValue,
        dealerValue: dealerValue,
        payoutMultiplier: CasinoConfig.blackjackWinPayout, // 1.0
        betAmount: betAmount,
      );
    }

    // Compare hands
    if (playerValue > dealerValue) {
      return BlackjackResult(
        outcome: BlackjackOutcome.playerWins,
        playerValue: playerValue,
        dealerValue: dealerValue,
        payoutMultiplier: CasinoConfig.blackjackWinPayout, // 1.0
        betAmount: betAmount,
      );
    } else if (dealerValue > playerValue) {
      return BlackjackResult(
        outcome: BlackjackOutcome.dealerWins,
        playerValue: playerValue,
        dealerValue: dealerValue,
        payoutMultiplier: -1.0, // Lose bet
        betAmount: betAmount,
      );
    } else {
      return BlackjackResult(
        outcome: BlackjackOutcome.push,
        playerValue: playerValue,
        dealerValue: dealerValue,
        payoutMultiplier: 0.0, // Push
        betAmount: betAmount,
      );
    }
  }

  /// Get result with bet amount (UI compatibility)
  BlackjackResult getResult(int betAmount) =>
      determineOutcome(betAmount: betAmount);

  /// Calculate payout
  /// Returns total return (0 if lost, bet if push, bet + winnings if won)
  int calculatePayout(int betAmount, BlackjackResult result) {
    if (result.payoutMultiplier < 0) {
      return 0; // Lost
    }
    return betAmount + (betAmount * result.payoutMultiplier).round();
  }

  /// Simulate n hands using basic strategy approximation
  /// Returns observed RTP
  double simulateRtp(int numHands) {
    int totalBet = 0;
    int totalReturn = 0;
    const betAmount = 100;

    for (int i = 0; i < numHands; i++) {
      totalBet += betAmount;
      newRound();

      // Simple strategy: hit until 17+
      while (playerHand.value < 17 && playerHand.canHit) {
        playerHit();
      }

      if (!playerHand.isBust) {
        dealerPlay();
      }

      final result = determineOutcome();
      totalReturn += calculatePayout(betAmount, result);
    }

    return totalReturn / totalBet;
  }

  /// Get theoretical RTP (approximate)
  /// Actual RTP depends on player strategy
  /// With basic strategy: ~99.5% (0.5% house edge)
  double getTheoreticalRtp() {
    // This is approximate; actual depends on strategy
    return 0.995; // 99.5% with perfect basic strategy
  }
}
