import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: const Center(
        child: Text(
          'events page',
          style: TextStyle(fontSize: 50, color: Color.fromARGB(255, 81, 162, 233)),
        ),
      ),
    );
  }
}