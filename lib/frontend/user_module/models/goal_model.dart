import 'package:intl/intl.dart';

class Goal {
  final String? id;
  final String userId;
  final String title;
  final double targetAmount;
  double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;

  Goal({
    this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.endDate,
    this.description,
  });

  // Calculate progress percentage
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    double progress = (currentAmount / targetAmount) * 100;
    return progress > 100 ? 100 : progress;
  }

  // Calculate remaining amount
  double get remainingAmount => targetAmount - currentAmount;

  // Calculate days left until target date
  int get daysLeft {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  // Factory constructor to create a Goal from JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now().add(const Duration(days: 30)),
      description: json['description'],
    );
  }

  // Convert Goal to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
      'description': description ?? '',
    };
  }
} 