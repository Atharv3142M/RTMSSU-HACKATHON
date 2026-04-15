import 'dart:convert';

class UserModel {
  String? userId;
  String? username;
  String? email;
  String? phoneNumber;
  String? profileImagePath;
  bool? isBlocked;
  DateTime? createdAt;

  UserModel({
    this.userId,
    this.username,
    this.email,
    this.phoneNumber,
    this.profileImagePath,
    this.isBlocked,
    this.createdAt,
  });

  // Convert user model to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImagePath': profileImagePath,
      'isBlocked': isBlocked,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create user model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      profileImagePath: json['profileImagePath'],
      isBlocked: json['isBlocked'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  // Create user model from backend JSON
  factory UserModel.fromBackendJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['_id'],
      username: json['userName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      profileImagePath: json['profileImagePath'],
      isBlocked: json['isBlocked'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  // Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Create from JSON string
  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString));
  }

  // Copy with method to create a copy of the model with some fields updated
  UserModel copyWith({
    String? userId,
    String? username,
    String? email,
    String? phoneNumber,
    String? profileImagePath,
    bool? isBlocked,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 