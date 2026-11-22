import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

/// Helper class to convert exceptions into user-friendly error messages
class ErrorHandler {
  /// Convert FirebaseAuthException to user-friendly message
  static String handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email. Please register first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Invalid email format. Please check and try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password sign in is not enabled.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Please login instead.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'invalid-credential':
          return 'Invalid email or password. Please try again.';
        default:
          return 'Authentication error: ${error.message ?? "Unknown error"}';
      }
    }
    return 'An unexpected error occurred: $error';
  }

  /// Convert sentiment analysis exceptions to user-friendly messages
  static String handleSentimentError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socket') || errorStr.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (errorStr.contains('timeout')) {
      return 'Request took too long. Please try again.';
    } else if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return 'API key is invalid. Please check your configuration.';
    } else if (errorStr.contains('429') || errorStr.contains('rate')) {
      return 'Too many requests. Please wait a moment and try again.';
    } else if (errorStr.contains('json') || errorStr.contains('parse')) {
      return 'Failed to analyze sentiment. Please try again.';
    } else if (errorStr.contains('empty')) {
      return 'Please write something before analyzing mood.';
    }

    return 'Failed to analyze mood: $error';
  }

  /// Convert Firestore exceptions to user-friendly messages
  static String handleFirestoreError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) {
      return 'Permission denied. Please check your account access.';
    } else if (errorStr.contains('not found')) {
      return 'Data not found. Please try again.';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (errorStr.contains('offline')) {
      return 'Offline mode - changes will sync when online.';
    }

    return 'Database error: $error';
  }

  /// Generic error handler
  static String handle(dynamic error, {String context = ''}) {
    if (error is FirebaseAuthException) {
      return handleAuthError(error);
    } else if (error is SocketException) {
      return 'Connection error. Please check your network.';
    } else if (error.toString().contains('Sentiment')) {
      return handleSentimentError(error);
    } else if (error.toString().contains('Firestore')) {
      return handleFirestoreError(error);
    }

    return 'Error${context.isNotEmpty ? " in $context" : ""}: ${error.toString()}';
  }
}
