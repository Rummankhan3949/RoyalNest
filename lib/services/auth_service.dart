import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'session_cache_service.dart';

/// Authentication service for both admin and client
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SessionCacheService _sessionCacheService = SessionCacheService();

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  bool _requiresEmailVerification(User user) {
    final usesPassword = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    return usesPassword && !_isAdminUser(user);
  }

  bool _isAdminUser(User user) {
    final email = user.email?.trim().toLowerCase() ?? '';
    return email == AppConstants.adminEmail.toLowerCase();
  }

  /// Check if credentials are admin credentials
  bool isAdminCredentials(String email, String password) {
    return email.trim().toLowerCase() ==
            AppConstants.adminEmail.toLowerCase() &&
        password.trim() == AppConstants.adminPassword;
  }

  /// Admin login using Firebase Auth (email/password)
  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      // Enforce configured admin credentials
      if (!isAdminCredentials(email, password)) {
        return {'success': false, 'message': 'Invalid admin credentials'};
      }

      final normalizedAdminEmail = AppConstants.adminEmail.trim().toLowerCase();
      final normalizedAdminPassword = AppConstants.adminPassword.trim();

      // Sign in the admin to Firebase so request.auth is present for Firestore rules
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedAdminEmail,
        password: normalizedAdminPassword,
      );

      final user = credential.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'Admin sign-in failed. User not available.',
        };
      }

      // Ensure admin user document exists with role=admin
      await _ensureAdminUserRecord(user);
      await _cacheSession(role: AppConstants.roleAdmin);

      return {
        'success': true,
        'message': 'Admin login successful',
        'role': AppConstants.roleAdmin,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Admin login failed';
      if (e.code == 'user-not-found') {
        message = 'Admin account is not configured in Firebase Auth.';
      } else if (e.code == 'wrong-password') {
        message = 'Invalid admin credentials';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid admin credentials';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  /// Client login with Firebase
  Future<Map<String, dynamic>> clientLogin(
    String email,
    String password,
  ) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final adminEmail = AppConstants.adminEmail.toLowerCase();

      if (normalizedEmail == adminEmail) {
        return {
          'success': false,
          'code': 'admin-email-restricted',
          'message':
              'Use admin credentials to login as admin. This email is reserved for admin access only.',
        };
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        await credential.user!.reload();
        final refreshedUser = _auth.currentUser;
        if (refreshedUser == null) {
          return {
            'success': false,
            'message': 'Session expired. Please login again.',
          };
        }

        if (_requiresEmailVerification(refreshedUser) &&
            !refreshedUser.emailVerified) {
          return {
            'success': false,
            'code': 'email-not-verified',
            'message': 'Please verify your email before logging in',
          };
        }

        // Wait a bit for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if user exists in Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(refreshedUser.uid)
            .get();

        if (userDoc.exists) {
          await _cacheSession(role: AppConstants.roleClient);
          return {
            'success': true,
            'message': 'Login successful',
            'role': AppConstants.roleClient,
            'user': UserModel.fromMap(userDoc.data()!),
          };
        } else {
          // User authenticated but no Firestore record - create one
          final userModel = UserModel(
            uid: refreshedUser.uid,
            username: refreshedUser.displayName ?? 'User',
            email: refreshedUser.email ?? email.trim(),
            cnic: '',
            role: AppConstants.roleClient,
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(refreshedUser.uid)
              .set(userModel.toMap());
          await _cacheSession(role: AppConstants.roleClient);
          return {
            'success': true,
            'message': 'Login successful',
            'role': AppConstants.roleClient,
            'user': userModel,
          };
        }
      }

      return {'success': false, 'message': 'User not found'};
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      }
      return {'success': false, 'message': message};
    } on FirebaseException catch (e) {
      // Handle Firestore permission errors
      if (e.code == 'permission-denied') {
        return {
          'success': false,
          'message':
              'Database access denied. Please contact support to configure Firestore security rules.',
        };
      }
      return {'success': false, 'message': 'Database error: ${e.message}'};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Client signup
  Future<Map<String, dynamic>> clientSignup({
    required String username,
    required String cnic,
    required String email,
    required String password,
  }) async {
    try {
      // Check if trying to signup with admin email
      if (email.trim().toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
        return {'success': false, 'message': 'This email is reserved'};
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(username);
        // Reload user to get updated info
        await user.reload();
        await sendVerificationEmail();

        final userModel = UserModel(
          uid: user.uid,
          username: username.trim(),
          email: user.email ?? email.trim(),
          cnic: cnic.trim(),
          role: AppConstants.roleClient,
          createdAt: DateTime.now(),
        );

        // Save to Firestore with retry logic
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
        } catch (firestoreError) {
          // If Firestore fails, still return success as auth succeeded
          // The login will create the document if needed
          return {
            'success': true,
            'message': 'Account created. Verification email has been sent.',
            'requiresEmailVerification': true,
            'user': userModel,
          };
        }

        return {
          'success': true,
          'message': 'Account created. Verification email has been sent.',
          'requiresEmailVerification': true,
          'user': userModel,
        };
      }

      return {'success': false, 'message': 'Failed to create account'};
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetLink(String email) async {
    final trimmedEmail = email.trim();
    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return {
        'success': true,
        'message': 'Password reset link sent to your email',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset link.';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email address.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many requests. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your connection.';
      }
      return {'success': false, 'message': message};
    } catch (_) {
      return {
        'success': false,
        'message': 'Unable to send reset link. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No signed-in user found.'};
      }

      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      }

      if (!_requiresEmailVerification(refreshedUser)) {
        return {'success': true, 'message': 'No email verification required.'};
      }

      if (refreshedUser.emailVerified) {
        return {'success': true, 'message': 'Email already verified.'};
      }

      await refreshedUser.sendEmailVerification();
      return {
        'success': true,
        'message': 'A verification link has been sent to your email.',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send verification email.';
      if (e.code == 'too-many-requests') {
        message = 'Too many requests. Please wait and try again.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      }
      return {'success': false, 'message': message};
    } catch (_) {
      return {
        'success': false,
        'message': 'Unable to send verification email. Please try again.',
      };
    }
  }

  Future<bool> isCurrentUserEmailVerified({bool reload = true}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    if (!_requiresEmailVerification(user)) {
      return true;
    }

    if (reload) {
      await user.reload();
    }

    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<String> resolveStartupRoute() async {
    final user = _auth.currentUser;
    if (user == null) {
      return '/login';
    }

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      return '/login';
    }

    if (_requiresEmailVerification(refreshedUser) &&
        !refreshedUser.emailVerified) {
      return '/verify-email';
    }

    return _isAdminUser(refreshedUser) ? '/admin-home' : '/client-main';
  }

  /// Logout (handles both Firebase and Google)
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      // Verify sign out was successful
      if (_auth.currentUser != null) {
        throw Exception('Logout failed - user still authenticated');
      }
      await _sessionCacheService.clearSession();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheSession({required String role}) async {
    await _sessionCacheService.saveSession(isLoggedIn: true, role: role);
  }

  /// Alias for logout to match UI calls
  Future<void> signOut() => logout();

  /// Get current user details from Firestore
  Future<UserModel?> getCurrentUserDetails() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change password with re-authentication
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return {'success': true, 'message': 'Password updated successfully'};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Failed to change password',
      };
    } catch (_) {
      return {'success': false, 'message': 'Failed to change password'};
    }
  }

  /// Google Sign-In for admin (must use configured admin email)
  Future<Map<String, dynamic>> adminLoginWithGoogle() async {
    final result = await authenticateWithGoogle(isSignupMode: false);
    if (result['success'] == true && result['role'] != AppConstants.roleAdmin) {
      return {
        'success': false,
        'message':
            'Only the admin email can login as admin. Please use ${AppConstants.adminEmail}',
      };
    }
    return result;
  }

  /// Ensure admin Firestore document exists with correct role
  Future<void> _ensureAdminUserRecord(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.set({
        'role': AppConstants.roleAdmin,
        'email': user.email ?? AppConstants.adminEmail,
        'username': user.displayName ?? 'Admin',
      }, SetOptions(merge: true));
    } else {
      await docRef.set({
        'uid': user.uid,
        'email': user.email ?? AppConstants.adminEmail,
        'username': user.displayName ?? 'Admin',
        'role': AppConstants.roleAdmin,
        'cnic': '',
        'createdAt': DateTime.now(),
      });
    }
  }

  /// Google Sign-In for client (login or signup)
  Future<Map<String, dynamic>> clientLoginWithGoogle() async {
    return authenticateWithGoogle(isSignupMode: false);
  }

  Future<Map<String, dynamic>> authenticateWithGoogle({
    required bool isSignupMode,
  }) async {
    try {
      final activeUser = _auth.currentUser;
      if (activeUser != null &&
          activeUser.providerData.any((p) => p.providerId == 'google.com')) {
        final isAdmin = _isAdminUser(activeUser);
        if (isAdmin) {
          if (isSignupMode) {
            await _auth.signOut();
            return {
              'success': false,
              'message': 'This email cannot be used for client signup',
            };
          }

          await _ensureAdminUserRecord(activeUser);
          await _cacheSession(role: AppConstants.roleAdmin);
          return {
            'success': true,
            'message': 'Admin login with Google successful',
            'role': AppConstants.roleAdmin,
            'isNewUser': false,
          };
        }

        final existingClientDoc = await _firestore
            .collection('users')
            .doc(activeUser.uid)
            .get();
        if (!existingClientDoc.exists) {
          final userModel = UserModel(
            uid: activeUser.uid,
            username: activeUser.displayName ?? 'User',
            email: activeUser.email ?? '',
            cnic: '',
            role: AppConstants.roleClient,
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(activeUser.uid)
              .set(userModel.toMap());
        }

        await _cacheSession(role: AppConstants.roleClient);
        return {
          'success': true,
          'message': 'Login successful',
          'role': AppConstants.roleClient,
          'isNewUser': false,
        };
      }

      final googleUser =
          await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'cancelled': true,
          'message': 'Google sign-in cancelled',
        };
      }

      final email = googleUser.email.trim();
      final adminEmail = AppConstants.adminEmail.toLowerCase();
      final isAdminEmail = email.toLowerCase() == adminEmail;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        if (isAdminEmail) {
          if (isSignupMode) {
            await _auth.signOut();
            return {
              'success': false,
              'message': 'This email cannot be used for client signup',
            };
          }

          await _ensureAdminUserRecord(firebaseUser);
          await _cacheSession(role: AppConstants.roleAdmin);
          return {
            'success': true,
            'message': 'Admin login with Google successful',
            'role': AppConstants.roleAdmin,
            'isNewUser': false,
          };
        }

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if user exists in Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          // Existing user login
          await _cacheSession(role: AppConstants.roleClient);
          return {
            'success': true,
            'message': 'Login successful',
            'role': AppConstants.roleClient,
            'isNewUser': false,
            'user': UserModel.fromMap(userDoc.data()!),
          };
        } else {
          // New user signup with Google - create the account
          final userModel = UserModel(
            uid: firebaseUser.uid,
            username: googleUser.displayName ?? 'User',
            email: email,
            cnic: '',
            role: AppConstants.roleClient,
            createdAt: DateTime.now(),
          );

          try {
            await _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .set(userModel.toMap());
          } catch (firestoreError) {
            // If Firestore fails, still return success as auth succeeded
            await _cacheSession(role: AppConstants.roleClient);
            return {
              'success': true,
              'message': 'Account created successfully',
              'role': AppConstants.roleClient,
              'isNewUser': true,
              'user': userModel,
            };
          }

          await _cacheSession(role: AppConstants.roleClient);
          return {
            'success': true,
            'message': 'Account created successfully',
            'role': AppConstants.roleClient,
            'isNewUser': true,
            'user': userModel,
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to authenticate with Google',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Google sign-in failed';
      if (e.code == 'account-exists-with-different-credential') {
        message =
            'An account already exists with this email but different sign-in method';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid Google credentials';
      } else if (e.code == 'email-already-in-use') {
        message =
            'An account already exists with this email. Please login instead.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Google sign-in error: ${e.toString()}',
      };
    }
  }

  /// Sign out from Google (also signs out from Firebase)
  Future<void> googleSignOut() async {
    await logout();
  }
}
