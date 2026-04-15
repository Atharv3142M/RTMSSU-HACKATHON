import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserProfileController extends GetxController {
  // Form controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  
  // Image state
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString profileImagePath = ''.obs;
  
  // Loading state
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  
  // User data
  final Rx<UserModel> user = UserModel().obs;
  
  // API base URL
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';
  
  // User ID from SharedPreferences
  final RxString userId = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    getUserIdFromSharedPreferences().then((_) {
      fetchUserDataFromBackend();
    });
  }
  
  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
  
  // Get userId from SharedPreferences
  Future<void> getUserIdFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedUserId = prefs.getString('userId');
      
      if (storedUserId != null && storedUserId.isNotEmpty) {
        userId.value = storedUserId;
        print('UserID loaded from SharedPreferences: ${userId.value}');
      } else {
        print('No userId found in SharedPreferences');
      }
    } catch (e) {
      print('Error getting userId from SharedPreferences: $e');
    }
  }
  
  // Fetch user data from backend based on userId
  Future<void> fetchUserDataFromBackend() async {
    if (userId.value.isEmpty) {
      print('Cannot fetch user data: userId is empty');
      loadUserData(); // Fallback to local data
      return;
    }
    
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/getAllUsers'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        
        // Find the user with matching ID
        final matchingUser = users.firstWhere(
          (user) => user['_id'] == userId.value,
          orElse: () => null,
        );
        
        if (matchingUser != null) {
          // Create UserModel from backend data using the new method
          user.value = UserModel.fromBackendJson(matchingUser);
          
          // Set the text controllers
          usernameController.text = user.value.username ?? '';
          emailController.text = user.value.email ?? '';
          phoneController.text = user.value.phoneNumber ?? '';
          
          // Load profile image if it exists
          if (user.value.profileImagePath != null && 
              user.value.profileImagePath!.isNotEmpty) {
            if (user.value.profileImagePath!.startsWith('http')) {
              // For remote images (URLs), we don't set selectedImage yet
              profileImagePath.value = user.value.profileImagePath!;
            } else if (File(user.value.profileImagePath!).existsSync()) {
              // For local images, set selectedImage if the file exists
              profileImagePath.value = user.value.profileImagePath!;
              selectedImage.value = File(profileImagePath.value);
            }
          }
          
          // Save the user data to shared preferences for offline access
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', user.value.toJsonString());
          
          print('User data fetched from backend successfully for userId: ${userId.value}');
        } else {
          print('User with ID ${userId.value} not found in backend');
          loadUserData(); // Fallback to local data
        }
      } else {
        print('Failed to fetch user data: ${response.statusCode}');
        print('Response body: ${response.body}');
        loadUserData(); // Fallback to local data
      }
    } catch (e) {
      print('Error fetching user data from backend: $e');
      loadUserData(); // Fallback to local data
    } finally {
      isLoading.value = false;
    }
  }
  
  // Load user data from shared preferences as fallback
  Future<void> loadUserData() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        user.value = UserModel.fromJsonString(userData);
        
        // Set the text controllers
        usernameController.text = user.value.username ?? '';
        emailController.text = user.value.email ?? '';
        phoneController.text = user.value.phoneNumber ?? '';
        
        // Set profile image path if it exists
        if (user.value.profileImagePath != null && 
            user.value.profileImagePath!.isNotEmpty &&
            File(user.value.profileImagePath!).existsSync()) {
          profileImagePath.value = user.value.profileImagePath!;
          selectedImage.value = File(profileImagePath.value);
        }
      } else {
        print('No user data found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Save user data to backend and shared preferences
  Future<void> saveUserData() async {
    isLoading.value = true;
    try {
      // Update user model with form values
      user.value = user.value.copyWith(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        profileImagePath: profileImagePath.value,
      );
      
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', user.value.toJsonString());
      
      // Update backend if we have a userId
      if (userId.value.isNotEmpty) {
        try {
          final response = await http.put(
            Uri.parse('$baseUrl/api/users/updateUser/${userId.value}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userName': user.value.username,
              'email': user.value.email,
              'phoneNumber': user.value.phoneNumber,
              // Only include profile image path if it's a URL (not a local path)
              if (user.value.profileImagePath != null && user.value.profileImagePath!.startsWith('http'))
                'profileImagePath': user.value.profileImagePath,
            }),
          );
          
          if (response.statusCode == 200) {
            print('User data updated in backend successfully');
          } else {
            print('Failed to update user in backend: ${response.statusCode}');
            print('Response body: ${response.body}');
          }
        } catch (e) {
          print('Error updating user in backend: $e');
        }
      }
      
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      isEditing.value = false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('Error saving user data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Pick image from gallery
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Save the image to app documents directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String filePath = '${appDocDir.path}/$fileName';
        
        // Copy the selected image to app directory
        await File(image.path).copy(filePath);
        
        // Update state
        selectedImage.value = File(filePath);
        profileImagePath.value = filePath;
        
        // Update user model
        user.value = user.value.copyWith(profileImagePath: filePath);
        
        // Save to shared preferences and backend
        saveUserData();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to select image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('Error picking image: $e');
    }
  }
  
  // Toggle editing mode
  void toggleEditingMode() {
    isEditing.value = !isEditing.value;
    
    if (!isEditing.value) {
      // If cancelling edit, restore values from user model
      usernameController.text = user.value.username ?? '';
      emailController.text = user.value.email ?? '';
      phoneController.text = user.value.phoneNumber ?? '';
    }
  }
  
  // Email validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }
  
  // Phone number validation
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    if (!GetUtils.isPhoneNumber(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
} 