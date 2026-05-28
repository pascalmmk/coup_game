import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/game_engine_provider.dart';
import '../widgets/balatro_button.dart';
import '../widgets/creator_info_button.dart';
import 'game_screen.dart';
import 'dart:math';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  void _createGame() async {
    try {
      final user = ref.read(authProvider);
      if (user == null) return;

      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final code = String.fromCharCodes(Iterable.generate(
          5, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));

      final engine = ref.read(gameEngineProvider.notifier);
      final playerName = _nameController.text.trim().isEmpty
          ? 'Player ${user.uid.substring(0, 4)}'
          : _nameController.text.trim();
      
      await engine.joinGame(code, user.uid, playerName);

      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GameScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _joinGame() async {
    try {
      final user = ref.read(authProvider);
      if (user == null || _codeController.text.isEmpty) return;

      final engine = ref.read(gameEngineProvider.notifier);
      final playerName = _nameController.text.trim().isEmpty
          ? 'Player ${user.uid.substring(0, 4)}'
          : _nameController.text.trim();

      await engine.joinGame(_codeController.text.toUpperCase(), user.uid, playerName);

      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GameScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
            width: 450,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF101416).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 4),
              boxShadow: [
                const BoxShadow(
                    color: Colors.black87,
                    blurRadius: 20,
                    offset: Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('COUP',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.amberAccent)),
                const SizedBox(height: 8),
                Text('PLAYER ID: ${user.uid.substring(0, 8)}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 20)),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'NICKNAME',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white54, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                BalatroButton(
                  onPressed: _createGame,
                  color: const Color(0xFFE53935),
                  child: const Text('CREATE NEW GAME'),
                ),
                const SizedBox(height: 32),
                const Text('OR',
                    style: TextStyle(
                        color: Colors.white54, letterSpacing: 2, fontSize: 24)),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 32,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'CODE',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white54, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.black54,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 24),
                BalatroButton(
                  onPressed: _joinGame,
                  color: const Color(0xFF1E88E5),
                  child: const Text('JOIN GAME'),
                ),
              ],
            ),
          ),
        ),
      ),
      const Positioned(
        left: 16,
        bottom: 16,
        child: CreatorInfoButton(),
      ),
    ],
  ),
);
}
}
