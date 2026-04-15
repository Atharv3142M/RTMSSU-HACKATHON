import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ml_based_personal_finance_optimizer/frontend/admin_module/model/admin_model.dart';

class AdminController extends GetxController {
  // User related variables
  final RxList<AdminUser> users = <AdminUser>[].obs;
  final RxInt totalUsers = 0.obs;
  final RxInt activeUsers = 0.obs;
  final RxInt newUsers = 0.obs;
  final RxInt blockedUsers = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DateTime> lastUpdated = DateTime.now().obs;

  // For editing user
  final RxString currentEditingUserId = ''.obs;
  final userNameController = TextEditingController();
  final emailController = TextEditingController();

  // Base URL for API requests
  String baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    // Remove trailing space if present in the .env file
    baseUrl = (dotenv.env['BASE_URL'] ?? 'http://localhost:5000').trim();
    print('Using base URL: $baseUrl');
    fetchAllUsers();
  }

  @override
  void onClose() {
    userNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  // Fetch all users for admin dashboard
  Future<void> fetchAllUsers() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final apiUrl = '$baseUrl/api/users/getAllUsers'.replaceAll(" ", "");
      print('Fetching users from: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is List) {
            users.value = responseData.map((user) => AdminUser.fromJson(user)).toList();
            
            // Update statistics
            updateStatistics();
            
            // Update last updated timestamp
            lastUpdated.value = DateTime.now();
            
          } else {
            // Handle case where response is not a list
            hasError.value = true;
            errorMessage.value = 'Invalid response format: Expected a list of users';
            print('Invalid response format: $responseData');
          }
        } catch (e) {
          hasError.value = true;
          errorMessage.value = 'Error parsing response: ${e.toString()}';
          print('Error parsing response: ${response.body}');
        }
      } else {
        hasError.value = true;
        errorMessage.value = 'Failed to load users. Status code: ${response.statusCode}';
        print('API Error: ${response.body}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error fetching users: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Update dashboard statistics
  void updateStatistics() {
    totalUsers.value = users.length;
    blockedUsers.value = users.where((user) => user.isBlocked).length;
    
    // Calculate active users (users who aren't blocked)
    activeUsers.value = totalUsers.value - blockedUsers.value;
    
    // Calculate new users (joined in the last 7 days)
    final DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    newUsers.value = users.where((user) => user.createdAt.isAfter(oneWeekAgo)).length;
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      final apiUrl = '$baseUrl/api/users/deleteUser/$userId'.replaceAll(" ", "");
      print('Deleting user at URL: $apiUrl');
      
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Remove the deleted user from the list
        users.removeWhere((user) => user.id == userId);
        updateStatistics();
        
        Get.snackbar(
          'Success', 
          'User deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF89C2A5).withOpacity(0.7),
          colorText: const Color(0xFF15232D),
        );
      } else {
        Get.snackbar(
          'Error', 
          'Failed to delete user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF9999).withOpacity(0.7),
          colorText: const Color(0xFF15232D),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Something went wrong: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF9999).withOpacity(0.7),
        colorText: const Color(0xFF15232D),
      );
    }
  }
  
  // Block user functionality
  Future<void> toggleBlockUser(String userId, bool isBlocked) async {
    try {
      final apiUrl = '$baseUrl/api/users/updateUser/$userId'.replaceAll(" ", "");
      print('Toggling block for user at URL: $apiUrl');
      
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isBlocked': isBlocked}),
      );

      if (response.statusCode == 200) {
        // Update the user in the list
        final index = users.indexWhere((user) => user.id == userId);
        if (index != -1) {
          final updatedUser = users[index].copyWith(isBlocked: isBlocked);
          users[index] = updatedUser;
          updateStatistics();
        }
        
        Get.snackbar(
          'Success', 
          isBlocked ? 'User blocked successfully' : 'User unblocked successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF89C2A5).withOpacity(0.7),
          colorText: const Color(0xFF15232D),
        );
      } else {
        Get.snackbar(
          'Error', 
          'Failed to ${isBlocked ? 'block' : 'unblock'} user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF9999).withOpacity(0.7),
          colorText: const Color(0xFF15232D),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Something went wrong: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF9999).withOpacity(0.7),
        colorText: const Color(0xFF15232D),
      );
    }
  }
  
  // Prepare for editing user
  void prepareForEdit(AdminUser user) {
    currentEditingUserId.value = user.id;
    userNameController.text = user.userName;
    emailController.text = user.email;
  }
  
  // Edit user functionality
  Future<void> editUser() async {
    if (currentEditingUserId.value.isEmpty) return;
    
    try {
      // Show loading indicator
      isLoading.value = true;
      
      // Validate inputs
      if (userNameController.text.trim().isEmpty) {
        Get.snackbar(
          'Error', 
          'Username cannot be empty',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF9999).withOpacity(0.7),
          colorText: const Color(0xFF15232D),
        );
        isLoading.value = false;
        return;
      }
      
      if (emailController.text.trim().isEmpty || !emailController.text.contains('@')) {
        Get.snackbar(
          'Error', 
          'Please enter a valid email address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF9999).withOpacity(0.7),
          colorText: const Color(0xFF15232D),
        );
        isLoading.value = false;
        return;
      }
      
      // Debug print to verify the API request
      final userId = currentEditingUserId.value;
      final apiUrl = '$baseUrl/api/users/updateUser/$userId';
      final requestBody = {
        'userName': userNameController.text.trim(),
        'email': emailController.text.trim()
      };
      
      print('Updating user with ID: $userId');
      print('API URL: $apiUrl');
      print('Request body: ${jsonEncode(requestBody)}');
      
      // Make sure URL has no spaces that could cause issues
      final cleanUrl = apiUrl.replaceAll(" ", "");
      print('Clean URL: $cleanUrl');
      
      final response = await http.put(
        Uri.parse(cleanUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Update the user in the list
        final index = users.indexWhere((user) => user.id == currentEditingUserId.value);
        if (index != -1) {
          final updatedUser = users[index].copyWith(
            userName: userNameController.text.trim(),
            email: emailController.text.trim()
          );
          users[index] = updatedUser;
        }
        
        Get.snackbar(
          'Success', 
          'User updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF89C2A5).withOpacity(0.7),
          colorText: const Color(0xFF15232D),
        );
        
        // Reset editing state
        currentEditingUserId.value = '';
        userNameController.clear();
        emailController.clear();
      } else {
        Get.snackbar(
          'Error', 
          'Failed to update user: ${response.body}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF9999).withOpacity(0.7),
          colorText: const Color(0xFF15232D),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Something went wrong: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF9999).withOpacity(0.7),
        colorText: const Color(0xFF15232D),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh user data
  Future<void> refreshUsers() async {
    await fetchAllUsers();
  }
  
  // Check if email is blocked before user creation (to be used by auth controller)
  Future<bool> isEmailBlocked(String email) async {
    try {
      final apiUrl = '$baseUrl/api/users/checkBlocked?email=$email'.replaceAll(" ", "");
      print('Checking blocked status at URL: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isBlocked'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking if email is blocked: ${e.toString()}');
      return false;
    }
  }
} 