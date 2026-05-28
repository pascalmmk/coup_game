import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

final localPlayerIdProvider = StateProvider<String?>((ref) => null);

final gameEngineProvider = NotifierProvider<GameEngine, GameState>(() {
  return GameEngine();
});

class GameEngine extends Notifier<GameState> {
  final _uuid = const Uuid();
  final _random = Random();
  String? _gameId;
  StreamSubscription? _sub;

  @override
  GameState build() {
    return const GameState(
      id: 'default_game',
      players: [],
      deck: [],
    );
  }

  Future<void> joinGame(String gameId, String localId, String playerName) async {
    _gameId = gameId;
    ref.read(localPlayerIdProvider.notifier).state = localId;
    
    _sub?.cancel();
    _sub = FirebaseFirestore.instance.collection('games').doc(gameId).snapshots().listen((snap) {
      if (snap.exists) {
        state = GameState.fromJson(snap.data()!);
      }
    });

    final docRef = FirebaseFirestore.instance.collection('games').doc(gameId);
    final doc = await docRef.get();
    
    if (doc.exists) {
      final gs = GameState.fromJson(doc.data()!);
      if (!gs.players.any((p) => p.id == localId)) {
        final newPlayer = Player(id: localId, name: playerName, coins: 2, cards: const [], isConnected: true);
        final updated = gs.copyWith(players: [...gs.players, newPlayer]);
        await docRef.set(updated.toJson());
      }
    } else {
      final newPlayer = Player(id: localId, name: playerName, coins: 2, cards: const [], isConnected: true);
      final gs = GameState(id: gameId, players: [newPlayer], deck: []);
      await docRef.set(gs.toJson());
    }
  }

  void _syncState(GameState newState) {
    state = newState;
    if (_gameId != null) {
      FirebaseFirestore.instance.collection('games').doc(_gameId).set(newState.toJson());
    }
  }

  void addPlayer(String name) {
    // Managed via joinGame for multiplayer, but keeping method just in case
  }

  void leaveGame(String localId) {
    if (_sub != null) {
      _sub!.cancel();
      _sub = null;
    }
    
    // Remove player from state
    final newPlayers = state.players.where((p) => p.id != localId).toList();
    if (newPlayers.isEmpty) {
      // If last player, maybe delete game? We'll just leave it empty for now.
    }
    _syncState(state.copyWith(players: newPlayers));
    _gameId = null;
  }

  void startGame() {
    if (state.players.length < 2) return;
    
    // Create deck
    List<InfluenceCard> deck = [];
    for (var type in CardType.values) {
      for (int i = 0; i < 3; i++) {
        deck.add(InfluenceCard(id: _uuid.v4(), type: type));
      }
    }
    deck.shuffle(_random);
    
    // Deal cards and reset players
    List<Player> startingPlayers = [];
    for (var p in state.players) {
      if (deck.length >= 2) {
        startingPlayers.add(p.copyWith(
          coins: 2,
          cards: [deck.removeLast(), deck.removeLast()],
        ));
      }
    }
    
    _syncState(state.copyWith(
      deck: deck,
      players: startingPlayers,
      currentPlayerIndex: 0,
      phase: GamePhase.inProgress,
      turnPhase: TurnPhase.selectAction,
      clearPendingAction: true,
      clearWinner: true,
      log: ['Game started'],
    ));
  }

  void logAction(String message) {
    _syncState(state.copyWith(log: [...state.log, message]));
  }

  void startTargetSelection(ActionType type) {
    if (state.phase != GamePhase.inProgress) return;
    if (state.turnPhase != TurnPhase.selectAction) return;

    final actor = state.currentPlayer;
    if (type == ActionType.assassinate && actor.coins < 3) return;
    if (type == ActionType.coup && actor.coins < 7) return;

    _syncState(state.copyWith(
      turnPhase: TurnPhase.selectTarget,
      pendingAction: GameAction(type: type, actorId: actor.id),
    ));
  }

