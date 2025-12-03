import 'dart:math';
import '../../data/models/playing_card.dart';

/// 덱 생성 및 관리 서비스
class DeckService {
  List<PlayingCard> createShuffledDeck() {
    final deck = <PlayingCard>[];
    const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

    for (final suit in Suit.values) {
      for (final rank in ranks) {
        deck.add(PlayingCard(suit, rank));
      }
    }

    deck.add(const PlayingCard(null, 'JokerR'));
    deck.add(const PlayingCard(null, 'JokerB'));

    deck.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    return deck;
  }

  String getAssetPath(PlayingCard card) {
    if (card.isRedJoker) return 'assets/card_joker2.png';
    if (card.isBlackJoker) return 'assets/card_joker1.png';

    final suitStr = card.suit!.assetName;
    final rankStr = _getRankString(card.rank);
    return 'assets/card_${suitStr}_$rankStr.png';
  }

  String _getRankString(String rank) {
    return switch (rank) {
      'A' => 'ace',
      'K' => 'king',
      'Q' => 'queen',
      'J' => 'junior',
      '2' => 'two',
      '3' => 'three',
      '4' => 'four',
      '5' => 'five',
      '6' => 'six',
      '7' => 'seven',
      '8' => 'eight',
      '9' => 'nine',
      '10' => 'ten',
      _ => rank,
    };
  }
}
