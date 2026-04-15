import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

  AuthModel() {
    final explicitServerClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
        dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: explicitServerClientId,
    );
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      // Check if email is blocked before trying to create an account
      final isBlocked = await checkIfEmailBlocked(email);
      if (isBlocked) {
        Get.snackbar(
          'Error',
          'This email has been blocked by administrator',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      
      // Create user in Firebase
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Extract username from email (before @ symbol)
      final String userName = email.contains('@') 
          ? email.split('@')[0] 
          : email;
      
      // Create user in your backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/addUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'email': email,
          'password': password,
        }),
      );

      // Log the response for debugging
      print('Backend addUser response: ${response.statusCode} - ${response.body}');
      Map<String, dynamic> jsonMap = json.decode(response.body);

      // Access the _id
      String userId = jsonMap['userData']['_id'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("userId", userId);

      // If the backend user creation failed
      if (response.statusCode != 201) {
        print('Failed to store user in database: ${response.body}');
        
        // Try to delete the Firebase user if we couldn't create the backend user
        try {
          await userCredential.user?.delete();
          Get.snackbar(
            'Error',
            'User registration failed: Could not create user record',
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
            snackPosition: SnackPosition.BOTTOM,
          );
          return null;
        } catch (deleteError) {
          // If we can't delete the Firebase user, just log the error
          print("Error deleting Firebase user after backend failure: $deleteError");
        }
      }
      
      return userCredential.user;
    } catch (e) {
      print("Error in signUpWithEmail: $e");
      Get.snackbar(
        'Error',
        'Registration failed: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
  
  Future<bool> checkIfEmailBlocked(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/checkBlocked?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isBlocked'] ?? false;
      }
      return false;
    } catch (e) {
      print("Error checking if email is blocked: $e");
      return false;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      // Check if email is blocked
      final isBlocked = await checkIfEmailBlocked(email);
      if (isBlocked) {
        Get.snackbar(
          'Error',
          'This email has been blocked by administrator',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      
      // Sign in with Firebase
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Fetch user from backend based on email and store userId
      try {
        print('Fetching user ID for email: $email');
        final response = await http.get(
          Uri.parse('$baseUrl/api/users/getAllUsers'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final List<dynamic> users = json.decode(response.body);
          
          // Find user with matching email
          for (var user in users) {
            if (user['email'] == email) {
              // Found matching user, store the ID
              final String userId = user['_id'];
              print('Found userId: $userId for email: $email');
              
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("userId", userId);
              print('Successfully stored userId in SharedPreferences');
              break;
            }
          }
        } else {
          print('Failed to fetch users: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching user ID: $e');
      }
      
      return userCredential.user;
    } catch (e) {
      print("Error in loginWithEmail: $e");
      Get.snackbar(
        'Error',
        'Login failed: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
  
  // Use getAllUsers endpoint to find the user by email
  Future<void> _fetchUserIdUsingAllUsers(String email) async {
    try {
      print('Fetching user ID for email: $email');
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/getAllUsers'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        dynamic foundUser;
        
        // Find user with matching email
        try {
          foundUser = users.firstWhere(
            (user) => user['email'] == email,
            orElse: () => null,
          );
        } catch (e) {
          // Manual search if firstWhere with orElse fails
          foundUser = null;
          for (var user in users) {
            if (user['email'] == email) {
              foundUser = user;
              break;
            }
          }
        }
        
        if (foundUser != null && foundUser['_id'] != null) {
          String userId = foundUser['_id'];
          print('Successfully found userId: $userId for email: $email');
          
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userId", userId);
          print('Stored userId in SharedPreferences: $userId');
        } else {
          print('User not found in getAllUsers response for email: $email');
        }
      } else {
        print('Failed to fetch all users, status: ${response.statusCode}, response: ${response.body}');
      }
    } catch (e) {
      print('Error finding user by email: $e');
    }
  }

  Future<User?> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        // Check if email is blocked
        final isBlocked = await checkIfEmailBlocked(googleSignInAccount.email);
        if (isBlocked) {
          Get.snackbar(
            'Error',
            'This email has been blocked by administrator',
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
            snackPosition: SnackPosition.BOTTOM,
          );
          await _googleSignIn.signOut();
          return null;
        }
        
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        if (googleSignInAuthentication.idToken == null) {
          final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
          final hasServerId = (dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
                  dotenv.env['GOOGLE_SERVER_CLIENT_ID']) !=
              null;
          final message = isAndroid && !hasServerId
              ? 'Google sign-in failed on Android: missing server client ID. Add GOOGLE_WEB_CLIENT_ID in .env and ensure Firebase Android OAuth SHA keys are configured.'
              : 'Google sign-in failed: no ID token returned by Google.';
          Get.snackbar(
            'Error',
            message,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 6),
          );
          return null;
        }
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        
        // Extract username from email (before @gmail.com)
        final String userName = googleSignInAccount.displayName ?? 
            (googleSignInAccount.email.contains('@') 
                ? googleSignInAccount.email.split('@')[0] 
                : googleSignInAccount.email);
        
        // Generate a random password for backend storage
        final String randomPassword = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Check if user exists in your backend, if not create one
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/api/users/addUser'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userName': userName,
              'email': googleSignInAccount.email,
              'password': randomPassword, // Using a random password for backend storage
            }),
          );
          
          // Log the response for debugging
          print('Backend addUser response: ${response.statusCode} - ${response.body}');
          
          // Store the user ID in SharedPreferences
          try {
            final Map<String, dynamic> jsonMap = json.decode(response.body);
            
            // Handle case where user is created successfully (201 status)
            if (response.statusCode == 201 && jsonMap.containsKey('userData') && jsonMap['userData'] != null) {
              String userId = jsonMap['userData']['_id'];
              print('Successfully extracted userId: $userId from Google sign-in');
              
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("userId", userId);
              print('Stored userId: $userId in SharedPreferences');
            } 
            // Handle case where user already exists (400 status)
            else if ((response.statusCode == 400 || response.statusCode == 409) && 
                     jsonMap.containsKey('message') && 
                     (jsonMap['message'] == 'User already exists' || 
                      jsonMap['message'].toString().contains('already exists'))) {
              
              print('User already exists, fetching user ID from existing users');
              await _fetchUserIdUsingAllUsers(googleSignInAccount.email);
            } 
            // Any other response
            else {
              print('Response does not contain userData or _id: ${response.body}');
              // Try to fetch user ID as a fallback
              await _fetchUserIdUsingAllUsers(googleSignInAccount.email);
            }
          } catch (e) {
            print('Error processing backend response: $e');
            // Try to fetch user ID as a fallback
            await _fetchUserIdUsingAllUsers(googleSignInAccount.email);
          }
        } catch (e) {
          print('Error adding user to backend: $e');
          // Try to fetch user ID as a fallback
          await _fetchUserIdUsingAllUsers(googleSignInAccount.email);
        }
        
        // Verify that we successfully stored the userId
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? storedUserId = prefs.getString("userId");
        print('Final check - userId in SharedPreferences: $storedUserId');
        
        return userCredential.user;
      }
    } catch (e) {
      print("Error in loginWithGoogle: $e");
      Get.snackbar(
        'Error',
        'Google sign in failed: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return null;
  }
  
  // Helper method to fetch user ID by email and store it
  Future<void> _fetchAndStoreUserIdByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/getUserByEmail?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        if (jsonMap.containsKey('user') && jsonMap['user'] != null && jsonMap['user']['_id'] != null) {
          String userId = jsonMap['user']['_id'];
          print('Successfully fetched userId: $userId for email: $email');
          
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userId", userId);
        } else {
          print('User data not found in response: ${response.body}');
        }
      } else {
        print('Failed to fetch user by email, status: ${response.statusCode}, response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user by email: $e');
    }
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }
}