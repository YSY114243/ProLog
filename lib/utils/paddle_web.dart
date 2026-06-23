// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js' as js;

void initPaddle(String token, bool isSandbox) {
  final win = html.window as dynamic;
  try {
    win.initPaddle(token, isSandbox);
  } catch (e) {
    print('Error initializing Paddle: $e');
  }
}

void openPaddleCheckout({
  required String priceId,
  required Function(dynamic) onSuccess,
  required Function(dynamic) onClosed,
}) {
  final win = html.window as dynamic;
  try {
    win.openPaddleCheckout(
      priceId,
      js.allowInterop((data) => onSuccess(data)),
      js.allowInterop((data) => onClosed(data)),
    );
  } catch (e) {
    print('Error opening Paddle checkout: $e');
  }
}
