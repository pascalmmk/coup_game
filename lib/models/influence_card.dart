import 'enums.dart';

class InfluenceCard {
  final String id;
  final CardType type;
  final bool isRevealed;

  const InfluenceCard({
    required this.id,
    required this.type,
    this.isRevealed = false,
  });

  InfluenceCard copyWith({String? id, CardType? type, bool? isRevealed}) {
    return InfluenceCard(
      id: id ?? this.id,
      type: type ?? this.type,
      isRevealed: isRevealed ?? this.isRevealed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'isRevealed': isRevealed,
      };

  factory InfluenceCard.fromJson(Map<String, dynamic> json) => InfluenceCard(
        id: json['id'],
        type: CardType.values.byName(json['type']),
        isRevealed: json['isRevealed'] ?? false,
      );
}
