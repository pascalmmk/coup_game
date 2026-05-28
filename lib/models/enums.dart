enum CardType {
  duke,
  assassin,
  captain,
  ambassador,
  contessa,
}

enum ActionType {
  // General actions (anyone can do)
  income, // +1 coin
  foreignAid, // +2 coins (can be blocked by Duke)
  coup, // Pay 7, eliminate a card (can't be blocked)

  // Character actions (can be challenged)
  tax, // Duke: +3 coins
  assassinate, // Assassin: pay 3, eliminate a card
  steal, // Captain: take 2 coins from a player
  exchange, // Ambassador: swap cards with deck
}

enum BlockType {
  blockForeignAid, // Duke blocks foreign aid
  blockAssassinate, // Contessa blocks assassination
  blockSteal, // Captain or Ambassador blocks steal
}

enum GamePhase {
  waitingForPlayers, // Lobby
  inProgress, // Game running
  gameOver, // Someone won
}

enum TurnPhase {
  selectAction, // Active player picks an action
  selectTarget, // Active player picks a target (for steal/assassinate/coup)
  waitingForBlock, // Other players can block or challenge
  waitingForChallenge, // Others can challenge a block
  resolvingChallenge, // A challenge is being resolved
  resolvingAction, // Action goes through, applying effects
  loseInfluence, // A player must reveal and lose a card
  exchangeCards, // Ambassador must return 2 cards
}

enum PlayerResponseType {
  pass,
  challenge,
  block,
}
