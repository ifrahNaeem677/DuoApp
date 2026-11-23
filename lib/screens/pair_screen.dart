import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class PairScreen extends StatefulWidget {
  const PairScreen({super.key});

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _nameCtrl = TextEditingController();
  final _friendNameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _friendNameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: scoreService.me.pairCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied! Send it to your friend 📩'), behavior: SnackBarBehavior.floating),
    );
  }

  void _start() {
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim().toUpperCase();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (code.length < 4) {
      setState(() => _error = "Please enter your friend's code");
      return;
    }
    if (code == scoreService.me.pairCode) {
      setState(() => _error = "That's your own code. Enter your friend's code");
      return;
    }
    scoreService.pair(myName: name, friendCode: code, friendName: _friendNameCtrl.text);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Transform.translate(offset: const Offset(0, -36), child: _buildCodeCard()),
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildRulesCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 64),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
                child: const Icon(Icons.mosque_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 14),
              const Text('DuoDeen',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text('Grow in deen together, one day at a time',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.white.withAlpha(220))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        children: [
          const Text('YOUR PAIR CODE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(scoreService.me.pairCode,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 6)),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copy code',
              ),
            ],
          ),
          const Text('Share this with your friend',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Pair with your friend',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: fieldDecoration('Your name', Icons.person_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _friendNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: fieldDecoration("Friend's name (optional)", Icons.people_alt_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: fieldDecoration("Friend's pair code", Icons.link_rounded),
            onSubmitted: (_) => _start(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('START DUO'),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    Widget rule(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textDark))),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('The Rules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 8),
          rule(Icons.favorite_rounded, 'One friend only. Your duo partner.'),
          rule(Icons.schedule_rounded, 'Daily winner decided at 10 PM.'),
          rule(Icons.icecream_rounded, 'Loser gives the winner a treat!'),
        ],
      ),
    );
  }
}
