import 'influence_card.dart';

class Player {
  final String id;
  final String name;
  final int coins;
  final List<InfluenceCard> cards;
  final bool isConnected;

  const Player({
    required this.id,
    required this.name,
    this.coins = 2,
    this.cards = const [],
    this.isConnected = false,
  });

  bool get isAlive => cards.any((c) => !c.isRevealed);
  int get influenceCount => cards.where((c) => !c.isRevealed).length;

  Player copyWith({
    String? id,
    String? name,
    int? coins,
    List<InfluenceCard>? cards,
    bool? isConnected,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      coins: coins ?? this.coins,
      cards: cards ?? this.cards,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'coins': coins,
        'cards': cards.map((c) => c.toJson()).toList(),
        'isConnected': isConnected,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'],
        name: json['name'],
        coins: json['coins'] ?? 2,
        cards: (json['cards'] as List<dynamic>? ?? [])
            .map((c) => InfluenceCard.fromJson(c))
            .toList(),
        isConnected: json['isConnected'] ?? false,
      );
}
