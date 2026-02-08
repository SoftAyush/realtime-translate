import 'package:flutter/material.dart';

String formattedTime(BuildContext context) {
  final now = TimeOfDay.now();
  return now.format(context); // Pass the BuildContext here
}
