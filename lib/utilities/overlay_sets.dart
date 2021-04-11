import 'package:bhaithamen/utilities/variables.dart';
import 'package:flutter/material.dart';
import 'package:show_overlay/show_overlay.dart';

String useOverlay;

showTheOverlay(){
  switch (useOverlay) {
    case 'welcome':
      showOverlayWelcome();
      break;
    case 'reminder':
      showOverlayReminder();
      break;      
    default:
  }
}

showOverlayWelcome() {
    showOverlay(
      context: globalContext,
      barrierDismissible: false,
      builder: (_, __, close) {
        return Center(
          child: RaisedButton(
            onPressed: close,
            child: Text('welcome close'),
          ),
        );
      },
    );
  }

  showOverlayReminder() {
    showOverlay(
      context: globalContext,
      barrierDismissible: false,
      builder: (_, __, close) {
        return Center(
          child: RaisedButton(
            onPressed: close,
            child: Text('reminder close'),
          ),
        );
      },
    );
  }