import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  static bool testMode = false;
  final dynamic _auth = (kIsWeb || testMode) ? FakeFirebaseAuth() : FirebaseAuth.instance;
  final dynamic _googleSignIn = (kIsWeb || testMode) ? FakeGoogleSignIn() : GoogleSignIn();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isGuest = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _currentUser != null || _isGuest;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool('is_guest') ?? false;

      // Monitor Firebase auth state
      _auth.authStateChanges().listen((dynamic firebaseUser) {
        if (firebaseUser != null && !_isGuest) {
          _currentUser = UserModel(
            uid: firebaseUser.uid,
            displayName: firebaseUser.displayName ?? 'NEET Student',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          );
        } else {
          if (!_isGuest) {
            _currentUser = null;
          }
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dynamic credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        _isGuest = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest', false);

        _currentUser = UserModel(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? 'NEET Student',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUpWithEmail(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dynamic credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(name);
        await firebaseUser.reload();
        
        final updatedUser = _auth.currentUser;
        _isGuest = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest', false);

        if (updatedUser != null) {
          _currentUser = UserModel(
            uid: updatedUser.uid,
            displayName: updatedUser.displayName ?? name,
            email: updatedUser.email ?? '',
            photoUrl: updatedUser.photoURL,
            createdAt: updatedUser.metadata.creationTime ?? DateTime.now(),
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dynamic googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User cancelled the sign-in
      }

      final dynamic googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final dynamic userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        _isGuest = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest', false);

        _currentUser = UserModel(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? googleUser.displayName ?? 'NEET Student',
          email: firebaseUser.email ?? googleUser.email,
          photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('PlatformException(10') || 
          errStr.toLowerCase().contains('developer') || 
          errStr.contains('DEVELOPER_ERROR')) {
        _errorMessage = 'Configuration error: Please ensure Google Play App Signing SHA-1 fingerprint is added to your Firebase project settings.';
      } else {
        _errorMessage = errStr;
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void loginAsGuest() async {
    _isLoading = true;
    notifyListeners();

    _isGuest = true;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}

    _isGuest = false;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);

    _isLoading = false;
    notifyListeners();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email address.';
      case 'wrong-password':
        return 'Incorrect password provided.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

class FakeFirebaseAuth {
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();
  dynamic _currentUser;

  FakeFirebaseAuth() {
    _controller.add(null);
  }

  Stream<dynamic> authStateChanges() => _controller.stream;
  dynamic get currentUser => _currentUser;

  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  Future<dynamic> signInWithEmailAndPassword({required String email, required String password}) async {
    final fakeUser = FakeUser(
      uid: 'fake_uid_${email.hashCode}',
      email: email,
      displayName: email.split('@')[0],
    );
    _currentUser = fakeUser;
    _controller.add(fakeUser);
    return FakeUserCredential(fakeUser);
  }

  Future<dynamic> createUserWithEmailAndPassword({required String email, required String password}) async {
    final fakeUser = FakeUser(
      uid: 'fake_uid_${email.hashCode}',
      email: email,
      displayName: email.split('@')[0],
    );
    _currentUser = fakeUser;
    _controller.add(fakeUser);
    return FakeUserCredential(fakeUser);
  }

  Future<dynamic> signInWithCredential(dynamic credential) async {
    final fakeUser = FakeUser(
      uid: 'fake_uid_google',
      email: 'notesmedicose@gmail.com',
      displayName: 'Admin User',
    );
    _currentUser = fakeUser;
    _controller.add(fakeUser);
    return FakeUserCredential(fakeUser);
  }
}

class FakeUser {
  final String uid;
  String? displayName;
  final String? email;
  final String? photoURL;
  final FakeUserMetadata metadata = FakeUserMetadata();

  FakeUser({required this.uid, this.displayName, this.email, this.photoURL});

  Future<void> updateDisplayName(String name) async {
    displayName = name;
  }

  Future<void> reload() async {}
}

class FakeUserMetadata {
  final DateTime creationTime = DateTime.now();
}

class FakeUserCredential {
  final FakeUser user;
  FakeUserCredential(this.user);
}

class FakeGoogleSignIn {
  Future<dynamic> signIn() async => FakeGoogleSignInAccount();
  Future<void> signOut() async {}
}

class FakeGoogleSignInAccount {
  final String id = 'fake_google_id';
  final String displayName = 'Admin User';
  final String email = 'notesmedicose@gmail.com';
  final String? photoUrl = null;
  Future<dynamic> get authentication async => FakeGoogleSignInAuthentication();
}

class FakeGoogleSignInAuthentication {
  final String accessToken = 'fake_access_token';
  final String idToken = 'fake_id_token';
}
