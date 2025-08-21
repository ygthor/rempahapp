import 'package:flutter/material.dart';
import 'package:kanesanapp/shared/ui.dart';

export './widgets/shimmer_placeholder.dart';

Widget submitButton({onPressed, String text = '', icon}) {
  icon = icon ?? const Icon(Icons.check);

  return SizedBox(
    height: 45,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.blueDress,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // <-- Radius
        ),
        padding: const EdgeInsets.all(10), // <-- Splash color
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(text)]),
    ),
  );
}