  void performAction(ActionType type, {String? targetId}) {
    if (state.phase != GamePhase.inProgress) return;
    if (state.turnPhase != TurnPhase.selectAction && state.turnPhase != TurnPhase.selectTarget) return;
    
    final actor = state.currentPlayer;
    
    // Check basic requirements
    if (type == ActionType.assassinate && actor.coins < 3) return;
    if (type == ActionType.coup && actor.coins < 7) return;
    
    // Ensure target is alive if a target is required
    if (targetId != null) {
      final targetPlayer = state.playerById(targetId);
      if (targetPlayer == null || !targetPlayer.isAlive) return;
    }
    
    final action = GameAction(
      type: type,
      actorId: actor.id,
      targetId: targetId,
    );
    
    List<Player> updatedPlayers = List.from(state.players);
    final actorIndex = state.currentPlayerIndex;
    if (type == ActionType.assassinate) {
      updatedPlayers[actorIndex] = actor.copyWith(coins: actor.coins - 3);
    } else if (type == ActionType.coup) {
      updatedPlayers[actorIndex] = actor.copyWith(coins: actor.coins - 7);
    }
    
    if (type == ActionType.income || type == ActionType.coup) {
      // Temporarily sync the upfront coin deduction before resolving
      _syncState(state.copyWith(players: updatedPlayers));
      _resolveAction(action);
    } else if (type == ActionType.foreignAid) {
      _syncState(state.copyWith(
        players: updatedPlayers,
        pendingAction: action,
        turnPhase: TurnPhase.waitingForBlock,
        log: [...state.log, '${actor.name} attempts Foreign Aid']
      ));
    } else {
      _syncState(state.copyWith(
        players: updatedPlayers,
        pendingAction: action,
        turnPhase: TurnPhase.waitingForChallenge,
        log: [...state.log, '${actor.name} attempts ${type.name}']
      ));
    }
  }

  void _resolveAction(GameAction action) {
    final actorIndex = state.players.indexWhere((p) => p.id == action.actorId);
    if (actorIndex == -1) return;
    final actor = state.players[actorIndex];
    
    List<Player> updatedPlayers = List.from(state.players);
    List<InfluenceCard> updatedDeck = List.from(state.deck);
    String? logMsg;
    
    switch (action.type) {
      case ActionType.income:
        updatedPlayers[actorIndex] = actor.copyWith(coins: actor.coins + 1);
        logMsg = '${actor.name} takes Income';
        break;
      case ActionType.foreignAid:
        updatedPlayers[actorIndex] = actor.copyWith(coins: actor.coins + 2);
        logMsg = '${actor.name} takes Foreign Aid';
        break;
      case ActionType.tax:
        updatedPlayers[actorIndex] = actor.copyWith(coins: actor.coins + 3);
        logMsg = '${actor.name} takes Tax';
        break;
      case ActionType.assassinate:
        if (action.targetId != null) {
           _syncState(state.copyWith(
             players: updatedPlayers,
             turnPhase: TurnPhase.loseInfluence,
             pendingAction: action.copyWith(isResolved: true, loserId: action.targetId),
             log: [...state.log, '${actor.name} assassinates target!']
           ));
           return; 
        }
        break;
      case ActionType.steal:
        if (action.targetId != null) {
           final targetIndex = updatedPlayers.indexWhere((p) => p.id == action.targetId);
           if (targetIndex != -1) {
             final target = updatedPlayers[targetIndex];
             final stolenCoins = min(2, target.coins);
             updatedPlayers[targetIndex] = target.copyWith(coins: target.coins - stolenCoins);
             updatedPlayers[actorIndex] = actor.copyWith(coins: actor.coins + stolenCoins);
             logMsg = '${actor.name} steals $stolenCoins from ${target.name}';
           }
        }
        break;
      case ActionType.exchange:
        int cardsToDraw = min(2, updatedDeck.length);
        if (cardsToDraw > 0) {
          final drawnCards = updatedDeck.sublist(0, cardsToDraw);
          updatedDeck.removeRange(0, cardsToDraw);
          
          updatedPlayers[actorIndex] = actor.copyWith(
            cards: [...actor.cards, ...drawnCards]
          );
          
          _syncState(state.copyWith(
            players: updatedPlayers,
            deck: updatedDeck,
            turnPhase: TurnPhase.exchangeCards,
            log: [...state.log, '${actor.name} draws cards for Exchange']
          ));
          return;
        } else {
          logMsg = '${actor.name} tried to exchange but deck is empty';
        }
        break;
      case ActionType.coup:
        if (action.targetId != null) {
           _syncState(state.copyWith(
             players: updatedPlayers,
             turnPhase: TurnPhase.loseInfluence,
             pendingAction: action.copyWith(isResolved: true, loserId: action.targetId),
             log: [...state.log, '${actor.name} launches a Coup!']
           ));
           return; 
        }
        break;
    }
    
    final newLogs = logMsg != null ? [...state.log, logMsg] : state.log;
    
    _syncState(state.copyWith(
      players: updatedPlayers,
      deck: updatedDeck,
      clearPendingAction: true,
      log: newLogs,
    ));
    
    nextTurn();
  }

  int _getRequiredPassCount(GameState state) {
    if (state.pendingAction == null) return 0;
    final action = state.pendingAction!;
    
    if (state.turnPhase == TurnPhase.waitingForChallenge) {
      if (action.blockerId != null && (action.type == ActionType.foreignAid || action.type == ActionType.assassinate)) {
        // Only the actor can challenge a block on their Foreign Aid or Assassination
        return 1;
      }
      if (action.blockerId == null && action.type == ActionType.assassinate) {
        // Only the target can challenge an assassination attempt
        return 1;
      }
      // Anyone can challenge (except the person being challenged)
      return state.alivePlayers.length - 1;
    } else if (state.turnPhase == TurnPhase.waitingForBlock) {
      if (action.type == ActionType.foreignAid) {
        // Anyone can block foreign aid (except the actor)
        return state.alivePlayers.length - 1;
      } else if (action.type == ActionType.assassinate || action.type == ActionType.steal) {
        // Only the target can block
        return 1;
      }
    }
    return 0;
  }

