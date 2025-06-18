import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

class RoundedBox extends StatelessWidget {
  final Widget widget;
  const RoundedBox({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Box(
      style: Style(
        $box.color(Color(0xFF1C1C1E)),
        $box.border.all(
          color: Color(0xFF1C1C1F),
          width: 1,
          style: BorderStyle.solid,
          strokeAlign: 0.5,
        ),

        $box.borderRadius.all(20),

        $box.elevation(2),
      ),
      child: widget,
    );
  }
}
