import 'package:flutter/material.dart';

import 'screens/pair_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const DuoDeenApp());

class DuoDeenApp extends StatelessWidget {
  const DuoDeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DuoDeen',
      theme: buildAppTheme(),
      home: const PairScreen(),
    );
  }
}
