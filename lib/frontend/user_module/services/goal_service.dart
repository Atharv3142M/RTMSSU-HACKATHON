import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/goal_model.dart';

class GoalService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:3000';

  // Get all goals for a user
  Future<List<Goal>> getGoals(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/goals/getGoals/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((goal) => Goal.fromJson(goal)).toList();
      } else {
        throw Exception('Failed to load goals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching goals: $e');
    }
  }

  // Get a specific goal by ID
  Future<Goal> getGoalById(String goalId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/goals/getGoal/$goalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Goal.fromJson(data);
      } else {
        throw Exception('Failed to load goal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching goal: $e');
    }
  }

  // Add a new goal
  Future<Goal> addGoal(Goal goal) async {
    try {
      print("GoalService: Sending request to: $baseUrl/api/goals/addGoal");
      print("GoalService: Request body: ${json.encode(goal.toJson())}");
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/goals/addGoal'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(goal.toJson()),
      );

      print("GoalService: Response status: ${response.statusCode}");
      print("GoalService: Response body: ${response.body}");

      if (response.statusCode == 201) {
        final dynamic data = json.decode(response.body);
        return Goal.fromJson(data);
      } else {
        throw Exception('Failed to add goal: HTTP ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print("GoalService: Error adding goal: $e");
      throw Exception('Error adding goal: $e');
    }
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/goals/deleteGoal/$goalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete goal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting goal: $e');
    }
  }

  // Deposit money to a goal
  Future<Goal> depositToGoal(String goalId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/goals/deposit/$goalId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Goal.fromJson(data['goal']);
      } else {
        throw Exception('Failed to deposit: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error making deposit: $e');
    }
  }

  // Withdraw money from a goal
  Future<Goal> withdrawFromGoal(String goalId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/goals/withdraw/$goalId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Goal.fromJson(data['goal']);
      } else {
        throw Exception('Failed to withdraw: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error making withdrawal: $e');
    }
  }

  // Edit an existing goal
  Future<Goal> editGoal(Goal goal) async {
    try {
      print("GoalService: Updating goal with ID: ${goal.id}");
      print("GoalService: Request body: ${json.encode(goal.toJson())}");
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/goals/updateGoal/${goal.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(goal.toJson()),
      );

      print("GoalService: Response status: ${response.statusCode}");
      print("GoalService: Response body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Goal.fromJson(data);
      } else {
        throw Exception('Failed to update goal: HTTP ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print("GoalService: Error updating goal: $e");
      throw Exception('Error updating goal: $e');
    }
  }
} 