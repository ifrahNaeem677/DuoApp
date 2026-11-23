import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/day_task.dart';
import '../models/user.dart';
import 'notification_service.dart';
import 'score_service.dart';

SupabaseClient get supabase => Supabase.instance.client;

enum SyncState { synced, saving, error }

/// A row from `weekly_reports`, seen from "my" side.
class WeekReport {
  final DateTime weekStart;
  final String? winnerId;
  final int myWins;
  final int partnerWins;

  const WeekReport({required this.weekStart, this.winnerId, this.myWins = 0, this.partnerWins = 0});
}

/// All live data for the logged-in user. Every screen listens to this.
class DuoState extends ChangeNotifier {
  Profile? me;
  Profile? partner;
  List<DailyEntry> entries = [];
  bool loading = true;
  String? loadError;
  SyncState sync = SyncState.synced;

  /// true if the optional `tasbeeh_count` column is missing (see fix.sql)
  bool tasbeehColumnMissing = false;

  final Map<String, int> _myScores = {};
  final Map<String, Map<String, int>> _tasbeehByDay = {};
  final Map<String, Set<String>> _azkarChecked = {};
  int _pending = 0;
  bool _hold = false;
  Timer? _debounce;
  Timer? _tasbeehDebounce;
  Future<void> _chain = Future.value();
  StreamSubscription<List<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<List<Map<String, dynamic>>>? _entriesSub;
  String? _streamKey;
  bool _started = false;

  String get uid => supabase.auth.currentUser?.id ?? '';
  bool get isPaired => me?.pairId != null;
  String get partnerName => partner?.firstName ?? 'Friend';
  int get streak => ScoreService.streak(_myScores);

