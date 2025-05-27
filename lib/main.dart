import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const UndercoverGame());
}

class UndercoverGame extends StatelessWidget {
  const UndercoverGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Undercover Game',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: PlayerSetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PlayerSetupScreen extends StatefulWidget {
  @override
  _PlayerSetupScreenState createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  int _playerCount = 3;
  final List<TextEditingController> _controllers = [];

  void _updateControllers() {
    _controllers.clear();
    for (int i = 0; i < _playerCount; i++) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  void _startGame() {
    List<String> names = _controllers.map((c) => c.text.trim()).toList();
    if (names.any((name) => name.isEmpty)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleDistributionScreen(playerNames: names),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Number of Players:'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _playerCount,
                  items: List.generate(10, (i) => i + 3)
                      .map(
                        (e) => DropdownMenuItem<int>(
                          value: e,
                          child: Text(e.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _playerCount = val;
                        _updateControllers();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _playerCount,
                itemBuilder: (context, index) {
                  return TextField(
                    controller: _controllers[index],
                    decoration: InputDecoration(
                      labelText: 'Player ${index + 1}',
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleDistributionScreen extends StatelessWidget {
  final List<String> playerNames;
  final List<List<String>> wordPairs = [
    ['Cat', 'Tiger'],
    ['Coffee', 'Tea'],
    ['Ship', 'Boat'],
    ['Apple', 'Banana'],
    ['Sun', 'Moon'],
  ];

  RoleDistributionScreen({required this.playerNames});

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final selectedPair = wordPairs[random.nextInt(wordPairs.length)];
    final citizenWord = selectedPair[0];
    final undercoverWord = selectedPair[1];

    int undercoverIndex = random.nextInt(playerNames.length);
    List<String> roles = List.generate(
      playerNames.length,
      (index) => index == undercoverIndex ? 'Undercover' : 'Citizen',
    );
    List<String> words = List.generate(
      playerNames.length,
      (index) => index == undercoverIndex ? undercoverWord : citizenWord,
    );

    return RoleRevealScreen(
      players: List.generate(
        playerNames.length,
        (index) => Player(
          name: playerNames[index],
          role: roles[index],
          word: words[index],
        ),
      ),
    );
  }
}

class Player {
  final String name;
  final String role;
  final String word;
  bool isEliminated;

  Player({
    required this.name,
    required this.role,
    required this.word,
    this.isEliminated = false,
  });
}

class RoleRevealScreen extends StatefulWidget {
  final List<Player> players;

  const RoleRevealScreen({required this.players});

  @override
  _RoleRevealScreenState createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  int current = 0;

  void _next() {
    if (current < widget.players.length - 1) {
      setState(() {
        current++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameRoundScreen(players: widget.players),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.players[current];

    return Scaffold(
      appBar: AppBar(title: const Text("Role Reveal")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${player.name}, tap to reveal your role",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Show Role"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Your Role: ${player.role}"),
                    content: Text("Your Word: ${player.word}"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _next();
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GameRoundScreen extends StatefulWidget {
  final List<Player> players;

  const GameRoundScreen({required this.players});

  @override
  _GameRoundScreenState createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends State<GameRoundScreen> {
  int currentSpeaker = 0;
  final Map<String, int> votes = {};

  void _nextSpeaker() {
    if (currentSpeaker < alivePlayers.length - 1) {
      setState(() {
        currentSpeaker++;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VotingScreen(players: alivePlayers, onVoted: _handleVotingResult),
        ),
      );
    }
  }

  List<Player> get alivePlayers =>
      widget.players.where((p) => !p.isEliminated).toList();

  void _handleVotingResult(String votedName) {
    if (votedName.isNotEmpty) {
      Player votedPlayer = widget.players.firstWhere(
        (p) => p.name == votedName,
      );
      votedPlayer.isEliminated = true;
    }

    // Win Check
    List<Player> alive = widget.players.where((p) => !p.isEliminated).toList();
    bool undercoverAlive = alive.any((p) => p.role == 'Undercover');

    if (!undercoverAlive) {
      _showEndScreen("Citizens Win!");
    } else if (alive.length == 2) {
      _showEndScreen("Undercover Wins!");
    } else {
      setState(() {
        currentSpeaker = 0;
      });
    }
  }

  void _showEndScreen(String result) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EndScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (alivePlayers.isEmpty) return const Center(child: Text("Game Over"));

    Player speaker = alivePlayers[currentSpeaker];

    return Scaffold(
      appBar: AppBar(title: const Text("Game Round")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${speaker.name}, describe your word!",
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextSpeaker,
              child: Text(
                currentSpeaker < alivePlayers.length - 1 ? "Next" : "Vote",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VotingScreen extends StatefulWidget {
  final List<Player> players;
  final Function(String) onVoted;

  const VotingScreen({required this.players, required this.onVoted});

  @override
  _VotingScreenState createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  String? selected;

  void _submitVote() {
    widget.onVoted(selected ?? '');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voting")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("Who is the Undercover?", style: TextStyle(fontSize: 20)),
          ...widget.players.map(
            (p) => RadioListTile<String>(
              title: Text(p.name),
              value: p.name,
              groupValue: selected,
              onChanged: (val) => setState(() => selected = val),
            ),
          ),
          ElevatedButton(
            onPressed: _submitVote,
            child: const Text("Submit Vote"),
          ),
        ],
      ),
    );
  }
}

class EndScreen extends StatelessWidget {
  final String result;

  const EndScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Game Over")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              result,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Play Again"),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => PlayerSetupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
