import 'package:flutter/material.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 248, 248, 248),
      child: const Center(
        child: Text(
          'rewards page',
          style: TextStyle(fontSize: 50, color: Color.fromARGB(255, 46, 46, 46)),
        ),
      ),
    );
  }
}