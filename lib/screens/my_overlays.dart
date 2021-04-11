import 'package:flutter/material.dart';


class OverlayBox extends StatelessWidget {
  final Widget child;
  OverlayBox({this.child});

  @override
  Widget build(Object context) {
    return Container(
      color: Colors.grey[200],
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => child,
          ),
        ],
      ),
    );
  }
}
