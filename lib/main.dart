import 'package:flutter/material.dart';
import 'package:freelancing/ChatScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Support Chat',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange, // main orange color
          brightness: Brightness.light,
        ),
        useMaterial3: true, // optional for modern Material 3 look
      ),
      home: const ChatScreen(),
    );
  }
}
