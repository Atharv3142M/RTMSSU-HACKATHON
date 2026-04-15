import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data'; // Added for Int64List
import '../models/transaction_model.dart';
import '../controllers/transaction_controllers/transaction_controller.dart';

class NotificationService {
  static const String transactionChannelKey = 'recurring_transaction_channel';
  static const String transactionChannelName = 'Recurring Transaction Notifications';
  static const String transactionChannelDescription = 'Notifications for recurring transactions';
  
  // Define vibration pattern
  static final Int64List highVibrationPattern = Int64List.fromList([0, 200, 100, 200]);

  static Future<void> initializeNotifications() async {
    // Check if notifications are already initialized - we'll use a try-catch instead of accessing 'initialized'
    try {
      print('Initializing notifications...');
      
      // Initialize AwesomeNotifications with a simple default icon
      final success = await AwesomeNotifications().initialize(
        null, // Use null instead of resource path that might not exist
        [
          NotificationChannel(
            channelKey: transactionChannelKey,
            channelName: transactionChannelName,
            channelDescription: transactionChannelDescription,
            defaultColor: Colors.blue,
            ledColor: Colors.blue,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            vibrationPattern: highVibrationPattern,
            enableVibration: true,
            playSound: true,
            // Remove soundSource that might not exist
            locked: false,
          )
        ],
        debug: true,
      );
      
      print('Notification initialization result: $success');

      // Request notification permissions immediately
      await requestNotificationPermissions();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }
  
  // Separate method to request permissions
  static Future<bool> requestNotificationPermissions() async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      print('Notifications allowed: $isAllowed');
      
      if (!isAllowed) {
        final result = await AwesomeNotifications().requestPermissionToSendNotifications();
        print('Permission request result: $result');
        return result;
      }
      return isAllowed;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  static Future<bool> scheduleRecurringTransaction({
    required TransactionModel transaction,
    required int durationInDays,
    bool isTestMode = false,
  }) async {
    try {
      // Create unique notification ID based on transaction details
      final int notificationId = _generateNotificationId(transaction);
      
      // For test mode, use a very short duration (5 seconds) instead of 1 minute
      final DateTime scheduledDate = isTestMode 
          ? DateTime.now().add(const Duration(seconds: 5)) 
          : DateTime.now().add(Duration(days: durationInDays));
      
      print('Scheduling notification for ${scheduledDate.toString()}');
      print('Current time: ${DateTime.now().toString()}');
      
      // Format amount with 2 decimal places and add thousand separators
      final String formattedAmount = _formatCurrency(transaction.amount);
      final String transactionType = transaction.isExpense ? 'Expense' : 'Income';
      final String category = _capitalizeFirstLetter(transaction.category);
      final String emoji = _getEmojiForCategory(transaction.category);
      
      // Additional data to pass to notification action
      Map<String, String> payload = {
        'transactionId': transaction.transactionId ?? '',
        'userId': transaction.userId,
        'amount': transaction.amount.toString(),
        'description': transaction.description ?? '',
        'category': transaction.category,
        'isExpense': transaction.isExpense.toString(),
        'isRecurring': transaction.isRecurring.toString(),
        'recurringDuration': transaction.recurringDuration.toString(),
      };

      // Build a beautiful notification content
      String notificationTitle = '$emoji Recurring $transactionType Due';
      String notificationBody = 'Do you want to add your ${transaction.isExpense ? 'payment' : 'deposit'} of ₹$formattedAmount for $category?';
      
      if (transaction.description != null && transaction.description!.isNotEmpty) {
        notificationBody += '\n"${transaction.description}"';
      }
      
      // For test mode, add a simpler notification to ensure it works
      if (isTestMode) {
        notificationTitle = 'Test Notification';
        notificationBody = 'This is a test notification for transaction: ${transaction.category}';
      }

      // First check if we have permission
      final hasPermission = await AwesomeNotifications().isNotificationAllowed();
      if (!hasPermission) {
        print('Notification permission not granted. Requesting...');
        final permissionGranted = await requestNotificationPermissions();
        if (!permissionGranted) {
          print('Failed to get notification permission');
          return false;
        }
      }

      // For immediate test notification
      if (isTestMode) {
        print('Creating immediate test notification');
        bool success = await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: transactionChannelKey,
            title: 'Immediate Test Notification',
            body: 'This should appear right away!',
            notificationLayout: NotificationLayout.Default,
            payload: payload,
          ),
        );
        print('Immediate test notification created: $success');
      }

      // Create the scheduled notification
      print('Creating scheduled notification with ID: $notificationId');
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId + 1, // Use different ID for scheduled notification
          channelKey: transactionChannelKey,
          title: notificationTitle,
          body: notificationBody,
          notificationLayout: NotificationLayout.BigText,
          payload: payload,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
          backgroundColor: transaction.isExpense ? Colors.red.shade700 : Colors.green.shade700,
          color: Colors.white,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'ADD',
            label: 'Add Now',
            color: transaction.isExpense ? Colors.red : Colors.green,
            autoDismissible: true,
          ),
          NotificationActionButton(
            key: 'SKIP',
            label: 'Skip',
            isDangerousOption: true,
            autoDismissible: true,
          ),
        ],
        schedule: isTestMode 
            ? NotificationInterval(interval: Duration(seconds: 5), timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier())
            : NotificationCalendar.fromDate(date: scheduledDate),
      );

      print('Scheduled notification created: $success');
      
      // Schedule the next notification if this one is successful and not a test
      if (success && !isTestMode && transaction.isRecurring && transaction.recurringDuration != null) {
        _scheduleNextOccurrence(transaction, notificationId);
      }
      
      // List pending notifications for debugging
      final pendingNotifications = await AwesomeNotifications().listScheduledNotifications();
      print('Pending notifications: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        print('Pending notification ID: ${notification.content?.id}, scheduled for: ${notification.schedule?.toMap()}');
      }
      
      return success;
    } catch (e) {
      print('Error scheduling notification: $e');
      return false;
    }
  }
  
  // Schedule the next occurrence for truly recurring transactions
  static Future<void> _scheduleNextOccurrence(TransactionModel transaction, int previousId) async {
    if (transaction.recurringDuration == null) return;
    
    final int nextNotificationId = previousId + 1000; // Ensure unique ID for next notification
    final DateTime nextScheduledDate = DateTime.now().add(
      Duration(days: transaction.recurringDuration! * 2) // Schedule next one after 2 cycles
    );
    
    // Format amount with 2 decimal places
    final String formattedAmount = _formatCurrency(transaction.amount);
    final String transactionType = transaction.isExpense ? 'Expense' : 'Income';
    final String category = _capitalizeFirstLetter(transaction.category);
    final String emoji = _getEmojiForCategory(transaction.category);
    
    // Payload for the next notification
    Map<String, String> payload = {
      'transactionId': transaction.transactionId ?? '',
      'userId': transaction.userId,
      'amount': transaction.amount.toString(),
      'description': transaction.description ?? '',
      'category': transaction.category,
      'isExpense': transaction.isExpense.toString(),
      'isRecurring': transaction.isRecurring.toString(),
      'recurringDuration': transaction.recurringDuration.toString(),
    };

    // Build a beautiful notification content
    String notificationTitle = '$emoji Recurring $transactionType Due';
    String notificationBody = 'Do you want to add your ${transaction.isExpense ? 'payment' : 'deposit'} of ₹$formattedAmount for $category?';
    
    if (transaction.description != null && transaction.description!.isNotEmpty) {
      notificationBody += '\n"${transaction.description}"';
    }
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: nextNotificationId,
        channelKey: transactionChannelKey,
        title: notificationTitle,
        body: notificationBody,
        notificationLayout: NotificationLayout.BigText,
        payload: payload,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        backgroundColor: transaction.isExpense ? Colors.red.shade700 : Colors.green.shade700,
        color: Colors.white,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'ADD',
          label: 'Add Now',
          color: transaction.isExpense ? Colors.red : Colors.green,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'SKIP',
          label: 'Skip',
          isDangerousOption: true,
          autoDismissible: true,
        ),
      ],
      schedule: NotificationCalendar.fromDate(date: nextScheduledDate),
    );
  }
  
  // Generate a unique notification ID based on transaction details
  static int _generateNotificationId(TransactionModel transaction) {
    final String uniqueString = '${transaction.userId}${transaction.amount}${DateTime.now().millisecondsSinceEpoch}';
    final int hashCode = uniqueString.hashCode;
    // Ensure it's a positive value within int32 range
    return (hashCode & 0x7FFFFFFF) % 100000;
  }
  
  // Helper method to format currency with commas
  static String _formatCurrency(double amount) {
    // Add thousand separators to the amount
    final String amountStr = amount.toStringAsFixed(2);
    final parts = amountStr.split('.');
    final wholePart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';
    
    // Add thousand separators
    String result = '';
    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        result += ',';
      }
      result += wholePart[i];
    }
    
    return '$result.$decimalPart';
  }
  
  // Helper to capitalize first letter
  static String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // Get emoji for category
  static String _getEmojiForCategory(String category) {
    final Map<String, String> categoryEmojis = {
      'food': '🍔',
      'shopping': '🛍️',
      'healthcare': '💊',
      'transportation & fuel': '🚗',
      'entertainment': '🎬',
      'clothing': '👕',
      'education': '📚',
      'fitness': '🏋️',
      'bills': '📄',
      'home & furniture': '🏠',
      'pets': '🐾',
      'gifts': '🎁',
      'travel': '✈️',
      'salary': '💰',
      'investments': '📈',
      'rental': '🏘️',
      'refunds': '💸',
      'other': '📊',
    };
    
    return categoryEmojis[category.toLowerCase()] ?? '💵';
  }
  
  // Process notification actions
  static void processNotificationAction(ReceivedAction receivedAction) async {
    print('Received notification action: ${receivedAction.buttonKeyPressed}');
    print('Payload: ${receivedAction.payload}');
    
    if (receivedAction.buttonKeyPressed == 'ADD') {
      // User wants to add the transaction
      final Map<String, String?>? payload = receivedAction.payload;
      
      if (payload != null) {
        try {
          // Create a new transaction from the payload data
          final transaction = TransactionModel(
            userId: payload['userId'] ?? '',
            amount: double.tryParse(payload['amount'] ?? '0.0') ?? 0.0,
            description: payload['description'],
            category: payload['category'] ?? 'other',
            isExpense: payload['isExpense']?.toLowerCase() == 'true',
            transactionDate: DateTime.now(),
            isRecurring: payload['isRecurring']?.toLowerCase() == 'true',
            recurringDuration: int.tryParse(payload['recurringDuration'] ?? '0'),
          );
          
          // Get the transaction controller
          TransactionController? controller;
          try {
            controller = Get.find<TransactionController>();
          } catch (_) {
            // Controller not found, create a new instance
            controller = TransactionController();
          }
          
          // Add the transaction
          if (controller != null) {
            await controller.addTransaction(transaction);
            
            // Show success message
            Get.snackbar(
              '✅ Transaction Added',
              'The recurring ${transaction.isExpense ? "expense" : "income"} of ₹${_formatCurrency(transaction.amount)} has been added successfully.',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
              snackPosition: SnackPosition.TOP,
              margin: const EdgeInsets.all(10),
              borderRadius: 10,
              icon: const Icon(Icons.check_circle, color: Colors.white),
            );
          }
        } catch (e) {
          print('Error processing notification action: $e');
          Get.snackbar(
            '❌ Error',
            'Failed to add transaction: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(10),
            borderRadius: 10,
            icon: const Icon(Icons.error, color: Colors.white),
          );
        }
      }
    } else if (receivedAction.buttonKeyPressed == 'SKIP') {
      // User wants to skip this occurrence
      Get.snackbar(
        '⏭️ Transaction Skipped',
        'The recurring transaction has been skipped for now.',
        backgroundColor: Colors.grey,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        icon: const Icon(Icons.skip_next, color: Colors.white),
      );
    }
  }
  
  // Method to manually trigger a test notification
  static Future<bool> sendTestNotification() async {
    try {
      // First check if we have permission
      final hasPermission = await AwesomeNotifications().isNotificationAllowed();
      if (!hasPermission) {
        final permissionGranted = await requestNotificationPermissions();
        if (!permissionGranted) {
          print('Failed to get notification permission for test');
          return false;
        }
      }
      
      // Create a simple test notification that appears immediately
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 9999,
          channelKey: transactionChannelKey,
          title: 'Test Notification',
          body: 'This is a test notification to verify notifications are working',
          notificationLayout: NotificationLayout.Default,
        ),
      );
      
      print('Test notification created: $success');
      return success;
    } catch (e) {
      print('Error sending test notification: $e');
      return false;
    }
  }
} 