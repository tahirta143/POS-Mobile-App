import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../utils/constants.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final Color? color;
  const CustomLoader({super.key, this.size = 50, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.inkDrop(
        color: color ?? AppConstants.primaryTeal,
        size: size,
      ),
    );
  }
}
