import 'enums.dart';
import 'player.dart';
import 'influence_card.dart';
import 'game_action.dart';

class GameState {
  final String id;
  final List<Player> players;
  final List<InfluenceCard> deck;
  final int currentPlayerIndex;
  final GamePhase phase;
  final TurnPhase turnPhase;
  final GameAction? pendingAction;
  final String? winnerId;
  final List<String> log;

  const GameState({
    required this.id,
    required this.players,
    required this.deck,
    this.currentPlayerIndex = 0,
    this.phase = GamePhase.waitingForPlayers,
    this.turnPhase = TurnPhase.selectAction,
    this.pendingAction,
    this.winnerId,
    this.log = const [],
  });

  Player get currentPlayer => players[currentPlayerIndex];
  List<Player> get alivePlayers => players.where((p) => p.isAlive).toList();
  Player? playerById(String id) => players.where((p) => p.id == id).firstOrNull;

  GameState copyWith({
    String? id,
    List<Player>? players,
    List<InfluenceCard>? deck,
    int? currentPlayerIndex,
    GamePhase? phase,
    TurnPhase? turnPhase,
    GameAction? pendingAction,
    String? winnerId,
    List<String>? log,
    bool clearPendingAction = false,
    bool clearWinner = false,
  }) {
    return GameState(
      id: id ?? this.id,
      players: players ?? this.players,
      deck: deck ?? this.deck,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      turnPhase: turnPhase ?? this.turnPhase,
      pendingAction:
          clearPendingAction ? null : pendingAction ?? this.pendingAction,
      winnerId: clearWinner ? null : winnerId ?? this.winnerId,
      log: log ?? this.log,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'players': players.map((p) => p.toJson()).toList(),
        'deck': deck.map((c) => c.toJson()).toList(),
        'currentPlayerIndex': currentPlayerIndex,
        'phase': phase.name,
        'turnPhase': turnPhase.name,
        'pendingAction': pendingAction?.toJson(),
        'winnerId': winnerId,
        'log': log,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        id: json['id'],
        players: (json['players'] as List<dynamic>)
            .map((p) => Player.fromJson(p))
            .toList(),
        deck: (json['deck'] as List<dynamic>)
            .map((c) => InfluenceCard.fromJson(c))
            .toList(),
        currentPlayerIndex: json['currentPlayerIndex'] ?? 0,
        phase: GamePhase.values.byName(json['phase']),
        turnPhase: TurnPhase.values.byName(json['turnPhase']),
        pendingAction: json['pendingAction'] != null
            ? GameAction.fromJson(json['pendingAction'])
            : null,
        winnerId: json['winnerId'],
        log: List<String>.from(json['log'] ?? []),
      );
}
