import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/day_task.dart';
import '../models/user.dart';

/// Final scores of one day.
class DayResult {
  final DateTime date;
  final int myScore;
  final int friendScore;

  DayResult({required this.date, required this.myScore, required this.friendScore});

  bool get iWon => myScore > friendScore;
  bool get friendWon => friendScore > myScore;
}

/// Holds all app data in memory (local state).
/// When you add Firebase later, only this file needs to change.
class ScoreService extends ChangeNotifier {
  static const int maxGoals = 5;
  static const int goalPoints = 10;
  static const int sleepPoints = 5;
  static const int maxScore = 100;

  AppUser me = AppUser(name: 'You', pairCode: _generateCode());
  AppUser? friend;
  DayData today = DayData();
  int friendScore = 68; // demo score until Firebase is connected
  int streak = 4;
  bool savedToday = false;
  final List<DayResult> history = _demoHistory();

  // ---------- Pairing ----------
  void pair({required String myName, required String friendCode, String friendName = ''}) {
    me.name = myName;
    friend = AppUser(
      name: friendName.trim().isEmpty ? 'Friend' : friendName.trim(),
      pairCode: friendCode,
    );
    notifyListeners();
  }

  String get friendName => friend?.name ?? 'Friend';

  // ---------- Scoring ----------
  static int scoreFor(DayData d) {
    var s = 0;
    for (final t in d.tasks) {
      if (t.done) s += t.points;
    }
    if (d.goodSleep) s += sleepPoints;
    return min(s, maxScore);
  }

  int get myScore => scoreFor(today);

  String get statusText {
    final m = myScore;
    final f = friendScore;
    if (m > f) return "You're winning by ${m - f}! 🏆";
    if (m == f) return "It's a tie, keep going! 🤝";
    return '$friendName is ahead by ${f - m}. You got this! 💪';
  }

  DayResult get todayResult {
    final now = DateTime.now();
    return DayResult(
      date: DateTime(now.year, now.month, now.day),
      myScore: myScore,
      friendScore: friendScore,
    );
  }

  // ---------- Actions ----------
  void toggle(DayTask task) {
    task.done = !task.done;
    notifyListeners();
  }

  bool get canAddGoal => today.goals.length < maxGoals;

  void addGoal(String title) {
    if (!canAddGoal || title.trim().isEmpty) return;
    today.tasks.add(DayTask(
      id: 'goal_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      subtitle: 'Personal goal',
      points: goalPoints,
      category: TaskCategory.goal,
    ));
    notifyListeners();
  }

  void removeGoal(DayTask task) {
    today.tasks.remove(task);
    notifyListeners();
  }

  void setSleep(double hours) {
    today.sleepHours = hours;
    notifyListeners();
  }

  void saveToday() {
    if (!savedToday) {
      savedToday = true;
      streak += 1;
    }
    notifyListeners();
  }

  // ---------- Helpers ----------
  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static List<DayResult> _demoHistory() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    const mine = [72, 85, 64, 90, 78, 81];
    const theirs = [70, 79, 75, 88, 82, 76];
    return List.generate(
      6,
      (i) => DayResult(
        date: todayDate.subtract(Duration(days: 6 - i)),
        myScore: mine[i],
        friendScore: theirs[i],
      ),
    );
  }
}

/// One shared instance used by every screen.
final scoreService = ScoreService();
