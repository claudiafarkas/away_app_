import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Calendar Page \n \n AI Calendar coming soon!',
          style: TextStyle(color: Color.fromARGB(255, 244, 241, 219)),
        ),
      ),
    );
  }
}
