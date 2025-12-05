import 'package:flutter/material.dart';

class AlarmsWidget extends StatelessWidget {
  const AlarmsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          Padding(padding: EdgeInsets.all(20), child: Text("Alarms")),
          Text("data"),
          Text("data"),
          Text("data"),
          Text("data"),
        ],
      ),
    );
  }
}
