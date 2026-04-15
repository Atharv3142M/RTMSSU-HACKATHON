import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ml_based_personal_finance_optimizer/frontend/admin_module/model/admin_model.dart';
import 'package:ml_based_personal_finance_optimizer/frontend/user_module/utils/app_themes/app_theme.dart';
import '../../controllers/admin_controller/admin_controller.dart';

import 'package:intl/intl.dart';
import 'dart:math' as math;

class AdminDashboard extends StatelessWidget {
  final AdminController controller = Get.put(AdminController());

  AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(context, isDark),
      body: _buildBody(context, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            'Manage users and view statistics',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : Colors.black54,
            ),
            onPressed: () => controller.refreshUsers(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState(context, isDark);
      } else if (controller.hasError.value) {
        return _buildErrorState(context, isDark);
      } else if (controller.users.isEmpty) {
        return _buildEmptyState(context, isDark);
      } else {
        return _buildUsersList(context, isDark);
      }
    });
  }

  Widget _buildLoadingState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              color: isDark ? AppColors.neutral200 : AppColors.neutral700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.darkError,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Users',
            style: TextStyle(
              color: isDark ? AppColors.neutral200 : AppColors.neutral700,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => controller.fetchAllUsers(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? AppColors.neutral400 : AppColors.neutral500,
          ),
          const SizedBox(height: 16),
          Text(
            'No Users Found',
            style: TextStyle(
              color: isDark ? AppColors.neutral200 : AppColors.neutral700,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no users registered in the system',
            style: TextStyle(
              color: isDark ? AppColors.neutral300 : AppColors.neutral600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 480;

    // Important: Use a Container with fixed constraints rather than Material to avoid rendering issues
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: screenWidth,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                ? [AppColors.darkPrimary.withOpacity(0.8), AppColors.darkSecondary.withOpacity(0.6)]
                : [AppColors.lightPrimary.withOpacity(0.8), AppColors.lightSecondary.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark 
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          margin: EdgeInsets.symmetric(
            vertical: isMobile ? 8 : 16,
            horizontal: isMobile ? 8 : 16,
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Users Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 18 : 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Show real-time update info
                          Obx(() => Text(
                            'Last updated: ${DateFormat('MMM d, h:mm a').format(controller.lastUpdated.value)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: isMobile ? 12 : 14,
                            ),
                          )),
                        ],
                      ),
                    ),
                    // Refresh button
                    InkWell(
                      onTap: controller.refreshUsers,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stats cards section - Use responsive layout
              LayoutBuilder(
                builder: (context, constraints) {
                  // Use different layouts based on available width
                  if (constraints.maxWidth < 600) {
                    // Mobile layout (stacked)
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildSimpleStatCard(context, 'Total', controller.totalUsers.toString(), Icons.people_outline, isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSimpleStatCard(context, 'Active', controller.activeUsers.toString(), Icons.check_circle_outline, isDark)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSimpleStatCard(context, 'Blocked', controller.blockedUsers.toString(), Icons.block_outlined, isDark, isWarning: true, isFullWidth: true),
                      ],
                    );
                  } else {
                    // Tablet/desktop layout (row)
                    return Row(
                      children: [
                        Expanded(child: _buildSimpleStatCard(context, 'Total Users', controller.totalUsers.toString(), Icons.people_outline, isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSimpleStatCard(context, 'Active Users', controller.activeUsers.toString(), Icons.check_circle_outline, isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSimpleStatCard(context, 'Blocked Users', controller.blockedUsers.toString(), Icons.block_outlined, isDark, isWarning: true)),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSimpleStatCard(BuildContext context, String label, String value, IconData icon, bool isDark, {bool isWarning = false, bool isFullWidth = false}) {
    final isMobile = MediaQuery.of(context).size.width < 480;
    
    // Determine colors based on warning status and theme
    final Color iconBgColor = isWarning
        ? (isDark ? AppColors.darkWarning.withOpacity(0.2) : AppColors.lightWarning.withOpacity(0.2))
        : Colors.white.withOpacity(0.2);
    
    final Color iconColor = isWarning
        ? (isDark ? AppColors.darkWarning : AppColors.lightWarning)
        : Colors.white;
        
    final Color valueFontColor = isWarning
        ? (isDark ? AppColors.darkWarning : AppColors.lightWarning)
        : Colors.white;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueFontColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, bool isDark) {
    return RefreshIndicator(
      onRefresh: controller.refreshUsers,
      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      child: CustomScrollView(
        slivers: [
          // Fixed header that scrolls with content
          SliverPersistentHeader(
            pinned: true,
            floating: true,
            delegate: _SliverHeaderDelegate(
              child: _buildStatsSummary(context, isDark),
              minHeight: MediaQuery.of(context).size.width < 480 ? 320 : 240,
              maxHeight: MediaQuery.of(context).size.width < 480 ? 350 : 260,
            ),
          ),
          // User list content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildSectionHeader('User Management', isDark),
                  const SizedBox(height: 12),
                  ...controller.users.map((user) => _buildUserCard(context, user, isDark)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatCard(
    String title, 
    String value, 
    IconData icon, 
    bool isDark, 
    {bool isWarning = false, bool isWide = false}
  ) {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isMobile = screenWidth < 480;
    
    Color iconColor;
    Color bgColor;
    
    if (isWarning) {
      iconColor = isDark ? AppColors.darkWarning : AppColors.lightWarning;
      bgColor = isDark 
          ? AppColors.darkWarning.withOpacity(0.2) 
          : AppColors.lightWarning.withOpacity(0.2);
    } else {
      iconColor = Colors.white;
      bgColor = Colors.white.withOpacity(0.2);
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 16,
        horizontal: isMobile ? 12 : 16,
      ),
      width: isWide && isMobile ? double.infinity : null,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isWarning 
                      ? iconColor.withOpacity(0.2) 
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: isMobile ? 14 : 16,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 6 : 10),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.neutral200 : AppColors.neutral700,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AdminUser user, bool isDark) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 480;
    
    // Determine style based on blocked status
    Color avatarColor = isDark
        ? (user.isBlocked ? AppColors.darkWarning : AppColors.darkPrimary).withOpacity(0.2)
        : (user.isBlocked ? AppColors.lightWarning : AppColors.lightPrimary).withOpacity(0.2);
    
    Color textColor = isDark
        ? (user.isBlocked ? AppColors.darkWarning : AppColors.darkPrimary)
        : (user.isBlocked ? AppColors.lightWarning : AppColors.lightPrimary);
    
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: user.isBlocked
              ? (isDark ? AppColors.darkWarning.withOpacity(0.2) : AppColors.lightWarning.withOpacity(0.2))
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          width: 1,
        ),
      ),
      color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: avatarColor,
                  radius: isMobile ? 20 : 24,
                  child: Text(
                    user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16,
                          decoration: user.isBlocked ? TextDecoration.lineThrough : null,
                          decorationColor: isDark ? AppColors.darkWarning : AppColors.lightWarning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      if (user.isBlocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkWarning.withOpacity(0.1)
                                  : AppColors.lightWarning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BLOCKED',
                              style: TextStyle(
                                color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                        : theme.colorScheme.surfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                    iconSize: isMobile ? 20 : 24,
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 32 : 40,
                      minHeight: isMobile ? 32 : 40,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showUserOptions(context, user, isDark),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    'ID: ${user.id.length > 8 ? user.id.substring(0, 8) + '...' : user.id}',
                    style: TextStyle(
                      color: isDark ? AppColors.neutral200 : AppColors.neutral700,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                  backgroundColor: isDark 
                      ? AppColors.neutral800.withOpacity(0.5) 
                      : AppColors.neutral100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  'Joined: ${DateFormat('MMM d, yyyy').format(user.createdAt)}',
                  style: TextStyle(
                    color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserOptions(BuildContext context, AdminUser user, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: user.isBlocked
                        ? (isDark ? AppColors.darkWarning.withOpacity(0.2) : AppColors.lightWarning.withOpacity(0.2))
                        : (isDark ? AppColors.darkSuccess.withOpacity(0.2) : AppColors.lightSuccess.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    user.isBlocked ? Icons.block : Icons.check_circle,
                    color: user.isBlocked
                        ? (isDark ? AppColors.darkWarning : AppColors.lightWarning)
                        : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                    size: 20,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimary.withOpacity(0.1)
                      : AppColors.lightPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  size: 20,
                ),
              ),
              title: Text(
                'Edit User',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Modify user profile information',
                style: TextStyle(
                  color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                  fontSize: 12,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                _showEditUserDialog(context, user, isDark);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkWarning.withOpacity(0.1)
                      : AppColors.lightWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  user.isBlocked ? Icons.check_circle : Icons.block,
                  color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
                  size: 20,
                ),
              ),
              title: Text(
                user.isBlocked ? 'Unblock User' : 'Block User',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                user.isBlocked 
                    ? 'Allow user to access the system' 
                    : 'Prevent user from accessing the system',
                style: TextStyle(
                  color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                  fontSize: 12,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                _confirmBlockUser(context, user, isDark);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkError.withOpacity(0.1)
                      : AppColors.lightError.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: isDark ? AppColors.darkError : AppColors.lightError,
                  size: 20,
                ),
              ),
              title: Text(
                'Delete User',
                style: TextStyle(
                  color: isDark ? AppColors.darkError : AppColors.lightError,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Permanently remove user and all data',
                style: TextStyle(
                  color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                  fontSize: 12,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteUser(context, user, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, AdminUser user, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(
            'Delete User',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${user.userName}? This action cannot be undone.',
            style: TextStyle(
              color: isDark ? AppColors.neutral300 : AppColors.neutral600,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.darkError,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                controller.deleteUser(user.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmBlockUser(BuildContext context, AdminUser user, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(
            user.isBlocked ? 'Unblock User' : 'Block User',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.isBlocked 
                    ? 'Are you sure you want to unblock ${user.userName}?' 
                    : 'Are you sure you want to block ${user.userName}?',
                style: TextStyle(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.neutral800.withOpacity(0.5) 
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      user.isBlocked ? Icons.info_outline : Icons.warning_amber_rounded,
                      color: user.isBlocked
                          ? (isDark ? AppColors.darkInfo : AppColors.lightInfo)
                          : (isDark ? AppColors.darkWarning : AppColors.lightWarning),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.isBlocked
                            ? 'User will be able to access the system again'
                            : 'User will not be able to log in or create a new account with this email',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: user.isBlocked
                    ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                    : (isDark ? AppColors.darkWarning : AppColors.lightWarning),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(user.isBlocked ? 'Unblock' : 'Block'),
              onPressed: () {
                Navigator.of(context).pop();
                controller.toggleBlockUser(user.id, !user.isBlocked);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, AdminUser user, bool isDark) {
    // Set current values to the text controllers
    controller.prepareForEdit(user);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(
            'Edit User',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller.userNameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.emailController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                controller.currentEditingUserId.value = '';
                controller.userNameController.clear();
                controller.emailController.clear();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                controller.editUser();
              },
            ),
          ],
        );
      },
    );
  }
} 

// SliverHeaderDelegate for implementing sticky header
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _SliverHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Use a sized container to ensure the child has proper constraints
    return Container(
      width: MediaQuery.of(context).size.width,
      height: math.max(minHeight, maxHeight - shrinkOffset),
      child: child,
    );
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
} 