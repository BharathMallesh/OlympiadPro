import 'package:flutter/material.dart';

/// The Vidyora logo mark (lotus + open book) on a light rounded badge, so the
/// navy-and-gold mark stays legible on the app's dark surfaces.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Image.asset('assets/vidyora-mark.png', fit: BoxFit.contain),
    );
  }
}
