import 'package:flutter/material.dart';

class AdminUser {
  final String id;
  final String userName;
  final String email;
  final DateTime createdAt;
  final bool isBlocked;

  AdminUser({
    required this.id,
    required this.userName,
    required this.email,
    required this.createdAt,
    this.isBlocked = false,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id'] ?? '',
      userName: json['userName'] ?? json['username'] ?? 'Unknown',
      email: json['email'] ?? 'No email',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userName': userName,
      'email': email,
      'isBlocked': isBlocked,
    };
  }

  AdminUser copyWith({
    String? id,
    String? userName,
    String? email,
    DateTime? createdAt,
    bool? isBlocked,
  }) {
    return AdminUser(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
} 