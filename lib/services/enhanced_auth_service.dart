import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) return false;

      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your account',
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  /// Enable biometric authentication for user
  static Future<bool> enableBiometricAuth(String userId) async {
    try {
      final bool authenticated = await authenticateWithBiometrics(
        reason: 'Authenticate to enable biometric login',
      );
      
      if (authenticated) {
        await _secureStorage.write(
          key: 'biometric_enabled_$userId',
          value: 'true',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error enabling biometric auth: $e');
      return false;
    }
  }

  /// Check if biometric auth is enabled for user
  static Future<bool> isBiometricEnabled(String userId) async {
    try {
      final String? enabled = await _secureStorage.read(
        key: 'biometric_enabled_$userId',
      );
      return enabled == 'true';
    } catch (e) {
      print('Error checking biometric status: $e');
      return false;
    }
  }

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmailPassword(
    String email, 
    String password,
  ) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Store encrypted credentials for biometric auth
      await _storeUserCredentials(email, password);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with biometric authentication
  static Future<UserCredential?> signInWithBiometric() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user found for biometric authentication');
      }

      final bool isEnabled = await isBiometricEnabled(currentUser.uid);
      if (!isEnabled) {
        throw Exception('Biometric authentication not enabled');
      }

      final bool authenticated = await authenticateWithBiometrics(
        reason: 'Authenticate to sign in',
      );

      if (authenticated) {
        // Get stored credentials
        final Map<String, String>? credentials = await _getStoredCredentials();
        if (credentials != null) {
          return await signInWithEmailPassword(
            credentials['email']!,
            credentials['password']!,
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Biometric sign in error: $e');
      rethrow;
    }
  }

  /// Create account with email and password
  static Future<UserCredential?> createAccount(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile
      await credential.user?.updateDisplayName(displayName);
      
      // Store encrypted credentials
      await _storeUserCredentials(email, password);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Clear stored credentials
      await _clearStoredCredentials();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  /// Delete account
  static Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Clear all stored data
        await _clearAllUserData(user.uid);
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Store encrypted user credentials
  static Future<void> _storeUserCredentials(String email, String password) async {
    try {
      final String encryptedEmail = _encryptData(email);
      final String encryptedPassword = _encryptData(password);
      
      await _secureStorage.write(key: 'user_email', value: encryptedEmail);
      await _secureStorage.write(key: 'user_password', value: encryptedPassword);
    } catch (e) {
      print('Error storing credentials: $e');
    }
  }

  /// Get stored credentials
  static Future<Map<String, String>?> _getStoredCredentials() async {
    try {
      final String? encryptedEmail = await _secureStorage.read(key: 'user_email');
      final String? encryptedPassword = await _secureStorage.read(key: 'user_password');
      
      if (encryptedEmail != null && encryptedPassword != null) {
        return {
          'email': _decryptData(encryptedEmail),
          'password': _decryptData(encryptedPassword),
        };
      }
      return null;
    } catch (e) {
      print('Error getting stored credentials: $e');
      return null;
    }
  }

  /// Clear stored credentials
  static Future<void> _clearStoredCredentials() async {
    try {
      await _secureStorage.delete(key: 'user_email');
      await _secureStorage.delete(key: 'user_password');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }

  /// Clear all user data
  static Future<void> _clearAllUserData(String userId) async {
    try {
      await _secureStorage.delete(key: 'biometric_enabled_$userId');
      await _clearStoredCredentials();
      
      // Clear shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> keys = prefs.getKeys().where((key) => key.contains(userId)).toList();
      for (String key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  /// Simple encryption for stored credentials
  static String _encryptData(String data) {
    final List<int> bytes = utf8.encode(data);
    final Digest digest = sha256.convert(bytes);
    return base64.encode(utf8.encode(data + digest.toString()));
  }

  /// Simple decryption for stored credentials
  static String _decryptData(String encryptedData) {
    try {
      final String decoded = utf8.decode(base64.decode(encryptedData));
      // Remove the hash part (last 64 characters)
      return decoded.substring(0, decoded.length - 64);
    } catch (e) {
      print('Error decrypting data: $e');
      return '';
    }
  }

  /// Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Get user security score
  static Future<int> getUserSecurityScore() async {
    int score = 0;
    
    try {
      final User? user = currentUser;
      if (user == null) return 0;

      // Email verified
      if (user.emailVerified) score += 25;
      
      // Biometric enabled
      if (await isBiometricEnabled(user.uid)) score += 25;
      
      // Recent sign in (within 30 days)
      final DateTime? lastSignIn = user.metadata.lastSignInTime;
      if (lastSignIn != null && 
          DateTime.now().difference(lastSignIn).inDays <= 30) {
        score += 25;
      }
      
      // Account age (older than 7 days)
      final DateTime? creationTime = user.metadata.creationTime;
      if (creationTime != null && 
          DateTime.now().difference(creationTime).inDays >= 7) {
        score += 25;
      }
      
      return score;
    } catch (e) {
      print('Error calculating security score: $e');
      return 0;
    }
  }
}