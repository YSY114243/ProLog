import 'package:flutter/material.dart';

Widget buildPayPalButton({
  required String amount,
  required Function(dynamic) onSuccess,
  required Function(String) onError,
  required Function(dynamic) onCancel,
}) {
  return const Center(child: Text('PayPal Web is only available on Web platform.'));
}
