import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ml_based_personal_finance_optimizer/frontend/user_module/controllers/theme_controller/theme_controller.dart';
import 'package:ml_based_personal_finance_optimizer/frontend/user_module/services/notification_service.dart';
import '../../models/transaction_model.dart';
import '../../controllers/user_profile_controller.dart';

class UserProfileView extends StatelessWidget {
  UserProfileView({Key? key}) : super(key: key);

  final UserProfileController controller = Get.put(UserProfileController());
  final ThemeController themeController = Get.find<ThemeController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final _formKey = GlobalKey<FormState>(); // Made static to avoid GlobalKey conflicts


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Theme Toggle Button
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              themeController.toggleTheme();
            },
          ),
          Obx(() => controller.isEditing.value
              ? IconButton(
            icon: Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                controller.saveUserData();
              }
            },
          )
              : IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: controller.toggleEditingMode,
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.chat),
        onPressed: () {
          Get.toNamed('/chatbot');
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                _buildProfileImageSection(context),
                const SizedBox(height: 30),

                // Profile Details Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username Field
                        _buildTextField(
                          controller: controller.usernameController,
                          label: 'Username',
                          icon: Icons.person,
                          enabled: controller.isEditing.value,
                          context: context,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          controller: controller.emailController,
                          label: 'Email',
                          icon: Icons.email,
                          enabled: controller.isEditing.value,
                          context: context,
                          validator: controller.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Phone Field
                        _buildTextField(
                          controller: controller.phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          enabled: controller.isEditing.value,
                          context: context,
                          validator: controller.validatePhone,
                          keyboardType: TextInputType.phone,
                        ),

                        // Account Status
                        Obx(() => controller.user.value.isBlocked != null
                            ? Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                controller.user.value.isBlocked!
                                    ? Icons.block
                                    : Icons.check_circle,
                                color: controller.user.value.isBlocked!
                                    ? Colors.red
                                    : Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Account Status: ${controller.user.value.isBlocked! ? 'Blocked' : 'Active'}',
                                style: TextStyle(
                                  color: controller.user.value.isBlocked!
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                            : const SizedBox.shrink()),

                        // Account Creation Date
                        Obx(() => controller.user.value.createdAt != null
                            ? Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Account Created: ${_formatDate(controller.user.value.createdAt!)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                            : const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Edit/Save Button
                if (controller.isEditing.value)
                  TextButton(
                    onPressed: controller.toggleEditingMode,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel'),
                  ),

                // App Settings Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Theme Toggle Button
                        _buildThemeButton(context),
                        
                        const SizedBox(height: 24),
                        
                        // Test Notifications Section
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.notifications_active, size: 18),
                              label: Text('Test Immediate'),
                              onPressed: () async {
                                bool success = await NotificationService.sendTestNotification();
                                Get.snackbar(
                                  success ? 'Success' : 'Failed',
                                  success 
                                    ? 'Immediate test notification sent' 
                                    : 'Failed to send test notification',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: success ? Colors.green : Colors.red,
                                  colorText: Colors.white,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.timer, size: 18),
                              label: Text('Test 5s Delay'),
                              onPressed: () async {
                                // Create a test transaction
                                final testTransaction = TransactionModel(
                                  userId: 'test_user',
                                  amount: 100.0,
                                  description: 'Test Transaction',
                                  category: 'food',
                                  isExpense: true,
                                  transactionDate: DateTime.now(),
                                  isRecurring: true,
                                  recurringDuration: 30,
                                );
                                
                                bool success = await NotificationService.scheduleRecurringTransaction(
                                  transaction: testTransaction,
                                  durationInDays: 30,
                                  isTestMode: true,
                                );
                                
                                Get.snackbar(
                                  success ? 'Success' : 'Failed',
                                  success 
                                    ? 'Test notification scheduled (5 sec)' 
                                    : 'Failed to schedule test notification',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: success ? Colors.green : Colors.red,
                                  colorText: Colors.white,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const SizedBox(height: 100), // Extra space for bottom navigation
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: _buildModernBottomNav(context),
    );
  }

  // Show Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              const Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Get.offAllNamed('/signup');
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Perform Logout Operation
  Future _performLogout() async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Clear GetX controllers AFTER navigation
      Get.deleteAll();

      // Navigate to login page and clear all previous routes
      Get.offAllNamed('/login'); // Use /login instead of /signup

      // Show success message
      Get.snackbar(
        'Success',
        'You have been logged out successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Error handling...
    }
  }


  // Theme Button Widget (existing code)
  Widget _buildThemeButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDark ? 'Dark mode enabled' : 'Light mode enabled',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              themeController.toggleTheme();
            },
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 18,
            ),
            label: Text(isDark ? 'Light' : 'Dark'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Rest of your existing methods remain the same...
  Widget _buildModernBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withOpacity(0.7)
                : Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomAppBar(
            elevation: 0,
            color: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 12,
            height: 90,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ModernBottomNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: false,
                    theme: theme,
                    onTap: () {
                      Get.offNamed('/homePage');
                    },
                  ),
                  _ModernBottomNavItem(
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics_rounded,
                    label: 'Analytics',
                    isActive: false,
                    theme: theme,
                    onTap: () {
                      Get.offNamed('/analysis');
                    },
                  ),
                  _ModernBottomNavItem(
                    icon: Icons.flag_outlined,
                    activeIcon: Icons.flag_rounded,
                    label: 'Goals',
                    isActive: false,
                    theme: theme,
                    onTap: () {
                      Get.offNamed('/goals');
                    },
                  ),
                  _ModernBottomNavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    isActive: true,
                    theme: theme,
                    onTap: () {
                      Get.offNamed('/user-profile');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          return Stack(
            children: [
              GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: controller.selectedImage.value != null
                        ? Image.file(
                      controller.selectedImage.value!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: controller.pickImage,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.background,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 12),
        Obx(() => Text(
          controller.user.value.username ?? 'Set your username',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        )),
        const SizedBox(height: 4),
        Obx(() => Text(
          controller.user.value.email ?? 'Add your email',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        )),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required BuildContext context,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ModernBottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ModernBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final backgroundColor = isActive
        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
        : Colors.transparent;
    final borderColor = isActive
        ? theme.colorScheme.primary.withOpacity(0.4)
        : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
