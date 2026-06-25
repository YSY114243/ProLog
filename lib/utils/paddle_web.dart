// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('window.initPaddle')
external void _initPaddle(String token, bool isSandbox);

@JS('window.openPaddleCheckout')
external void _openPaddleCheckout(String priceId, JSFunction onSuccess, JSFunction onClosed);

void initPaddle(String token, bool isSandbox) {
  try {
    _initPaddle(token, isSandbox);
  } catch (e) {
    debugPrint('Error initializing Paddle: $e');
  }
}

void openPaddleCheckout({
  required String priceId,
  required Function(dynamic) onSuccess,
  required Function(dynamic) onClosed,
}) {
  try {
    _openPaddleCheckout(
      priceId,
      ((JSAny? data) => onSuccess(data)).toJS,
      ((JSAny? data) => onClosed(data)).toJS,
    );
  } catch (e) {
    debugPrint('Error opening Paddle checkout: $e');
  }
}
