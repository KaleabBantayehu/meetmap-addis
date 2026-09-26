import 'package:flutter/foundation.dart';

Future<void> runBestEffortCleanup(
  Iterable<Future<void> Function()> operations,
) async {
  for (final operation in operations) {
    try {
      await operation();
    } catch (error) {
      debugPrint('Local account cleanup step failed: $error');
    }
  }
}
