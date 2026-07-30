import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'logic_puzzle_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});
  @override State<DailyChallengeScreen> createState() => _DailyState();
}

class _DailyState extends State<DailyChallengeScreen> {
  Map<String, dynamic>? _challenge;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.getDailyChallenge();
      setState(() { _challenge = data; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚡ Daily Challenge')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _challenge == null
          ? const Center(child: Text('Could not load challenge.\nCheck your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF185FA5), Color(0xFF534AB7)]),
                      borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      const Text('⚡', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text("Today's Challenge",
                        style: const TextStyle(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.w700)),
                      Text(_challenge!['date'] ?? '',
                        style: const TextStyle(color: Colors.white60, fontSize: 14)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  const Text('Same puzzle for everyone today!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => const LogicPuzzleScreen())),
                    child: const Text('Start Challenge 🚀',
                      style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
