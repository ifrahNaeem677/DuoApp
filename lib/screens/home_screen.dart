import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'home_widgets.dart';

/// Scrollable page used by every tab: header + cards,
/// SafeArea + 90px bottom space, pull-to-refresh from Supabase.
class TabPage extends StatelessWidget {
  final Widget header;
  final List<Widget> children;
  const TabPage({super.key, required this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: duo.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, kBottomSpace),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// HOME: VS card, Prayers, Deen, Goals, Sleep, Tasbeeh.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: duo,
      // ignore: prefer_const_constructors
      builder: (context, _) => TabPage(
        header: VsHeader(),
        children: [
          PairBanner(),
          SyncBar(),
          PrayersSection(),
          DeenSection(),
          GoalsSection(),
          SleepSection(),
          TasbeehSection(),
        ],
      ),
    );
  }
}

/// GOALS tab
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: duo,
      builder: (context, _) => TabPage(
        header: GradientHeader(
          title: "Today's Goals",
          subtitle: 'Up to 5 goals · 10 pts each',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [StreakChip(duo.streak), const SettingsButton()]),
        ),
        children: [SyncBar(), GoalsSection()],
      ),
    );
  }
}

/// SLEEP tab
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: duo,
      builder: (context, _) => TabPage(
        header: GradientHeader(
          title: 'Sleep',
          subtitle: 'Sleep 7-8 hours to earn +5',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [StreakChip(duo.streak), const SettingsButton()]),
        ),
        children: [SyncBar(), SleepSection(), TasbeehSection()],
      ),
    );
  }
}