  // =================== START / STOP ===================
  Future<void> start() async {
    if (_started) return;
    _started = true;
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      await _loadProfile();
      await _ensureToday();
      await _loadMyScores();
      await _setupPair(force: true);
      _profileSub = supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', uid)
          .listen(_onProfileRows, onError: (_) {});
      await NotificationService.requestPermission();
      await NotificationService.scheduleDaily(fajrTime: '05:00');
    } catch (e) {
      loadError = 'Could not load your data.\nCheck your internet connection.\n\n$e';
    }
    loading = false;
    notifyListeners();
  }

  void stop() {
    final p = _profileSub;
    final s = _entriesSub;
    _profileSub = null;
    _entriesSub = null;
    _debounce?.cancel();
    _tasbeehDebounce?.cancel();
    _streamKey = null;
    me = null;
    partner = null;
    entries = [];
    _myScores.clear();
    _hold = false;
    _started = false;
    loading = true;
    p?.cancel();
    s?.cancel();
  }

  Future<void> retry() async {
    stop();
    await start();
  }

  /// Pull-to-refresh: reload everything from Supabase.
  Future<void> refresh() async {
    try {
      await _loadProfile();
      await _ensureToday();
      await _loadMyScores();
      await _setupPair(force: true);
    } catch (_) {
      sync = SyncState.error;
      notifyListeners();
    }
  }

  // =================== LOADING ===================
  Future<void> _loadProfile() async {
    final row = await supabase.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) {
      throw Exception('Your profile was not found in the profiles table.');
    }
    me = Profile.fromMap(row);
  }

  /// Get today's row; if it does not exist, create an empty one.
  Future<void> _ensureToday() async {
    final today = ScoreService.todayKey();
    Map<String, dynamic>? row = await supabase
        .from('daily_entries')
        .select()
        .eq('user_id', uid)
        .eq('date', today)
        .maybeSingle();
    row ??= await supabase
        .from('daily_entries')
        .upsert({'user_id': uid, 'pair_id': me?.pairId, 'date': today}, onConflict: 'user_id,date')
        .select()
        .maybeSingle();
    if (row != null) _putEntry(DailyEntry.fromMap(row));
  }

  Future<void> _loadMyScores() async {
    final rows = await supabase
        .from('daily_entries')
        .select('date, score')
        .eq('user_id', uid)
        .order('date', ascending: false)
        .limit(400);
    _myScores.clear();
    for (final r in rows) {
      _myScores[r['date'].toString()] = (r['score'] as num?)?.toInt() ?? 0;
    }
  }

  Future<void> _setupPair({bool force = false}) async {
    final pid = me?.pairId;
    partner = null;
    if (pid != null) {
      final p = await supabase
          .from('profiles')
          .select()
          .eq('pair_id', pid)
          .neq('id', uid)
          .maybeSingle();
      partner = p == null ? null : Profile.fromMap(p);
    }

    final key = pid ?? 'solo:$uid';
    if (force || _streamKey != key) {
      await _entriesSub?.cancel();
      _streamKey = key;
      final base = supabase.from('daily_entries').stream(primaryKey: ['id']);
      final filtered = pid != null ? base.eq('pair_id', pid) : base.eq('user_id', uid);
      _entriesSub = filtered.order('date', ascending: false).limit(60).listen(
        _onEntryRows,
        onError: (_) {
          sync = SyncState.error;
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  Future<void> _safeSetupPair() async {
    try {
      await _setupPair();
    } catch (_) {}
  }

  // =================== LIVE UPDATES ===================
  void _onProfileRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return;
    final p = Profile.fromMap(rows.first);
    final pairChanged = p.pairId != me?.pairId;
    me = p;
    if (pairChanged) {
      _safeSetupPair();
    } else {
      notifyListeners();
    }
  }

  void _onEntryRows(List<Map<String, dynamic>> rows) {
    final today = ScoreService.todayKey();
    final local = _findMine(today);
    final fresh = rows.map(DailyEntry.fromMap).toList();
    final busy = _pending > 0 || _hold;
    // My today row may be missing from a pair stream (e.g. just paired) – keep it.
    final hasMineToday = fresh.any((e) => e.userId == uid && e.date == today);
    if (local != null && (busy || !hasMineToday)) {
      fresh.removeWhere((e) => e.userId == uid && e.date == today);
      final serverMine = rows
          .where((r) => r['user_id'].toString() == uid && r['date'].toString() == today)
          .toList();
      if (serverMine.isNotEmpty) {
        local.score = (serverMine.first['score'] as num?)?.toInt() ?? local.score;
      }
      fresh.add(local);
    }
    entries = fresh;
    for (final e in entries) {
      if (e.userId == uid) _myScores[e.date] = e.score;
    }
    notifyListeners();
  }

  DailyEntry? _findMine(String date) {
    for (final e in entries) {
      if (e.userId == uid && e.date == date) return e;
    }
    return null;
  }

  void _putEntry(DailyEntry e) {
    entries.removeWhere((x) => x.userId == e.userId && x.date == e.date);
    entries.add(e);
    if (e.userId == uid) _myScores[e.date] = e.score;
  }

  // =================== TODAY ===================
  DailyEntry get myToday {
    final today = ScoreService.todayKey();
    final found = _findMine(today);
    if (found != null) return found;
    // New day started while the app was open → create it locally, saved on first tick.
    final e = DailyEntry.empty(userId: uid, pairId: me?.pairId, date: today);
    entries.add(e);
    return e;
  }

  DailyEntry? get partnerToday {
    final p = partner;
    if (p == null) return null;
    final today = ScoreService.todayKey();
    for (final e in entries) {
      if (e.userId == p.id && e.date == today) return e;
    }
    return null;
  }

  int get myScore => myToday.score;
  int get partnerScore => partnerToday?.score ?? 0;

  int scoreOn(String userId, String date) {
    for (final e in entries) {
      if (e.userId == userId && e.date == date) return e.score;
    }
    return 0;
  }

  /// Change today's entry and upsert to Supabase immediately.
  void updateToday(void Function(DailyEntry e) change) {
    final e = myToday;
    change(e);
    e.pairId = me?.pairId;
    notifyListeners();
    _save(e);
  }

  /// For the sleep slider: show now, upsert after the finger stops.
  void updateTodayDebounced(void Function(DailyEntry e) change) {
    final e = myToday;
    change(e);
    e.pairId = me?.pairId;
    _hold = true;
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _hold = false;
      _save(myToday);
    });
  }

  void retrySave() => _save(myToday);

  Future<void> _save(DailyEntry e) {
    _pending++;
    sync = SyncState.saving;
    notifyListeners();
    final payload = e.toUpsert();
    _chain = _chain.then((_) async {
      try {
        final row = await supabase
            .from('daily_entries')
            .upsert(payload, onConflict: 'user_id,date')
            .select()
            .maybeSingle();
        if (row != null) {
          final saved = DailyEntry.fromMap(row);
          // score always comes from the database trigger
          e.score = saved.score;
          e.id = saved.id;
          _myScores[e.date] = saved.score;
        }
        if (_pending <= 1) sync = SyncState.synced;
      } catch (_) {
        sync = SyncState.error;
      } finally {
        _pending--;
        notifyListeners();
      }
    });
    return _chain;
  }

  // =================== GOALS ===================
  bool get canAddGoal => myToday.goals.length < ScoreService.maxGoals;

  void addGoal(String title) => updateToday((e) {
        if (e.goals.length < ScoreService.maxGoals && title.trim().isNotEmpty) {
          e.goals.add(Goal(title: title.trim()));
        }
      });

  void toggleGoal(int index) => updateToday((e) {
        if (index < e.goals.length) e.goals[index].done = !e.goals[index].done;
      });

  void removeGoal(int index) => updateToday((e) {
        if (index < e.goals.length) e.goals.removeAt(index);
      });

  // =================== TASBEEH ===================
  int tasbeehFor(String key) => _tasbeehByDay[ScoreService.todayKey()]?[key] ?? 0;

  /// Adds 1 and returns the new count for this dhikr.
  int tapTasbeeh(String key) {
    final m = _tasbeehByDay.putIfAbsent(ScoreService.todayKey(), () => {});
    final n = (m[key] ?? 0) + 1;
    m[key] = n;
    myToday.tasbeehCount += 1;
    notifyListeners();
    _scheduleTasbeehSave();
    return n;
  }

  void resetTasbeeh(String key) {
    final m = _tasbeehByDay.putIfAbsent(ScoreService.todayKey(), () => {});
    final n = m[key] ?? 0;
    m[key] = 0;
    final e = myToday;
    e.tasbeehCount = (e.tasbeehCount - n) < 0 ? 0 : e.tasbeehCount - n;
    notifyListeners();
    _scheduleTasbeehSave();
  }

  void _scheduleTasbeehSave() {
    _tasbeehDebounce?.cancel();
    _tasbeehDebounce = Timer(const Duration(milliseconds: 800), () async {
      final e = myToday;
      try {
        await supabase
            .from('daily_entries')
            .upsert({
              'user_id': uid,
              'pair_id': me?.pairId,
              'date': e.date,
              'tasbeeh_count': e.tasbeehCount,
            }, onConflict: 'user_id,date');
        tasbeehColumnMissing = false;
      } on PostgrestException catch (err) {
        if (err.message.contains('tasbeeh_count')) tasbeehColumnMissing = true;
      } catch (_) {}
      notifyListeners();
    });
  }

  // =================== AZKAR ===================
  bool isAzkarChecked(String id) => _azkarChecked[ScoreService.todayKey()]?.contains(id) ?? false;

  /// Returns true when this tick completed all morning azkar.
  bool toggleAzkar(String id, List<String> allMorningIds) {
    final set = _azkarChecked.putIfAbsent(ScoreService.todayKey(), () => <String>{});
    if (!set.remove(id)) set.add(id);
    final allMorning = allMorningIds.every(set.contains);
    if (allMorning && !myToday.azkar) {
      updateToday((e) => e.azkar = true);
      return true;
    }
    notifyListeners();
    return false;
  }

  // =================== PAIRING ===================
  Future<String?> pairWith(String code) async {
    final c = code.trim().toUpperCase();
    if (c.length != 6) return 'Invalid Code';
    if (isPaired) return 'You are already paired. Unpair first.';
    try {
      await supabase.rpc('pair_with_code', params: {'code': c});
    } on PostgrestException catch (e) {
      if (_isMissingFunction(e)) {
        final err = await _pairDirect(c);
        if (err != null) return err;
      } else {
        return e.message;
      }
    } catch (_) {
      return 'Could not pair. Check your internet.';
    }
    try {
      await _loadProfile();
      if (me?.pairId != null) updateToday((e) {}); // move today's row into the pair
      await _setupPair(force: true);
    } catch (_) {}
    return null;
  }

  bool _isMissingFunction(PostgrestException e) =>
      e.code == 'PGRST202' || e.code == '42883' || e.message.contains('Could not find the function');

  /// Pairing done from the app (used when the optional SQL function is not installed).
  Future<String?> _pairDirect(String code) async {
    try {
      final friend = await supabase.from('profiles').select().eq('pair_code', code).maybeSingle();
      if (friend == null) return 'Invalid Code';
      final friendId = friend['id'].toString();
      if (friendId == uid) return "That's your own code";
      if (friend['pair_id'] != null) return 'Your friend is already paired with someone else.';

      final pairRow = await supabase
          .from('pairs')
          .insert({'user1_id': uid, 'user2_id': friendId})
          .select()
          .single();
      final pid = pairRow['id'];
      await supabase.from('profiles').update({'pair_id': pid}).eq('id', uid);
      await supabase.from('profiles').update({'pair_id': pid}).eq('id', friendId);

      final check = await supabase
          .from('profiles')
          .select('id')
          .eq('id', friendId)
          .eq('pair_id', pid)
          .maybeSingle();
      if (check == null) {
        return 'Your database rules blocked updating your friend. '
            'Run supabase/fix.sql in Supabase SQL Editor, then try again.';
      }
      return null;
    } on PostgrestException catch (e) {
      return 'Pairing was blocked by your database rules. '
          'Run supabase/fix.sql in Supabase SQL Editor, then try again.\n(${e.message})';
    } catch (_) {
      return 'Could not pair. Check your internet.';
    }
  }

  Future<String?> unpair() async {
    try {
      await supabase.rpc('unpair');
    } on PostgrestException catch (e) {
      if (!_isMissingFunction(e)) return e.message;
      try {
        final pid = me?.pairId;
        if (pid != null) {
          await supabase.from('pairs').update({'status': 'ended'}).eq('id', pid);
        }
        await supabase.from('profiles').update({'pair_id': null}).eq('id', uid);
      } catch (_) {
        return 'Could not unpair. Check your internet.';
      }
    } catch (_) {
      return 'Could not unpair. Check your internet.';
    }
    try {
      await _loadProfile();
      await _setupPair(force: true);
    } catch (_) {}
    return null;
  }

  // =================== THIS WEEK ===================
  Future<List<WeekReport>> loadPastWeeks() async {
    final pid = me?.pairId;
    if (pid == null) return [];
    final pairRow = await supabase.from('pairs').select().eq('id', pid).maybeSingle();
    final iAmUser1 = pairRow?['user1_id']?.toString() == uid;
    final rows = await supabase
        .from('weekly_reports')
        .select()
        .eq('pair_id', pid)
        .order('week_start', ascending: false)
        .limit(4);
    return rows.map((r) {
      int n(String k) => (r[k] as num?)?.toInt() ?? 0;
      return WeekReport(
        weekStart: DateTime.parse(r['week_start'].toString()),
        winnerId: r['winner_id']?.toString(),
        myWins: iAmUser1 ? n('user1_wins') : n('user2_wins'),
        partnerWins: iAmUser1 ? n('user2_wins') : n('user1_wins'),
      );
    }).toList();
  }

  String winnerName(String? winnerId) {
    if (winnerId == null) return 'Tie 🤝';
    if (winnerId == uid) return 'You won 🏆';
    return '$partnerName won';
  }

  // =================== ACCOUNT ===================
  Future<void> logout() async {
    await NotificationService.cancelAll();
    await supabase.auth.signOut();
  }
}

/// One shared instance used by every screen.
final duo = DuoState();
