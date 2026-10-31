import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:capcut_clone/providers/editor_provider.dart';
import 'package:capcut_clone/screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: const CapCutCloneApp(),
    ),
  );
}

class CapCutCloneApp extends StatelessWidget {
  const CapCutCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CapCut Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}
