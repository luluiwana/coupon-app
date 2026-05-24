import 'package:flutter/material.dart';

class TitleBar extends StatefulWidget {
  final String title;
  const TitleBar(this.title, {super.key});
  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 231, 230, 230),
      title: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo/mini_logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              widget.title, 
              style: const TextStyle(
                color: Color(0xFF004380),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
