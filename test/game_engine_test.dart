import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coup_game/models/models.dart';
import 'package:coup_game/providers/game_engine_provider.dart';

void main() {
  test('Game engine starts correctly', () {
    final container = ProviderContainer();
    final engine = container.read(gameEngineProvider.notifier);
    
    engine.addPlayer('Alice');
    engine.addPlayer('Bob');
    engine.startGame();
    
    final state = container.read(gameEngineProvider);
    
    expect(state.players.length, 2);
    expect(state.phase, GamePhase.inProgress);
    expect(state.turnPhase, TurnPhase.selectAction);
    
    // Players should have 2 coins and 2 cards each
    for (var player in state.players) {
      expect(player.coins, 2);
      expect(player.cards.length, 2);
    }
  });
  
  test('Income action resolves immediately', () {
    final container = ProviderContainer();
    final engine = container.read(gameEngineProvider.notifier);
    
    engine.addPlayer('Alice');
    engine.addPlayer('Bob');
    engine.startGame();
    
    final stateBefore = container.read(gameEngineProvider);
    final activePlayerBefore = stateBefore.currentPlayer;
    final initialCoins = activePlayerBefore.coins;
    
    engine.performAction(ActionType.income);
    
    final stateAfter = container.read(gameEngineProvider);
    final activePlayerAfter = stateAfter.players.firstWhere((p) => p.id == activePlayerBefore.id);
    
    expect(activePlayerAfter.coins, initialCoins + 1);
    expect(stateAfter.currentPlayerIndex, isNot(stateBefore.currentPlayerIndex));
  });
  
  test('Foreign Aid waits for block', () {
    final container = ProviderContainer();
    final engine = container.read(gameEngineProvider.notifier);
    
    engine.addPlayer('Alice');
    engine.addPlayer('Bob');
    engine.startGame();
    
    engine.performAction(ActionType.foreignAid);
    
    final state = container.read(gameEngineProvider);
    expect(state.turnPhase, TurnPhase.waitingForBlock);
    expect(state.pendingAction?.type, ActionType.foreignAid);
  });
}
