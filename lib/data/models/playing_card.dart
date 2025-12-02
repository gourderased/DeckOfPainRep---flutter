/// 카드 무늬
enum Suit {
  spade,
  diamond,
  heart,
  clover;

  String get assetName => name;
}

/// 플레잉 카드 모델
class PlayingCard {
  final Suit? suit;
  final String rank;

  const PlayingCard(this.suit, this.rank);

  bool get isJoker => suit == null;
  bool get isRedJoker => rank == 'JokerR';
  bool get isBlackJoker => rank == 'JokerB';
  bool get isFaceCard => ['J', 'Q', 'K', 'A'].contains(rank);
  bool get isNumberCard => !isJoker && !isFaceCard;

  @override
  String toString() => isJoker ? rank : '${suit!.assetName}_$rank';
}
