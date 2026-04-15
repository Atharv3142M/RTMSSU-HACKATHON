import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ml_based_personal_finance_optimizer/frontend/user_module/views/home_page.dart';

import '../../models/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpSignInController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  AuthModel authModel = AuthModel();

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    // Special case for admin login
    if (emailController.text == 'admin@gmail.com' && value == 'admin@123') {
      return null;
    }
    if (value.length <= 5) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  void signUp(GlobalKey<FormState> formKey) async {
    final SignUpSignInController controller = Get.find<SignUpSignInController>();
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      final user = await authModel.signUpWithEmail(emailController.text.trim(), passwordController.text);

      if(user != null) {
        print("Signup successful for email: ${emailController.text}");

        // Verify that userId is stored
        final prefs = await SharedPreferences.getInstance();
        final storedUserId = prefs.getString("userId");
        print("Stored userId after signup: $storedUserId");

        if (storedUserId == null || storedUserId.isEmpty) {
          print("WARNING: userId not found in SharedPreferences after successful signup");
          // Attempt to fetch it again as a last resort
          try {
            await Future.delayed(Duration(milliseconds: 500)); // Small delay to ensure backend operations complete
            final retryPrefs = await SharedPreferences.getInstance();
            final retryUserId = retryPrefs.getString("userId");
            print("Retry fetching userId: $retryUserId");
          } catch (e) {
            print("Error during retry fetch of userId: $e");
          }
        }

        // Navigate to homepage
        Get.off(HomePage());

        Get.snackbar(
          'Success',
          'Account created successfully!',
          backgroundColor: Get.theme.colorScheme.inversePrimary,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
      // If user is null, the AuthModel already showed an error snackbar
    } catch (e) {
      print("Error in signUp controller: $e");
      Get.snackbar(
        'Error',
        'Account creation failed: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void loginWithEmail(GlobalKey<FormState> formKey) async {
    final SignUpSignInController controller = Get.find<SignUpSignInController>();
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    // Check if admin credentials are used
    if (emailController.text == 'admin@gmail.com' && passwordController.text == 'admin@123') {
      // Redirect to admin dashboard
      isLoading.value = false;
      Get.offNamed('/admin-dashboard');
      Get.snackbar(
        'Admin Login',
        'Welcome to the Admin Dashboard',
        backgroundColor: Get.theme.colorScheme.inversePrimary,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      final user = await authModel.loginWithEmail(emailController.text.trim(), passwordController.text);
      if(user != null) {
        print("Login successful for email: ${emailController.text}");

        // Verify that userId is stored
        final prefs = await SharedPreferences.getInstance();
        final storedUserId = prefs.getString("userId");
        print("Stored userId after login: $storedUserId");

        if (storedUserId == null || storedUserId.isEmpty) {
          print("WARNING: userId not found in SharedPreferences after successful login");
          // Attempt to fetch it again as a last resort
          try {
            await Future.delayed(Duration(milliseconds: 500)); // Small delay to ensure backend operations complete
            final retryPrefs = await SharedPreferences.getInstance();
            final retryUserId = retryPrefs.getString("userId");
            print("Retry fetching userId: $retryUserId");
          } catch (e) {
            print("Error during retry fetch of userId: $e");
          }
        }

        // Navigate to homepage
        Get.off(HomePage());

        Get.snackbar(
          'Success',
          'Email sign in successful!',
          backgroundColor: Get.theme.colorScheme.inversePrimary,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      } else {
        Get.snackbar(
          'Error',
          'Email sign in failed!',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      print("Error in loginWithEmail: $e");
      Get.snackbar(
        'Error',
        'Email sign in failed!',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void googleSignUp() async {
    isLoading.value = true;

    try {
      final user = await authModel.loginWithGoogle();

      if(user != null) {
        // Verify that userId is stored
        final prefs = await SharedPreferences.getInstance();
        final storedUserId = prefs.getString("userId");
        print("Stored userId after Google sign-in: $storedUserId");

        if (storedUserId == null) {
          print("WARNING: userId not found in SharedPreferences after successful Google sign-in");
          Get.snackbar(
            'Warning',
            'User ID not found. Some features might not work properly.',
            backgroundColor: Get.theme.colorScheme.errorContainer,
            colorText: Get.theme.colorScheme.onErrorContainer,
            snackPosition: SnackPosition.BOTTOM,
            borderRadius: 12,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          );
        }

        // Navigate to homepage
        Get.off(HomePage());

        Get.snackbar(
          'Success',
          'Google sign in successful!',
          backgroundColor: Get.theme.colorScheme.inversePrimary,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      } else {
        Get.snackbar(
          'Error',
          'Google sign in failed!',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      print("Error in googleSignUp controller: $e");
      Get.snackbar(
        'Error',
        'Google sign in failed: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