  void pass(String playerId) {
    if (state.pendingAction == null) return;
    
    final action = state.pendingAction!;
    
    if (action.passedPlayerIds.contains(playerId)) return;
    
    final updatedPassedIds = [...action.passedPlayerIds, playerId];
    final updatedAction = action.copyWith(passedPlayerIds: updatedPassedIds);
    final requiredPassCount = _getRequiredPassCount(state);
    
    final player = state.playerById(playerId);
    final logMsg = '${player?.name} passed.';
    
    if (updatedPassedIds.length < requiredPassCount) {
      // Not everyone has passed yet
      _syncState(state.copyWith(
         pendingAction: updatedAction,
         log: [...state.log, logMsg],
      ));
      return;
    }
    
    // Everyone has passed!
    if (state.turnPhase == TurnPhase.waitingForChallenge) {
      if (updatedAction.blockerId != null) {
        // Everyone passed on challenging the block. The block succeeds!
        _syncState(state.copyWith(
          clearPendingAction: true, 
          log: [...state.log, logMsg, 'Block goes unchallenged. Action fails.']
        ));
        nextTurn();
      } else {
        // Everyone passed on challenging the action.
        if (updatedAction.type == ActionType.assassinate || 
            updatedAction.type == ActionType.steal) {
          _syncState(state.copyWith(
            turnPhase: TurnPhase.waitingForBlock,
            pendingAction: updatedAction.copyWith(passedPlayerIds: []), // Reset passes for block phase!
            log: [...state.log, logMsg],
          ));
        } else {
          // Temporarily set state to log the final pass, then resolve
          _syncState(state.copyWith(
            pendingAction: updatedAction,
            log: [...state.log, logMsg],
          ));
          _resolveAction(updatedAction);
        }
      }
    } else if (state.turnPhase == TurnPhase.waitingForBlock) {
      // Everyone passed on blocking the action. The action succeeds!
      _syncState(state.copyWith(
        pendingAction: updatedAction,
        log: [...state.log, logMsg],
      ));
      _resolveAction(updatedAction);
    }
  }

  void challenge(String challengerId) {
    if (state.pendingAction == null) return;
    
    final action = state.pendingAction!;
    
    String challengedId;
    CardType? requiredCard;
    
    if (action.blockType != null) {
      challengedId = action.blockerId!;
      switch (action.blockType!) {
        case BlockType.blockForeignAid: requiredCard = CardType.duke; break;
        case BlockType.blockAssassinate: requiredCard = CardType.contessa; break;
        case BlockType.blockSteal: requiredCard = CardType.ambassador; break;
      }
    } else {
      challengedId = action.actorId;
      switch (action.type) {
        case ActionType.tax: requiredCard = CardType.duke; break;
        case ActionType.assassinate: requiredCard = CardType.assassin; break;
        case ActionType.steal: requiredCard = CardType.captain; break;
        case ActionType.exchange: requiredCard = CardType.ambassador; break;
        default: return;
      }
    }
    
    _syncState(state.copyWith(
      pendingAction: action.copyWith(challengerId: challengerId),
      turnPhase: TurnPhase.resolvingChallenge,
    ));
    
    final challengedPlayer = state.playerById(challengedId);
    if (challengedPlayer == null) return;
    
    bool hasCard = challengedPlayer.cards.any((c) => !c.isRevealed && c.type == requiredCard);
    
    final challenger = state.playerById(challengerId);

    if (hasCard) {
      _syncState(state.copyWith(
        turnPhase: TurnPhase.loseInfluence,
        pendingAction: action.copyWith(challengerId: challengerId, loserId: challengerId),
        log: [...state.log, 'Challenge failed! ${challenger?.name} loses influence.']
      ));
    } else {
      _syncState(state.copyWith(
        turnPhase: TurnPhase.loseInfluence,
        pendingAction: action.copyWith(challengerId: challengerId, loserId: challengedId),
        log: [...state.log, 'Challenge successful! ${challengedPlayer.name} loses influence.']
      ));
    }
  }

  void block(String blockerId, BlockType blockType) {
    if (state.pendingAction == null || state.turnPhase != TurnPhase.waitingForBlock) return;
    
    final blocker = state.playerById(blockerId);
    
    _syncState(state.copyWith(
      pendingAction: state.pendingAction!.copyWith(
        blockerId: blockerId,
        blockType: blockType,
        passedPlayerIds: const [], // Reset passes for the new challenge phase!
      ),
      turnPhase: TurnPhase.waitingForChallenge,
      log: [...state.log, '${blocker?.name} blocks with ${blockType.name}']
    ));
  }

