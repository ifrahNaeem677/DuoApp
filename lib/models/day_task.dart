enum TaskCategory { prayer, deen, goal }

/// One thing you can tick off today (a prayer, a deen habit or a personal goal).
class DayTask {
  final String id;
  final String title;
  final String subtitle;
  final int points;
  final TaskCategory category;
  bool done;

  DayTask({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.points,
    required this.category,
    this.done = false,
  });
}

/// Everything you track for one day.
class DayData {
  final List<DayTask> tasks;
  double sleepHours;

  DayData({List<DayTask>? tasks, this.sleepHours = 7}) : tasks = tasks ?? defaultTasks();

  List<DayTask> byCategory(TaskCategory c) => tasks.where((t) => t.category == c).toList();

  List<DayTask> get prayers => byCategory(TaskCategory.prayer);
  List<DayTask> get deen => byCategory(TaskCategory.deen);
  List<DayTask> get goals => byCategory(TaskCategory.goal);

  bool get goodSleep => sleepHours >= 7 && sleepHours <= 8;

  static List<DayTask> defaultTasks() => [
        DayTask(id: 'fajr', title: 'Fajr', subtitle: 'Dawn', points: 5, category: TaskCategory.prayer),
        DayTask(id: 'dhuhr', title: 'Dhuhr', subtitle: 'Midday', points: 5, category: TaskCategory.prayer),
        DayTask(id: 'asr', title: 'Asr', subtitle: 'Afternoon', points: 5, category: TaskCategory.prayer),
        DayTask(id: 'maghrib', title: 'Maghrib', subtitle: 'Sunset', points: 5, category: TaskCategory.prayer),
        DayTask(id: 'isha', title: 'Isha', subtitle: 'Night', points: 5, category: TaskCategory.prayer),
        DayTask(id: 'quran', title: 'Quran', subtitle: 'At least 10 minutes', points: 10, category: TaskCategory.deen),
        DayTask(id: 'yaseen', title: 'Surah Yaseen', subtitle: 'Recite once', points: 5, category: TaskCategory.deen),
        DayTask(id: 'azkar', title: 'Azkar', subtitle: 'Morning & evening', points: 5, category: TaskCategory.deen),
      ];
}
