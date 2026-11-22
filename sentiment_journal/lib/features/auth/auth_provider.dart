import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Current user stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Current logged-in user data provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        return Stream.value(
          UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            createdAt: user.metadata.creationTime ?? DateTime.now(),
          ),
        );
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Auth notifier for async operations
class AuthNotifier extends AsyncNotifier<void> {
  late FirebaseAuth _auth;

  @override
  Future<void> build() async {
    _auth = ref.watch(firebaseAuthProvider);
  }

  /// Register with email and password
  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  /// Logout
  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signOut();
    });
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  () => AuthNotifier(),
);
