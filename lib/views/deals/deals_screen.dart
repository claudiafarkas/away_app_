import 'package:flutter/material.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Notes Page \n \n This is where you can write your notes - Premium Users will have the option to have a chat bot',
          style: TextStyle(color: Color.fromARGB(255, 244, 241, 219)),
        ),
      ),
    );
  }
}
