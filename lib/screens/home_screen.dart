import 'package:flutter/material.dart';

import '../models/day_task.dart';
import '../services/score_service.dart';
import '../theme/app_theme.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _addGoal() async {
    final c = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add a goal for today'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: fieldDecoration('e.g. Gym at 6 PM', Icons.flag_rounded),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Add')),
        ],
      ),
    );
    if (title != null && title.trim().isNotEmpty) {
      scoreService.addGoal(title);
    }
  }

  void _save() {
    scoreService.saveToday();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        content: Text('Saved! Your score: ${scoreService.myScore} / ${ScoreService.maxScore} ✨'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: scoreService,
        builder: (context, _) {
          final s = scoreService;
          final day = s.today;
          return SingleChildScrollView(
            child: Column(
              children: [
                _Header(service: s),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        icon: Icons.mosque_rounded,
                        title: 'Prayers',
                        tasks: day.prayers,
                        onToggle: s.toggle,
                      ),
                      _SectionCard(
                        icon: Icons.menu_book_rounded,
                        title: 'Deen',
                        tasks: day.deen,
                        onToggle: s.toggle,
                      ),
                      _SectionCard(
                        icon: Icons.flag_rounded,
                        title: "Today's Goals",
                        subtitle: '${day.goals.length}/${ScoreService.maxGoals} · swipe left to delete',
                        tasks: day.goals,
                        onToggle: s.toggle,
                        onDelete: s.removeGoal,
                        emptyText: 'No goals yet. Add up to 5 (10 pts each).',
                        footer: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: s.canAddGoal ? _addGoal : null,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(s.canAddGoal ? 'Add Goal' : 'Max 5 goals reached'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      _SleepCard(hours: day.sleepHours, good: day.goodSleep, onChanged: s.setSleep),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: Icon(s.savedToday ? Icons.check_circle_rounded : Icons.save_rounded),
                        label: Text(s.savedToday ? 'SAVED · UPDATE' : 'SAVE TODAY'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ================= HEADER WITH SCORES =================
class _Header extends StatelessWidget {
  final ScoreService service;
  const _Header({required this.service});

  @override
  Widget build(BuildContext context) {
    final my = service.myScore;
    final friend = service.friendScore;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assalamu Alaikum,',
                            style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 14)),
                        Text(service.me.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(45), borderRadius: BorderRadius.circular(20)),
                    child: Text('🔥 ${service.streak} days',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip: 'Leaderboard',
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                    icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScoreRing(label: 'YOU', score: my, leading: my > friend),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(45), shape: BoxShape.circle),
                    child: const Text('VS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  _ScoreRing(label: service.friendName.toUpperCase(), score: friend, leading: friend > my),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Text(service.statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final String label;
  final int score;
  final bool leading;
  const _ScoreRing({required this.label, required this.score, required this.leading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: (score / ScoreService.maxScore).clamp(0.0, 1.0).toDouble()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 9,
                  backgroundColor: Colors.white.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation(leading ? AppColors.gold : Colors.white),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading) const Text('👑', style: TextStyle(fontSize: 14)),
                    Text('$score',
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 110,
          child: Text(label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withAlpha(230), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        ),
      ],
    );
  }
}

// ================= SECTION CARD =================
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<DayTask> tasks;
  final void Function(DayTask) onToggle;
  final void Function(DayTask)? onDelete;
  final String? emptyText;
  final Widget? footer;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.tasks,
    required this.onToggle,
    this.subtitle,
    this.onDelete,
    this.emptyText,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final earned = tasks.where((t) => t.done).fold<int>(0, (a, t) => a + t.points);
    final total = tasks.fold<int>(0, (a, t) => a + t.points);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    if (subtitle != null)
                      Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (total > 0)
                Text('$earned/$total pts',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty && emptyText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(emptyText!, style: const TextStyle(color: AppColors.textMuted)),
            ),
          ...tasks.map((t) {
            final tile = _TaskTile(task: t, onTap: () => onToggle(t));
            if (onDelete == null) return tile;
            return Dismissible(
              key: ValueKey(t.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onDelete!(t),
              background: Container(
                margin: const EdgeInsets.only(bottom: 8),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              child: tile,
            );
          }),
          if (footer != null) ...[const SizedBox(height: 4), footer!],
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final DayTask task;
  final VoidCallback onTap;
  const _TaskTile({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: done ? AppColors.primary.withAlpha(22) : AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.primary : Colors.white,
                    border: Border.all(color: done ? AppColors.primary : Colors.grey.shade400, width: 2),
                  ),
                  child: done ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: done ? AppColors.primaryDark : AppColors.textDark,
                          )),
                      if (task.subtitle.isNotEmpty)
                        Text(task.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('+${task.points}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: done ? Colors.white : AppColors.primary,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= SLEEP CARD =================
class _SleepCard extends StatelessWidget {
  final double hours;
  final bool good;
  final ValueChanged<double> onChanged;
  const _SleepCard({required this.hours, required this.good, required this.onChanged});

  String get _label => hours % 1 == 0 ? hours.toInt().toString() : hours.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.bedtime_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sleep',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    Text('+5 pts for 7–8 hours', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Text('${_label}h',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
            ],
          ),
          Slider(
            value: hours,
            min: 0,
            max: 12,
            divisions: 24,
            label: '${_label}h',
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: good ? AppColors.primary.withAlpha(25) : Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              good ? '✅ Great sleep! +5 bonus' : '⚠️ Aim for 7–8 hours to earn +5',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: good ? AppColors.primaryDark : Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
