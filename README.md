# Coup Game 🃏

A multiplayer implementation of the popular deduction card game **Coup**, built with **Flutter** and powered by **Firebase**.

## Features 🚀
- **Real-time Multiplayer**: Play with friends in real-time using Firebase Cloud Firestore.
- **State Management**: Built using `flutter_riverpod` for robust and scalable state management.
- **Beautiful UI**: Custom-designed cards and interactive UI with animations using `google_fonts`.
- **Cross-Platform**: Play seamlessly on web, mobile, and desktop.
- **Full Game Logic**: Implements all standard rules, actions (Income, Foreign Aid, Coup), character abilities (Duke, Assassin, Captain, Ambassador, Contessa), challenges, and blocking.

## Tech Stack 🛠️
- **Frontend**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Backend/Database**: [Firebase Cloud Firestore](https://firebase.google.com/docs/firestore)
- **Authentication**: [Firebase Auth](https://firebase.google.com/docs/auth)

## Getting Started 🏁

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.0.0 or higher)
- A Firebase project

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/pascalmmk/coup_game.git
   cd coup_game
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Create a project on the [Firebase Console](https://console.firebase.google.com/).
   - Enable **Firestore Database** and **Authentication** (Anonymous auth recommended for quick start).
   - Register your app for your desired platforms (Web, iOS, Android).
   - Use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli) to configure your project:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```
   - Make sure your Firestore rules allow reading and writing for the game. (Check `firestore.rules` for the provided security rules).

4. **Run the app:**
   ```bash
   flutter run
   ```

## How to Play 📜
Coup is a game of deduction and deception. The goal is to be the last player with influence (cards) remaining.
- On your turn, you can claim any action (even if you don't have the card!).
- Other players can challenge your claim. If you were lying, you lose a card. If you were telling the truth, the challenger loses a card.
- Use your coins to launch a Coup against another player (costs 7 coins, unblockable).

*A detailed rules dialog is included within the app!*

## Contributing 🤝
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/pascalmmk/coup_game/issues).

## License 📝
This project is open-source. Feel free to use and modify it.
