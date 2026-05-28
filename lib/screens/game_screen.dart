import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/game_engine_provider.dart';
import '../widgets/influence_card_widget.dart';
import '../widgets/player_badge.dart';
import '../widgets/action_panel.dart';
import '../widgets/balatro_button.dart';
import '../widgets/rules_dialog.dart';
import '../widgets/creator_info_button.dart';
import 'lobby_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final Set<String> _exchangeSelectedCards = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameEngineProvider);
    final engine = ref.read(gameEngineProvider.notifier);
    final localPlayerId = ref.watch(localPlayerIdProvider);

    // LOBBY STATE
    if (gameState.phase == GamePhase.waitingForPlayers) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/table.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4), BlendMode.darken),
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF101416).withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ROOM CODE: ${gameState.id}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              letterSpacing: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.amberAccent)),
                  const SizedBox(height: 16),
                  Text('PLAYERS JOINED: ${gameState.players.length}/6',
                      style:
                          const TextStyle(fontSize: 24, color: Colors.white70)),
                  const SizedBox(height: 32),
                  ...gameState.players.map((p) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(p.name,
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                      )),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 300,
                    child: BalatroButton(
                      onPressed: gameState.players.length >= 2
                          ? () => engine.startGame()
                          : null,
                      color: const Color(0xFF2E7D32),
                      child: const Text('START GAME'),
                    ),
                  ),
                  if (gameState.players.length < 2)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text('WAITING FOR MORE PLAYERS...',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 20,
                              letterSpacing: 2)),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 300,
                    child: BalatroButton(
                      onPressed: () {
                        if (localPlayerId != null) {
                          engine.leaveGame(localPlayerId);
                        }
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => const LobbyScreen()));
                      },
                      color: const Color(0xFFC62828), // Deep Red
                      child: const Text('RETURN TO LOBBY'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    // GAME OVER STATE
    if (gameState.phase == GamePhase.gameOver) {
      final winner = gameState.players.firstWhere(
          (p) => p.id == gameState.winnerId,
          orElse: () => gameState.players.first);
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/table.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6), BlendMode.darken),
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: const Color(0xFF101416).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amberAccent, width: 4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 20,
                      offset: const Offset(5, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('GAME OVER',
                      style: TextStyle(
                          fontSize: 64,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6)),
                  const SizedBox(height: 24),
                  Text('${winner.name} WINS!',
                      style: const TextStyle(
                          fontSize: 32,
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 300,
                    child: BalatroButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => const LobbyScreen()));
                      },
                      color: const Color(0xFF1E88E5),
                      child: const Text('RETURN TO LOBBY'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    // IN GAME STATE
    final activePlayer = gameState.currentPlayer;
    final bottomPlayer =
        gameState.playerById(localPlayerId ?? '') ?? activePlayer;
    final opponents =
        gameState.players.where((p) => p.id != bottomPlayer.id).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/table.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6), BlendMode.darken),
          ),
        ),
        child: Row(
          children: [
            // LEFT PANEL (Control Center)
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: const Color(0xFF101416).withOpacity(0.9),
                border: const Border(
                    right: BorderSide(color: Colors.white24, width: 4)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 20,
                      offset: const Offset(5, 0))
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Phase Info Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text('ROUND INFO',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2)),
                            const SizedBox(height: 8),
                            Text(
                              gameState.turnPhase.name.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rules Info Button & Dev Info
                      Row(
                        children: [
                          Expanded(
                            child: BalatroButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (_) => const RulesDialog());
                              },
                              color: const Color(0xFF9C27B0),
                              child: const Text('INFO / CHEAT SHEET',
                                  style: TextStyle(
                                      fontSize: 14, letterSpacing: 1)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const CreatorInfoButton(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Game Log
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10, width: 2),
                          ),
                          child: ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: gameState.log.length,
                            itemBuilder: (context, index) {
                              final logMsg = gameState
                                  .log[gameState.log.length - 1 - index];
                              final isRecent = index == 0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '> $logMsg',
                                  style: TextStyle(
                                    color: isRecent
                                        ? Colors.white
                                        : Colors.white54,
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: isRecent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action / Reaction Panel
                      _buildSidePanelAction(
                          context, gameState, engine, localPlayerId),
                    ],
                  ),
                ),
              ),
            ),

            // TABLE AREA (Playing Field)
            Expanded(
              child: Container(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Opponent 1 (Top Left)
                    if (opponents.isNotEmpty)
                      Positioned(
                        top: 48,
                        left: 64,
                        child: _buildOpponentHand(opponents[0], -0.1, gameState,
                            engine, localPlayerId),
                      ),

                    // Opponent 2 (Top Right)
                    if (opponents.length > 1)
                      Positioned(
                        top: 48,
                        right: 64,
                        child: _buildOpponentHand(opponents[1], 0.1, gameState,
                            engine, localPlayerId),
                      ),

                    // Center Table Info
                    Center(
                      child: _buildTableCenter(gameState),
                    ),

                    // Active Player (Bottom Center)
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPlayerHand(
                              bottomPlayer, gameState, engine, localPlayerId),
                          const SizedBox(height: 24),
                          PlayerBadge(
                              player: bottomPlayer,
                              isActive: bottomPlayer.id == activePlayer.id),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentHand(Player player, double tilt, GameState state,
      GameEngine engine, String? localId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (!player.isAlive) return; // Cannot target dead players
            if (state.turnPhase == TurnPhase.selectTarget &&
                state.currentPlayer.id == localId) {
              engine.performAction(state.pendingAction!.type,
                  targetId: player.id);
            }
          },
          child: PlayerBadge(
              player: player,
              isActive: state.turnPhase == TurnPhase.selectTarget &&
                  state.currentPlayer.id == localId &&
                  player.isAlive),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: player.cards.asMap().entries.map((entry) {
            final int index = entry.key;
            final InfluenceCard card = entry.value;
            // Fan out slightly based on index
            final double cardAngle = player.cards.length > 1
                ? (index == 0 ? -0.1 : 0.1) + tilt
                : tilt;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InfluenceCardWidget(
                card: card,
                isFaceDown:
                    true, // Opponents cards are face down unless revealed
                width: 90,
                height: 130,
                angle: cardAngle,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlayerHand(Player activePlayer, GameState state,
      GameEngine engine, String? localId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: activePlayer.cards.asMap().entries.map((entry) {
        final int index = entry.key;
        final InfluenceCard card = entry.value;
        // Fan out based on index
        final double cardAngle =
            activePlayer.cards.length > 1 ? (index == 0 ? -0.05 : 0.05) : 0.0;

        final isSelectedForExchange = _exchangeSelectedCards.contains(card.id);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            decoration: isSelectedForExchange
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.8),
                          blurRadius: 20,
                          spreadRadius: 5)
                    ],
                  )
                : null,
            child: InfluenceCardWidget(
              card: card,
              isFaceDown: false,
              width: 130,
              height: 180,
              angle: cardAngle,
              onTap: () {
                if (state.turnPhase == TurnPhase.loseInfluence &&
                    activePlayer.id == localId) {
                  engine.revealCard(activePlayer.id, card.id);
                } else if (state.turnPhase == TurnPhase.exchangeCards &&
                    activePlayer.id == localId) {
                  if (card.isRevealed)
                    return; // Prevent returning revealed cards!
                  final int requiredCardsToReturn =
                      activePlayer.cards.length - 2;
                  setState(() {
                    if (_exchangeSelectedCards.contains(card.id)) {
                      _exchangeSelectedCards.remove(card.id);
                    } else if (_exchangeSelectedCards.length <
                        requiredCardsToReturn) {
                      _exchangeSelectedCards.add(card.id);
                    }
                  });
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableCenter(GameState state) {
    if (state.pendingAction != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PENDING ACTION',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.amberAccent.withOpacity(0.8),
                  letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text(
              state.pendingAction!.type.name.toUpperCase(),
              style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'BY ${state.playerById(state.pendingAction!.actorId)?.name.toUpperCase()}',
              style: const TextStyle(
                  fontSize: 16, color: Colors.white70, letterSpacing: 2),
            ),
          ],
        ),
      );
    }

    // Draw the deck in the center if no action is pending
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.1,
          child: Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24)),
          ),
        ),
        Transform.rotate(
          angle: 0.05,
          child: Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24)),
            child: const Center(
                child: Icon(Icons.style, color: Colors.white24, size: 40)),
          ),
        ),
        Positioned(
          bottom: -30,
          child: Text('${state.deck.length} CARDS',
              style: const TextStyle(
                  color: Colors.white54, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildSidePanelAction(BuildContext context, GameState state,
      GameEngine engine, String? localId) {
    final localPlayer = state.playerById(localId ?? '');
    if (localPlayer != null && !localPlayer.isAlive) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2),
        ),
        child: const Text('YOU HAVE LOST\nWATCHING GAME...',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      );
    }

    if (state.turnPhase == TurnPhase.selectAction) {
      if (state.currentPlayer.id == localId) {
        return Expanded(
          child: ActionPanel(
            activePlayer: state.currentPlayer,
            onActionSelected: (type) {
              if (type == ActionType.assassinate ||
                  type == ActionType.coup ||
                  type == ActionType.steal) {
                engine.startTargetSelection(type);
              } else {
                engine.performAction(type);
              }
            },
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: Text('WAITING FOR\n${state.currentPlayer.name.toUpperCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        );
      }
    }

    if (state.turnPhase == TurnPhase.selectTarget) {
      if (state.currentPlayer.id == localId) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purpleAccent, width: 2),
          ),
          child: const Text('SELECT A TARGET\n(TAP AN OPPONENT)',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: Text('WAITING FOR\n${state.currentPlayer.name.toUpperCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        );
      }
    }

    if (state.turnPhase == TurnPhase.waitingForBlock ||
        state.turnPhase == TurnPhase.waitingForChallenge) {
      bool isWaiting = false;
      final action = state.pendingAction!;

      if (state.turnPhase == TurnPhase.waitingForChallenge) {
        if (action.blockerId != null) {
          if (action.type == ActionType.foreignAid ||
              action.type == ActionType.assassinate) {
            // Only the original actor can challenge a Foreign Aid or Assassination block
            isWaiting = localId != action.actorId;
          } else {
            isWaiting = localId == action.blockerId;
          }
        } else {
          if (action.type == ActionType.assassinate) {
            // Only the target can challenge an assassination attempt
            isWaiting = localId != action.targetId;
          } else {
            isWaiting = localId == action.actorId;
          }
        }
      } else if (state.turnPhase == TurnPhase.waitingForBlock) {
        if (action.type == ActionType.foreignAid) {
          isWaiting = localId == action.actorId;
        } else if (action.type == ActionType.assassinate ||
            action.type == ActionType.steal) {
          isWaiting = localId != action.targetId;
        } else {
          isWaiting = true;
        }
      }

      // If the player has already passed, they are waiting for others
      if (action.passedPlayerIds.contains(localId)) {
        isWaiting = true;
      }

      if (isWaiting) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.orangeAccent.withOpacity(0.3), width: 2),
          ),
          child: const Text('WAITING FOR REACTIONS...',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        );
      }

      final responderId = localId ?? state.players.first.id;

      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.orangeAccent.withOpacity(0.5), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.orangeAccent.withOpacity(0.2),
                child: const Text('REACTION REQUIRED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => engine.pass(responderId),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('PASS'),
              ),
              const SizedBox(height: 8),
              if (state.turnPhase == TurnPhase.waitingForChallenge) ...[
                ElevatedButton(
                  onPressed: () => engine.challenge(responderId),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('CHALLENGE'),
                ),
              ],
              if (state.turnPhase == TurnPhase.waitingForBlock) ...[
                if (action.type == ActionType.foreignAid) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        engine.block(responderId, BlockType.blockForeignAid),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('BLOCK (DUKE)'),
                  ),
                ],
                if (action.type == ActionType.assassinate) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        engine.block(responderId, BlockType.blockAssassinate),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('BLOCK (CONTESSA)'),
                  ),
                ],
                if (action.type == ActionType.steal) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        engine.block(responderId, BlockType.blockSteal),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('BLOCK (CAPTAIN / AMBASSADOR)'),
                  ),
                ],
              ]
            ],
          ));
    }

    if (state.turnPhase == TurnPhase.loseInfluence) {
      if (localId == state.pendingAction?.loserId) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: const Text('TAP A CARD TO REVEAL\nAND LOSE INFLUENCE!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
        );
      } else {
        final loser = state.playerById(state.pendingAction?.loserId ?? '');
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: Text('WAITING FOR\n${loser?.name.toUpperCase() ?? "SOMEONE"}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        );
      }
    }

    if (state.turnPhase == TurnPhase.exchangeCards) {
      if (localId == state.currentPlayer.id) {
        final int requiredCardsToReturn = state.currentPlayer.cards.length - 2;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'TAP $requiredCardsToReturn CARD${requiredCardsToReturn > 1 ? 'S' : ''} TO RETURN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _exchangeSelectedCards.length == requiredCardsToReturn
                        ? () {
                            engine.returnExchangeCards(
                                localId!, _exchangeSelectedCards.toList());
                            setState(() {
                              _exchangeSelectedCards.clear();
                            });
                          }
                        : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32)),
                child: const Text('CONFIRM'),
              )
            ],
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: Text(
              'WAITING FOR\n${state.currentPlayer.name.toUpperCase()} TO EXCHANGE',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        );
      }
    }

    return const SizedBox.shrink();
  }
}
