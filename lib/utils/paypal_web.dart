// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPayPalButton({
  required String amount,
  required Function(dynamic) onSuccess,
  required Function(String) onError,
  required Function(dynamic) onCancel,
}) {
  final viewId = 'paypal-btn-container-${DateTime.now().millisecondsSinceEpoch}';

  // Register the view factory for the HTML element
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final elem = html.DivElement()
      ..id = viewId
      ..style.width = '100%'
      ..style.height = '100%';
    
    // Defer the JS call to ensure the element is in the DOM
    Future.delayed(const Duration(milliseconds: 200), () {
      // We will use standard interop or dynamic call
      // Because dart:js_util is missing in 3.12, we can just use dynamic call via window
      final win = html.window as dynamic;
      win.renderPayPalButton(
        viewId,
        amount,
        (details) => onSuccess(details),
        (err) => onError(err.toString()),
        (data) => onCancel(data),
      );
    });

    return elem;
  });

  return HtmlElementView(viewType: viewId);
}
