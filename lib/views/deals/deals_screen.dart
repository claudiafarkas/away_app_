import 'package:flutter/material.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Deals/Offers Screen',
          style: TextStyle(color: Color.fromARGB(255, 244, 241, 219)),
        ),
      ),
    );
  }
}