  void revealCard(String playerId, String cardId) {
    if (state.turnPhase != TurnPhase.loseInfluence) return;
    if (state.pendingAction?.loserId != playerId) return;
    
    final pIndex = state.players.indexWhere((p) => p.id == playerId);
    if (pIndex == -1) return;
    final player = state.players[pIndex];
    
    final cIndex = player.cards.indexWhere((c) => c.id == cardId && !c.isRevealed);
    if (cIndex == -1) return;
    
    List<InfluenceCard> newCards = List.from(player.cards);
    newCards[cIndex] = newCards[cIndex].copyWith(isRevealed: true);
    
    List<Player> newPlayers = List.from(state.players);
    newPlayers[pIndex] = player.copyWith(cards: newCards);
    
    final action = state.pendingAction;
    
    _syncState(state.copyWith(
      players: newPlayers,
      log: [...state.log, '${player.name} lost ${newCards[cIndex].type.name}'],
      clearPendingAction: true,
    ));
    
    if (newPlayers.where((p) => p.isAlive).length <= 1) {
      _checkGameOver();
      return;
    }
    
    if (action != null && !action.isResolved) {
      if (action.blockerId != null) {
        // A block was challenged!
        if (action.loserId == action.challengerId) {
          // Blocker was truthful! Challenge failed. Block succeeds -> Action fails!
          _syncState(state.copyWith(
            clearPendingAction: true,
            log: [...state.log, 'Block was successful. Action fails.']
          ));
          nextTurn();
        } else {
          // Blocker lied! Challenge succeeded. Block fails -> Action succeeds!
          _resolveAction(action);
        }
      } else {
        // An action was challenged!
        if (action.loserId == action.actorId) {
          // Actor lied! Challenge succeeded. Action fails!
          _syncState(state.copyWith(
            clearPendingAction: true,
            log: [...state.log, 'Action challenge succeeded. Action fails.']
          ));
          nextTurn();
        } else {
          // Actor was truthful! Challenge failed.
          if (action.type == ActionType.assassinate || action.type == ActionType.steal) {
             // It can still be blocked!
             _syncState(state.copyWith(
               pendingAction: action,
               turnPhase: TurnPhase.waitingForBlock
             ));
          } else {
             // Action succeeds immediately!
             _resolveAction(action);
          }
        }
      }
    } else {
       nextTurn();
    }
  }

  void _checkGameOver() {
    final alive = state.alivePlayers;
    if (alive.length <= 1) {
      _syncState(state.copyWith(
        phase: GamePhase.gameOver,
        winnerId: alive.isNotEmpty ? alive.first.id : null,
        log: [...state.log, 'Game Over!']
      ));
    }
  }

  void returnExchangeCards(String playerId, List<String> cardIdsToReturn) {
    if (state.turnPhase != TurnPhase.exchangeCards) return;
    if (state.currentPlayer.id != playerId) return;
    
    final pIndex = state.players.indexWhere((p) => p.id == playerId);
    if (pIndex == -1) return;
    final player = state.players[pIndex];
    
    final requiredReturns = player.cards.length - 2;
    if (cardIdsToReturn.length != requiredReturns) return;
    
    List<InfluenceCard> newCards = List.from(player.cards);
    List<InfluenceCard> returnedCards = [];
    
    for (String id in cardIdsToReturn) {
      final idx = newCards.indexWhere((c) => c.id == id);
      if (idx != -1) {
        if (newCards[idx].isRevealed) return; // Cannot return revealed cards
        returnedCards.add(newCards.removeAt(idx));
      } else {
        return; // Card not found
      }
    }
    
    List<Player> newPlayers = List.from(state.players);
    newPlayers[pIndex] = player.copyWith(cards: newCards);
    
    List<InfluenceCard> newDeck = List.from(state.deck)..addAll(returnedCards);
    newDeck.shuffle();
    
    _syncState(state.copyWith(
      players: newPlayers,
      deck: newDeck,
      log: [...state.log, '${player.name} returned cards to the deck']
    ));
    
    nextTurn();
  }

  void nextTurn() {
    int nextIdx = (state.currentPlayerIndex + 1) % state.players.length;
    while (!state.players[nextIdx].isAlive) {
      nextIdx = (nextIdx + 1) % state.players.length;
    }
    
    _syncState(state.copyWith(
      currentPlayerIndex: nextIdx,
      turnPhase: TurnPhase.selectAction,
      clearPendingAction: true,
      log: [...state.log, 'Turn passes to ${state.players[nextIdx].name}']
    ));
  }
}
