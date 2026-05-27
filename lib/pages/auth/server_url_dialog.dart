import 'package:flutter/material.dart';

import 'api_config.dart';

Future<bool> showServerUrlDialog(BuildContext context) async {
  final controller = TextEditingController(text: defaultApiBaseUrl);
  String? errorText;
  var didSave = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF12141A),
            title: const Text(
              'Server URL',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use your computer IP when testing on a phone, like http://192.168.1.10:8000.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.url,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'http://110.102.147.188:8000',
                    hintStyle: const TextStyle(color: Colors.white38),
                    errorText: errorText,
                    filled: true,
                    fillColor: const Color(0xFF0A0B0D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E2128)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00C5D9)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Start Django with: python backend/manage.py runserver 0.0.0.0:8000',
                  style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (!isValidApiBaseUrl(value)) {
                    setDialogState(() {
                      errorText = 'Enter a full http:// or https:// URL.';
                    });
                    return;
                  }

                  setApiBaseUrl(value);
                  didSave = true;
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00C5D9),
                  foregroundColor: const Color(0xFF0A0B0D),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return didSave;
}
