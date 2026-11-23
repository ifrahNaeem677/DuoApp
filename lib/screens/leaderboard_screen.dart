import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('This Week', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primaryDark,
      ),
      body: ListenableBuilder(
        listenable: scoreService,
        builder: (context, _) {
          final s = scoreService;
          final today = s.todayResult;
          final rows = [...s.history, today];
          final myWins = rows.where((r) => r.iWon).length;
          final friendWins = rows.where((r) => r.friendWon).length;
          final myTotal = rows.fold<int>(0, (a, r) => a + r.myScore);
          final friendTotal = rows.fold<int>(0, (a, r) => a + r.friendScore);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 44),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _WinsColumn(name: 'You', wins: myWins, total: myTotal),
                        const Text('–',
                            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                        _WinsColumn(name: s.friendName, wins: friendWins, total: friendTotal),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      myWins > friendWins
                          ? 'You lead the week! 🏆'
                          : myWins == friendWins
                              ? 'Neck and neck this week 🤝'
                              : '${s.friendName} leads the week. Catch up! 💪',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Daily results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 10),
              ...rows.reversed.map((r) => _DayRow(
                    result: r,
                    isToday: identical(r, today),
                    dayName: _weekdays[r.date.weekday - 1],
                    friendName: s.friendName,
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _WinsColumn extends StatelessWidget {
  final String name;
  final int wins;
  final int total;
  const _WinsColumn({required this.name, required this.wins, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$wins', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
        SizedBox(
          width: 110,
          child: Text(name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        Text('$total pts', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final DayResult result;
  final bool isToday;
  final String dayName;
  final String friendName;
  const _DayRow({required this.result, required this.isToday, required this.dayName, required this.friendName});

  Widget _bar(String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (score / ScoreService.maxScore).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                backgroundColor: AppColors.bg,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('$score',
                textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String badge;
    final Color badgeColor;
    if (result.iWon) {
      badge = 'WON';
      badgeColor = AppColors.primary;
    } else if (result.friendWon) {
      badge = 'LOST';
      badgeColor = Colors.redAccent;
    } else {
      badge = 'TIE';
      badgeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration().copyWith(
        border: isToday ? Border.all(color: AppColors.accent, width: 2) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(isToday ? 'Today' : dayName,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                Text('${result.date.day}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _bar('You', result.myScore, AppColors.primary),
                _bar(friendName, result.friendScore, AppColors.gold),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: badgeColor.withAlpha(30), borderRadius: BorderRadius.circular(12)),
            child: Text(isToday ? 'LIVE' : badge,
                style: TextStyle(color: isToday ? AppColors.accent : badgeColor, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
