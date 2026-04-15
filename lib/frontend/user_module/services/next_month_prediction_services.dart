import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExpensePredictionService {
  static const String nodeServerUrl = 'https://ml-based-personal-finance-optimizer.onrender.com';
  static const String flaskServerUrl = ' https://test-api-udkm.onrender.com';

  Future<Map<String, dynamic>> predictNextMonthExpense(String userId) async {
    try {
      // Step 1: Fetch all transactions from Node.js
      final transactionsResponse = await http.get(
        Uri.parse('$nodeServerUrl/api/transactions/all?userId=$userId'),
        headers: {
          'Authorization': 'Bearer ${await getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (transactionsResponse.statusCode != 200) {
        throw Exception('Failed to fetch transactions');
      }

      final transactions = json.decode(transactionsResponse.body);

      // Step 2: Send to Flask for prediction
      final predictionResponse = await http.post(
        Uri.parse('$flaskServerUrl/predict-expense'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'transactions': transactions}),
      );

      if (predictionResponse.statusCode != 200) {
        throw Exception('Failed to get expense prediction');
      }

      return json.decode(predictionResponse.body);

    } catch (e) {
      print('Error predicting expenses: $e');
      rethrow;
    }
  }
}

Future<String?> getAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token'); // or whatever key you use
}
