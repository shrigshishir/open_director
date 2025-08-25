import 'package:flutter/material.dart';

class AnimatedDialog {
  final String title;
  final Widget child;
  final String? button1Text;
  final VoidCallback? onPressedButton1;
  final String? button2Text;
  final VoidCallback? onPressedButton2;

  AnimatedDialog.show(
    BuildContext context, {
    this.title = '',
    required this.child,
    this.button1Text,
    this.onPressedButton1,
    this.button2Text,
    this.onPressedButton2,
  }) {
    List<Widget> actionButtons = [];

    if (button1Text != null) {
      actionButtons.add(
        ElevatedButton(child: Text(button1Text!), onPressed: onPressedButton1),
      );
    }
    if (button2Text != null) {
      actionButtons.add(
        ElevatedButton(child: Text(button2Text!), onPressed: onPressedButton2),
      );
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(
        child: AlertDialog(
          title: Text(title),
          content: Container(
            width: MediaQuery.of(context).size.width / 3,
            child: child,
          ),
          actions: actionButtons,
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, _child) {
        var fadeTween = CurveTween(curve: Curves.fastOutSlowIn);
        var fadeAnimation = fadeTween.animate(animation);
        return Transform.scale(
          scale: fadeAnimation.value,
          child: AlertDialog(
            title: Text(title),
            content: Container(
              width: MediaQuery.of(context).size.width / 3,
              child: child,
            ),
            actions: actionButtons,
          ),
        );
      },
    );
  }
}
