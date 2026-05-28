import 'enums.dart';

class GameAction {
  final ActionType type;
  final String actorId;
  final String? targetId;
  final String? blockerId;
  final BlockType? blockType;
  final String? challengerId;
  final String? loserId;
  final bool isResolved;
  final List<String> passedPlayerIds;

  const GameAction({
    required this.type,
    required this.actorId,
    this.targetId,
    this.blockerId,
    this.blockType,
    this.challengerId,
    this.loserId,
    this.isResolved = false,
    this.passedPlayerIds = const [],
  });

  GameAction copyWith({
    ActionType? type,
    String? actorId,
    String? targetId,
    String? blockerId,
    BlockType? blockType,
    String? challengerId,
    String? loserId,
    bool? isResolved,
    List<String>? passedPlayerIds,
  }) {
    return GameAction(
      type: type ?? this.type,
      actorId: actorId ?? this.actorId,
      targetId: targetId ?? this.targetId,
      blockerId: blockerId ?? this.blockerId,
      blockType: blockType ?? this.blockType,
      challengerId: challengerId ?? this.challengerId,
      loserId: loserId ?? this.loserId,
      isResolved: isResolved ?? this.isResolved,
      passedPlayerIds: passedPlayerIds ?? this.passedPlayerIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'actorId': actorId,
        'targetId': targetId,
        'blockerId': blockerId,
        'blockType': blockType?.name,
        'challengerId': challengerId,
        'loserId': loserId,
        'isResolved': isResolved,
        'passedPlayerIds': passedPlayerIds,
      };

  factory GameAction.fromJson(Map<String, dynamic> json) => GameAction(
        type: ActionType.values.byName(json['type']),
        actorId: json['actorId'],
        targetId: json['targetId'],
        blockerId: json['blockerId'],
        blockType: json['blockType'] != null
            ? BlockType.values.byName(json['blockType'])
            : null,
        challengerId: json['challengerId'],
        loserId: json['loserId'],
        isResolved: json['isResolved'] ?? false,
        passedPlayerIds: List<String>.from(json['passedPlayerIds'] ?? []),
      );
}
