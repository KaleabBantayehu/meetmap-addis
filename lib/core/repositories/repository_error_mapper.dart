import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

String mapRepositoryError(Object error, String fallbackMessage) {
  if (error is TimeoutException) {
    return 'Request timed out';
  }

  if (error is SocketException || error is HttpException) {
    return 'Network unavailable';
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Permission denied',
      'network-request-failed' || 'unavailable' => 'Network unavailable',
      'deadline-exceeded' => 'Request timed out',
      _ => fallbackMessage,
    };
  }

  final message = error.toString();
  if (message.contains('TimeoutException')) {
    return 'Request timed out';
  }
  if (message.contains('SocketException') || message.contains('Network')) {
    return 'Network unavailable';
  }
  if (message.contains('permission-denied')) {
    return 'Permission denied';
  }

  return fallbackMessage;
}

String cleanExceptionMessage(Object error, String fallbackMessage) {
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  if (message.isEmpty) return fallbackMessage;
  if (message.contains('FirebaseException') ||
      message.contains('TimeoutException') ||
      message.contains('SocketException') ||
      message.contains('StackTrace')) {
    return fallbackMessage;
  }
  return message;
}
