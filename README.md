# Coup Game

A multiplayer card game built with Flutter and Firebase. Create a room, share its code, and play through bluffing, challenges, blocks, coin actions, and influence elimination with live updates between clients.

The interface uses a dark tabletop background, illustrated character cards, animated buttons, and VT323 typography. Riverpod manages application state, Firebase Authentication supplies anonymous player identities, and Cloud Firestore stores and synchronizes each room.

The current implementation is a multiplayer prototype. The table renders the local player and two opponents, and game decisions run on clients. See [Current limitations](#current-limitations) for the rules, synchronization, and hidden-card restrictions before using it beyond a trusted demonstration.

## Run

Use **Flutter 3.38.4 or later** with a bundled Dart SDK satisfying **`>=3.10.3 <4.0.0`**, as required by the checked-in dependency lockfile. The broader Dart constraint in `pubspec.yaml` does not describe the minimum needed by the locked dependency set.

You will also need:

- A Firebase project you control.
- Firebase Authentication with **Anonymous** sign-in enabled.
- A Cloud Firestore database.
- Firebase CLI and FlutterFire CLI for project configuration.
- A browser for the web build, or the platform toolchain for a native target.

The repository imports a generated `lib/firebase_options.dart` file that is intentionally ignored by Git. A clean checkout must generate its own Firebase configuration before it can run.

### Install dependencies

```sh
git clone https://github.com/pascalmmk/coup_game.git
cd coup_game
flutter --version
flutter doctor
flutter pub get
```

The app is a Dart/Flutter project. There is no application Node.js server, npm frontend, Docker stack, or database migration command.

### Configure Firebase

Create a project in the [Firebase Console](https://console.firebase.google.com/), create its Firestore database, and enable **Authentication → Sign-in method → Anonymous**.

Install the Firebase CLI if it is not already available. One installation option, with Node.js and npm installed, is:

```sh
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

From the repository root, configure the web target using your project ID:

```sh
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID --platforms=web
```

This generates `lib/firebase_options.dart`, which is used during application startup. For another target, configure that platform as well and complete its native Firebase setup.

The checked-in `.firebaserc` and `firebase.json` refer to the original project, `coup-game-ed496`. Replace the project association for your own installation. Do not assume those checked-in identifiers give you access to the original project's services.

For Firebase CLI operations, select your project:

```sh
firebase use --add
```

There is no `.env` loader or application environment-variable configuration. Adding a Firebase key to an `.env` file will not satisfy the missing generated-options import.

### Configure Firestore access

The repository includes `firestore.rules`, and `firebase.json` points to it.

The rules allow authenticated users to read games and create or update game documents when their `id` field matches the document ID. Anonymous Firebase users count as authenticated. Deleting game documents is denied, and other collections are denied.

**These are prototype rules:** they do not restrict access to room members, validate legal moves, or protect individual players' hidden cards. Use a separate demonstration project with trusted participants. A deployment that needs fair play and private hands requires changes to both the data model and game authority.

For a demonstration project where that access model is intentional, deploy the checked-in rules explicitly to your project:

```sh
firebase deploy --only firestore:rules --project=YOUR_FIREBASE_PROJECT_ID
```

No seed data is required. The first create/join operation writes a document in the `games` collection.

### Start the web app

```sh
flutter run -d chrome
```

Enter a nickname and create a game. Have another participant join the same room code using a separate device or browser profile.

Two tabs in the same browser profile can share an anonymous Firebase identity. Because room membership is keyed by that UID, they may represent the same player rather than two independent participants.

For the current interface, start with **two or three players on a wide screen**. The waiting room displays a `/6` player count, but the playing field only renders two opponents and the engine does not enforce a six-player limit.

### Native targets

The repository contains Android, iOS, macOS, Windows, and Linux runner directories. Their presence does not establish that every platform has a complete, working Firebase configuration.

Configure Firebase for the target, install its Flutter platform toolchain, and check available devices:

```sh
flutter devices
flutter run -d YOUR_DEVICE_ID
```

The checked-in FlutterFire metadata lists Android, iOS, macOS, web, and Windows configurations, but the generated options file is absent. Linux is not listed there. Verify Firebase plugin support and configuration for each target before treating it as supported.

The fixed-width game layout also needs testing on small mobile screens; it is not a fully adaptive phone interface.

## Workflow

1. Open the app and wait for anonymous sign-in.
2. Enter a nickname, or leave it blank to use the generated player label.
3. Select **CREATE NEW GAME** and share the displayed room code.
4. Other players enter that code and select **JOIN GAME**.
5. Once at least two players have joined, select **START GAME**.
6. On your turn, choose an action. For Coup, Assassinate, or Steal, tap an opponent's name/coin badge to select the target.
7. When a reaction is required, select **PASS**, **CHALLENGE**, or the available **BLOCK** button.
8. If you lose influence, tap one of your unrevealed cards.
9. During Exchange, select the requested cards to return and press **CONFIRM**.
10. Continue until only one player has unrevealed influence remaining.

Open **INFO / CHEAT SHEET** during a game to view the action and character reference.

## Features and controls

### Anonymous player identity

`AuthNotifier` listens to Firebase authentication state. If no current user exists, it calls `signInAnonymously()`.

There is no email/password screen, OAuth flow, account-linking interface, or sign-out button. The nickname is a room display name, not an authentication credential.

If a nickname is blank, the lobby uses `Player ` followed by the first four characters of the Firebase UID. The lobby also displays a shortened player ID.

Returning to an existing room with the same UID does not add a duplicate player or update the previously stored nickname.

### Room creation and joining

New room codes contain five randomly chosen uppercase letters or digits. The code becomes the Firestore document ID under `games`.

Joining uppercases the entered code. Both creating and joining call the same `joinGame()` method:

- If the document exists, a player with a new UID is appended.
- If the UID is already present, the existing player is reused.
- If the document does not exist, a new room is created.

As a result, entering a mistyped code can create a different room instead of displaying “room not found.” The join path does not enforce a five-character format, trim surrounding whitespace, check room capacity, or reject a game already in progress.

Room codes are identifiers, not passwords. The Firestore rules do not use them as a membership authorization mechanism.

### Waiting room and starting a match

The waiting room displays the room code, joined names, player count, **START GAME**, and **RETURN TO LOBBY**.

Start is enabled with at least two players. There is no separate host role: any participant using the waiting-room interface can start the match.

Starting creates a 15-card deck with three copies of each character, shuffles it, and deals two cards to each player. Every dealt player starts with two coins, and the first player in the stored list takes the first turn.

There is no special two-player starting-coin adjustment in the code. A new match resets the pending action, winner, turn phase, and log.

### Actions

The action panel shows all seven actions. Character actions remain selectable without the corresponding card, allowing bluffing.

| Action | Cost / effect | Resolution in this implementation |
| --- | --- | --- |
| Income | Gain 1 coin | Resolves immediately and advances the turn. |
| Foreign Aid | Gain 2 coins | Waits for other living players to pass or claim a Duke block. |
| Coup | Pay 7 coins; target loses influence | Cannot be blocked or challenged; target selects a card to reveal. |
| Tax | Claim Duke; gain 3 coins | Waits for challenges before resolving. |
| Assassinate | Claim Assassin; pay 3 coins; target loses influence | Target may challenge, then may claim a Contessa block if the action proceeds. |
| Steal | Claim Captain; take up to 2 target coins | Waits for challenges, then a target block or pass. |
| Exchange | Claim Ambassador; draw and return cards | Waits for challenges, then opens card selection. |

Assassination and Coup costs are deducted when the action is submitted. Assassination coins are not refunded when the action is blocked or its claim fails.

Steal transfers `min(2, target.coins)`, so a player with fewer than two coins loses only what they have.

At ten or more coins, the interface disables every action except Coup. This restriction is in `ActionPanel`; the engine does not independently enforce it.

### Target selection

Coup, Assassinate, and Steal first switch the turn to `selectTarget`. The local active player then taps a living opponent's badge to submit the action.

Opponent card artwork is not the target-selection control. There is no cancel-target button in the current interface.

The table places only the first two opponents at its upper corners. Additional participants may be stored in the room but cannot all be selected through this layout.

### Challenges

A challenge checks whether the claimed player has an unrevealed card of the required character type.

- If the claim is supported, the challenger must reveal and lose one influence.
- If the claim is unsupported, the claimant must reveal and lose one influence.
- The game then continues or cancels the pending action according to whether the challenged claim was an action or a block.

The defending player does not manually select a proof card. The client checks the complete stored hand automatically. It also does not return a successfully defended character to the deck and draw a replacement.

Challenge eligibility follows the implemented interface:

| Claim | Players offered a challenge |
| --- | --- |
| Tax, Steal, Exchange | Other living players. |
| Assassination action | Only the target. |
| Foreign Aid or Assassination block | Only the original actor. |
| Steal block | Living players other than the blocker. |

These details describe the source behavior rather than claiming complete fidelity to every standard Coup rule.

### Blocks

Foreign Aid can be blocked by another living player claiming Duke. Assassination can be blocked by its target claiming Contessa. Steal can be blocked by its target using the button labelled **BLOCK (CAPTAIN / AMBASSADOR)**.

A block creates a new challenge window and clears the list of passed players. If the block goes unchallenged, the original action fails and the turn advances.

There is a current mismatch in Steal blocks: the interface names both Captain and Ambassador, but the challenge resolver checks only for an unrevealed Ambassador. A Captain-only hand therefore fails that block challenge in the implemented engine.

### Passing and reaction windows

Passes are stored as player IDs on the pending action. Duplicate passes from the same ID are ignored. The interface switches players who have passed to **WAITING FOR REACTIONS...**.

Once the required number of passes is reached, the engine resolves the action, moves from challenge to block handling, or accepts an unchallenged block.

There is no reaction timer or automatic pass for disconnected participants. A match can wait indefinitely for a player who stops responding.

### Losing influence and elimination

The player identified by `pendingAction.loserId` taps an unrevealed card. The engine marks it `isRevealed: true`; it stays in the player's card list and becomes visible to other clients.

A player is alive while at least one card remains unrevealed. Once both are revealed, the interface displays **YOU HAVE LOST / WATCHING GAME...**, hides normal action controls, and later turns skip that player.

After influence loss, the engine checks for one remaining living player and records the winner. The game-over screen displays that player's name.

### Ambassador exchange

Exchange draws up to two cards from the remaining deck and temporarily adds them to the acting player's cards. The player selects cards to return and presses **CONFIRM**.

The required return count is `player.cards.length - 2`. Revealed cards cannot be returned. Returned cards are added to the deck, the deck is shuffled, and the turn advances.

Because revealed cards remain in the player's list, this preserves already-lost influence rather than restoring the player to two living cards.

### Table, cards, and log

- Your cards are shown face up at the bottom of the table.
- Opponent cards are drawn face down until revealed.
- Player badges show names, coins, and remaining influence.
- The centre shows the pending action and actor, or the remaining deck count.
- The left panel shows the current turn phase and a scrolling event log with the newest event emphasized.
- Revealed cards receive a dark overlay and a red **REVEALED** label.
- Selected exchange cards receive a blue glow.

The visual concealment of opponent cards is not data-level secrecy: every client receives the complete game document, including every hand and the deck order.

### Visual style and reference dialogs

`AppTheme.darkTheme` applies the dark palette and VT323 font through `google_fonts`. There is no light-theme switch or user theme preference.

`BalatroButton` uses a short animated press offset and shadow change. Card containers and player badges use Flutter animations; the project does not use a dedicated game engine or animation library.

The cheat sheet lists actions and character abilities. A separate creator-information dialog credits Mustafa Alhasson and the GitHub handle `@pascalmmk`.

### Leaving and returning

The waiting-room **RETURN TO LOBBY** button cancels that client's room subscription and removes its player from the room list. An empty room document is left in Firestore rather than deleted.

The game-over **RETURN TO LOBBY** button only navigates back; it does not call `leaveGame()`. The in-game layout has no dedicated leave button.

The app does not save a room code for automatic restoration after reload. A player can enter the same code again, and the same Firebase UID will reuse its existing entry. There is no explicit presence heartbeat, disconnect recovery flow, or host migration.

## Development

Run commands from the repository root after generating Firebase configuration.

| Command | Purpose |
| --- | --- |
| `flutter pub get` | Resolves and installs Dart/Flutter packages. |
| `flutter doctor` | Checks the installed development toolchain. |
| `flutter devices` | Lists available run targets. |
| `flutter run -d chrome` | Starts web development in Chrome. |
| `flutter analyze` | Runs static analysis and configured Flutter lints. |
| `dart format lib test` | Formats application and test source. |
| `flutter test` | Runs the checked-in tests; see their current limitations below. |
| `flutter build web --release` | Produces a web release in `build/web`. |

Native release builds additionally need the relevant platform configuration, toolchain, identifiers, and signing setup.

There is no checked-in backend service to start alongside Flutter. Firestore and Firebase Authentication are the network services used by the application.

## Technologies

| Technology | Declared / locked version | Role |
| --- | --- | --- |
| Flutter | Lockfile requires `>=3.38.4` | Widgets, rendering, navigation, animations, platform builds. |
| Dart | Lockfile requires `>=3.10.3 <4.0.0` | Application and game logic. |
| `flutter_riverpod` | `^2.5.1` / `2.6.1` | Reactive authentication, local player ID, and game state. |
| `firebase_core` | `^3.6.0` / `3.15.2` | Firebase initialization. |
| `firebase_auth` | `^5.3.1` / `5.7.0` | Anonymous identities and auth-state updates. |
| `cloud_firestore` | `^5.4.3` / `5.6.12` | Room documents, snapshot listeners, and state writes. |
| `uuid` | `^4.4.0` / `4.5.3` | Unique IDs for individual influence cards. |
| `google_fonts` | `^8.1.0` / `8.1.0` | VT323 text styling. |
| `collection` | `^1.18.0` / `1.19.1` | Declared dependency; not explicitly imported by the inspected game implementation. |
| `flutter_test` | Flutter SDK | Unit/widget test APIs. |
| `flutter_lints` | `^6.0.0` / `6.0.0` | Analyzer lint configuration. |
| Firebase Hosting | Configuration in `firebase.json` | Optional hosting for the web build. |

`dart:math` provides random room-code generation, shuffling, and bounded coin transfers. `dart:async` supplies the room subscription type. These are Dart libraries, not extra packages.

The application does not use Flame, a custom WebSocket server, Cloud Functions, an ORM, or a server-side game engine.

## Architecture and data flow

```text
Flutter application
    |
    +-- AuthNotifier <--------------> Firebase Authentication
    |       anonymous UID
    |
    +-- LobbyScreen
    |       nickname + room code
    |
    +-- GameScreen / ActionPanel
            |
            v
        GameEngine (Riverpod Notifier)
            |
            | local state transition + whole-document write
            v
        Firestore: games/{roomCode}
            |
            | snapshot updates
            v
        GameEngine on every subscribed client
            |
            v
        Rebuilt game interface
```

### Startup

`main()` initializes Flutter bindings, initializes Firebase with generated platform options, and runs `CoupApp` inside `ProviderScope`.

`CoupApp` creates a dark `MaterialApp` with `LobbyScreen` as its home. Watching the authentication provider starts anonymous authentication and updates the lobby when a user becomes available.

### Joining a room

`joinGame()` records the local player ID, subscribes to the game document, reads its current contents, and creates or updates the room as needed.

Each snapshot is converted from JSON to `GameState`. Riverpod notifies widgets that watch the provider, rebuilding the relevant interface.

### Making a move

Controls call methods such as `performAction()`, `pass()`, `challenge()`, `block()`, or `revealCard()`.

These methods calculate a replacement state and call `_syncState()`. That method updates local state immediately and writes the entire serialized state back to Firestore.

The write is not awaited inside `_syncState()`, and it is not a transaction. Simultaneous moves or passes can overwrite each other. Firestore synchronizes the submitted documents; it does not adjudicate the game's rules.

### Game and turn phases

| Game phase | Screen state |
| --- | --- |
| `waitingForPlayers` | Waiting room and start control. |
| `inProgress` | Playing table and action/reaction controls. |
| `gameOver` | Winner screen. |

| Turn phase | Purpose |
| --- | --- |
| `selectAction` | Active player chooses an action. |
| `selectTarget` | Active player chooses an opponent. |
| `waitingForChallenge` | Eligible players may challenge or pass. |
| `waitingForBlock` | Eligible players may block or pass. |
| `resolvingChallenge` | Transitional state during automatic claim checking. |
| `loseInfluence` | The losing player selects a card to reveal. |
| `exchangeCards` | The acting player selects cards to return. |

`resolvingAction` is also declared in the enum, but the inspected engine does not enter it. `PlayerResponseType` is declared as a model enum; responses are implemented through separate engine methods.

## Firestore data model

Each room occupies one document at `games/{gameId}`.

| Field | Meaning |
| --- | --- |
| `id` | Room code, matching the document ID. |
| `players` | Full player records, including all cards. |
| `deck` | Remaining influence cards in stored order. |
| `currentPlayerIndex` | Index of the active player. |
| `phase` | Overall match phase. |
| `turnPhase` | Current action/reaction phase. |
| `pendingAction` | Action, actor, target, blocker, challenger, loser, and passes. |
| `winnerId` | Winning player ID when recorded. |
| `log` | Array of game-event messages. |

A `Player` stores `id`, `name`, `coins`, `cards`, and `isConnected`. An `InfluenceCard` stores `id`, `type`, and `isRevealed`.

`isConnected` is set when a new player joins, but it is not a live presence tracker. There are no separate private-hand documents, move-history subcollections, account profiles, timestamps, or ranked statistics in the implemented model.

The log grows inside the same document and is rewritten with state updates; there is no log pagination or pruning mechanism.

## File guide

```text
lib/
  main.dart                         Firebase startup and application root
  firebase_options.dart             Generated locally; ignored by Git
  core/
    theme.dart                      Dark palette and VT323 typography
  models/
    enums.dart                      Cards, actions, blocks, phases
    influence_card.dart             Card identity, type, revealed flag
    player.dart                     Player data and influence helpers
    game_action.dart                Pending action and reaction data
    game_state.dart                 Room state and JSON conversion
    models.dart                     Model exports
  providers/
    auth_provider.dart              Anonymous sign-in and auth state
    game_engine_provider.dart       Room sync and game transitions
  screens/
    lobby_screen.dart               Nickname, room creation, joining
    game_screen.dart                Waiting room, table, reactions, winner
  widgets/
    action_panel.dart               Action list, costs, forced-Coup UI
    balatro_button.dart             Animated pressable button
    influence_card_widget.dart      Card front/back and revealed state
    player_badge.dart               Name, coins, influence, highlighting
    rules_dialog.dart               Action and character cheat sheet
    creator_info_button.dart        Creator-information dialog
assets/images/
  table.png                         Table background and card-back texture
  duke.png
  assassin.png
  captain.png
  ambassador.png
  contessa.png                       Character illustrations
test/
  game_engine_test.dart              Three older engine tests
  widget_test.dart                   Unadapted counter-app smoke test
web/                                Flutter web runner files
android/ ios/ macos/ windows/ linux/ Native runner projects
firebase.json                       Firebase/Hosting configuration
.firebaserc                         Original Firebase project association
firestore.rules                     Game-document access rules
pubspec.yaml                        Dependencies and asset declarations
pubspec.lock                        Resolved package versions
analysis_options.yaml               Flutter lint configuration
```

The repository also contains `bulid/web` with that spelling. Firebase Hosting is configured for `build/web`, which is the normal output of a fresh Flutter build. Do not use the similarly named checked-in directory as a substitute for rebuilding current source.

## Understanding the code

### `main.dart`: initializing the application

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
runApp(const ProviderScope(child: CoupApp()));
```

Flutter bindings are initialized before Firebase. Platform-specific options identify the configured Firebase app, and `ProviderScope` makes Riverpod providers available to the widget tree.

This is why the generated options file must exist before building, and why the widget test cannot simply instantiate the application without accounting for its providers and Firebase dependencies.

### `auth_provider.dart`: anonymous sign-in

```dart
FirebaseAuth.instance.authStateChanges().listen((user) {
  state = user;
});

if (FirebaseAuth.instance.currentUser == null) {
  await FirebaseAuth.instance.signInAnonymously();
}
```

Authentication changes replace the provider's user value. The lobby shows a loading indicator while that value is null.

The initializer has no dedicated error-state UI. If anonymous authentication fails, the lobby can remain on its loading screen rather than displaying a useful sign-in error.

### `player.dart`: counting influence

```dart
bool get isAlive => cards.any((c) => !c.isRevealed);
int get influenceCount => cards.where((c) => !c.isRevealed).length;
```

Influence is calculated from unrevealed cards, not a separate health counter. A revealed card stays in the hand data but no longer contributes to survival.

### `game_engine_provider.dart`: building the deck

```dart
for (var type in CardType.values) {
  for (int i = 0; i < 3; i++) {
    deck.add(InfluenceCard(id: _uuid.v4(), type: type));
  }
}
deck.shuffle(_random);
```

The five character types produce 15 cards. UUIDs distinguish two physical cards of the same character, which matters when selecting a card to reveal or return.

Dealing removes two cards for each player in list order. The engine does not enforce the advertised six-player cap; if more players join than the deck can support, not every stored player is included in the dealt list.

### `game_engine_provider.dart`: synchronizing state

```dart
void _syncState(GameState newState) {
  state = newState;
  if (_gameId != null) {
    FirebaseFirestore.instance
        .collection('games')
        .doc(_gameId)
        .set(newState.toJson());
  }
}
```

Local UI changes are immediate, followed by a whole-document write. Incoming snapshots replace the local model with the stored version.

This simple design makes the flow easy to follow, but does not prevent conflicting writes or prove that a move came from the correct player. Several eligibility checks live only in the widgets.

### `action_panel.dart`: forcing Coup in the interface

```dart
final mustCoup = activePlayer.coins >= 10;
```

The panel combines this flag with affordability checks to disable buttons. It does not check whether a player actually holds the character for Tax, Steal, Exchange, or Assassinate, because those actions allow bluffing.

The distinction between button restrictions and engine validation matters: hiding a button is not enforcement against a modified client.

### `influence_card_widget.dart`: showing card faces

```dart
final bool showBack = isFaceDown && !card.isRevealed;
final imagePath = 'assets/images/${card.type.name}.png';
```

An unrevealed opponent card shows its back. A revealed card shows its character artwork even when the caller requested a face-down hand. Enum names must continue to match asset filenames.

### `game_state.dart`: replacing nullable state

The model uses `copyWith()` to create replacement state objects. Special flags such as `clearPendingAction` and `clearWinner` explicitly remove nullable values; simply omitting an argument preserves its previous value.

`toJson()` and `fromJson()` serialize nested players, cards, actions, and enum names for Firestore. Changes to these serialized names need to account for existing room documents.

## Configuration and assets

| File or setting | Purpose |
| --- | --- |
| `lib/firebase_options.dart` | Generated platform-specific Firebase initialization values. |
| Native Firebase configuration files | Platform configuration generated/downloaded for configured targets; ignored by Git. |
| `.firebaserc` | Firebase CLI project selection. |
| `firebase.json` | Firestore rules path, Hosting output, rewrites, caching, FlutterFire metadata. |
| `firestore.rules` | Database access policy. |
| `pubspec.yaml` | Dependency ranges, app version, six image assets. |
| `lib/core/theme.dart` | Colours, typography, component styling. |

The declared app version is `1.0.0+1`. There are no implemented app-specific environment variables or `--dart-define` settings.

Character artwork and the table texture are bundled through the asset list. VT323 is requested through `google_fonts`; a font file is not declared in the asset list. The app does not implement an offline mode.

## Tests and verification

The repository contains three engine tests covering intended startup, Income resolution, and Foreign Aid's block phase. They use a `ProviderContainer` and call `addPlayer()` before starting the game.

**Those tests are out of sync with the multiplayer implementation.** `addPlayer()` is currently an empty method. The test setup therefore does not create the two players its assertions depend on, and tests that access the current player can encounter an empty list.

`widget_test.dart` is still the generated counter-app smoke test. It looks for `0`, `1`, and an add button that are not Coup's interface, and it does not provide the application's Riverpod/Firebase setup.

These files should not be described as a passing game-rules suite. There are no inspected tests covering all challenge/block combinations, concurrent Firestore updates, hidden-card access, or multiple real clients.

Useful manual checks for a configured demonstration project include:

- Create and join one room from separate identities.
- Start a two-player and a three-player match.
- Check coin changes and the seven action paths.
- Exercise truthful and bluffing claims, blocks, and influence selection.
- Exchange with one revealed card already in the hand.
- Finish a match and check the winner display.
- Try simultaneous passes and disconnecting during a reaction window.

This README was prepared from source inspection. A live Firebase game, native build, and test run were not performed as part of the documentation review.

## Web deployment

Configure the app for your Firebase project, then build:

```sh
flutter build web --release
```

The Hosting configuration serves `build/web`, rewrites requests to `/index.html`, and applies `no-cache, no-store, must-revalidate` to matching HTML, JavaScript, JSON, and WebAssembly files.

After addressing the access model for your intended audience, deploy the web output to your project:

```sh
firebase deploy --only hosting --project=YOUR_FIREBASE_PROJECT_ID
```

Hosting deployment alone does not create a Firestore database, enable anonymous sign-in, generate Firebase options, or deploy Firestore rules. Complete those steps separately.

The app has no custom backend to deploy, and no automated release workflow was visible in the inspected root file listing.

## Current limitations

### Game-rule edge cases

- Steal-block challenges check Ambassador only, despite the Captain/Ambassador button label.
- A successfully defended character is not replaced from the deck.
- Assassination challenges and some block challenges are restricted to fewer participants than the general “anyone can challenge” description might imply.
- The forced-Coup rule is enforced by the action panel, not the engine.
- If an assassination target loses their final influence to a failed challenge while other players remain, the engine can still proceed to a block/loss stage for that eliminated target. The UI hides their response controls, so the game can stall.
- Pass tracking is not consistently reset after every challenged-action continuation, which can affect later block responses.
- Required targets, response eligibility, and current-player identity are not comprehensively validated inside every engine method.

### Multiplayer and room management

- The interface renders only two opponents; the `/6` waiting-room label is not enforced capacity.
- Room creation has no collision check separate from the join-or-create behavior.
- New players can join an active or completed game without being dealt into it.
- Joining and state updates use read/replace operations rather than Firestore transactions, so concurrent changes can be lost.
- There are no response timers, disconnect cleanup, reliable presence tracking, or automatic room restoration.
- Game-over navigation does not remove the player or cancel the room subscription.
- Empty rooms and game logs have no automatic cleanup policy in the app.

### Data privacy and authority

- Every game document contains all hands and the deck order.
- Any authenticated user can read game documents under the shipped rules, including games they have not joined.
- Authenticated writes are not validated for room membership, ownership, turn order, legal actions, or protected fields.
- Rules and shuffling execute on clients rather than a trusted server.

These are properties of the current implementation, not guarantees of secure or competitive online play.

### Interface and platform support

- A fixed 350-pixel control panel and positioned card hands can overflow or overlap on narrow screens.
- The app has no bots, matchmaking browser, chat, ranking, sound system, or configurable game variants.
- Runner directories do not establish tested support for every desktop/mobile target.
- The checked-in tests need updating before they can provide meaningful regression coverage.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| Missing `firebase_options.dart` | Run FlutterFire configuration for your project and target. |
| Dependency resolution fails on an older SDK | Use Flutter/Dart versions satisfying `pubspec.lock`, not only the older README's minimum. |
| Lobby stays on its loading indicator | Check Firebase initialization, network access, and whether Anonymous sign-in is enabled. |
| Firestore permission denied | Check the selected project, authenticated user, deployed rules, and matching document `id`. |
| Two tabs appear as one player | Use distinct devices or browser profiles with separate Firebase identities. |
| Joining leads to an empty room | A nonexistent code creates a new room; verify the exact code and avoid surrounding spaces. |
| Cannot start a match | At least two player records must be present. |
| Cannot target another participant | Tap the opponent badge; only the first two opponents are rendered. |
| Waiting for reactions indefinitely | A required player may be disconnected, or a rule continuation may be stalled. There is no timeout. |
| Captain block loses its challenge | The current resolver checks Ambassador for Steal blocks. |
| Ten coins disables most actions | The interface requires Coup at ten or more coins. |
| Exchange confirmation is disabled | Select exactly the requested number of unrevealed cards. |
| Old or unexpected hosted output | Rebuild `build/web`; do not confuse it with checked-in `bulid/web`. |
| Test failures after setup | Engine tests still call the empty `addPlayer()` method; the widget test targets a counter app. |

## Suggested reading order

1. `lib/main.dart` and `lib/providers/auth_provider.dart` for startup and identity.
2. `lib/models/enums.dart`, `player.dart`, and `influence_card.dart` for game vocabulary.
3. `lib/models/game_action.dart` and `game_state.dart` for serialized state.
4. `lib/screens/lobby_screen.dart` for create/join behavior.
5. `lib/providers/game_engine_provider.dart` for rules and Firestore synchronization.
6. `lib/screens/game_screen.dart` for phase-specific controls.
7. `lib/widgets/action_panel.dart` and the card/badge widgets for interactions.
8. `firestore.rules` for the actual access boundary.
9. Tests, dependency files, and Firebase Hosting configuration for development and deployment.

## License

The existing README contains a general statement about use and modification, but no dedicated root license file was visible in the inspected repository. This document does not assign a new license to the code or artwork.

---

Documented from [repository revision `c9b33e8`](https://github.com/pascalmmk/coup_game/tree/c9b33e8e3e85ecd4ee5313ac84a243231c6de9be), with behavior checked against the application source, dependency lockfile, Firebase configuration, rules, and tests.
