import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TransactionService{
  static String baseUrl = '${dotenv.env['BASE_URL']!}/api/transactions';

  //fetch transaction from userId
  Future<List<TransactionModel>> fetchTransactionsByUser(String userId) async {
    try {
      print('TransactionService: Fetching transactions for user: $userId');
      final url = Uri.parse('$baseUrl/$userId');

      final response = await http.get(url);
      print('TransactionService: Response status: ${response.statusCode}');
      print('TransactionService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        print('TransactionService: Parsed JSON list length: ${jsonList.length}');
        print('TransactionService: JSON list: $jsonList');
        
        List<TransactionModel> transactions = jsonList.map((e) {
          print('TransactionService: Converting JSON to model: $e');
          return TransactionModel.fromJson(e);
        }).toList();
        
        print('TransactionService: Converted ${transactions.length} transactions');
        return transactions;
      } else {
        print('TransactionService: Error status code: ${response.statusCode}');
        throw Exception('Failed to load transactions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('TransactionService: Exception caught: $e');
      rethrow;
    }
  }

  //add transaction
  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      print('TransactionService: Adding transaction: ${transaction.toJson()}');
      final url = Uri.parse('$baseUrl/addTransaction');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction.toJson()),
      );

      print('TransactionService: Add transaction response status: ${response.statusCode}');
      print('TransactionService: Add transaction response body: ${response.body}');

      if (response.statusCode == 201) {
        print('TransactionService: Transaction added successfully');
        return true;
      } else {
        print('TransactionService: Failed to add transaction. Status: ${response.statusCode}');
        throw Exception('Failed to add transaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('TransactionService: Exception in addTransaction: $e');
      rethrow;
    }
  }

  //delete transaction of a user
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      print('TransactionService: Deleting transaction: $transactionId');
      final url = Uri.parse('$baseUrl/deleteTransaction/$transactionId');

      final response = await http.delete(url);
      print('TransactionService: Delete transaction response status: ${response.statusCode}');
      print('TransactionService: Delete transaction response body: ${response.body}');

      if (response.statusCode == 200) {
        print('TransactionService: Transaction deleted successfully');
        return true;
      } else {
        print('TransactionService: Failed to delete transaction. Status: ${response.statusCode}');
        throw Exception('Failed to delete transaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('TransactionService: Exception in deleteTransaction: $e');
      rethrow;
    }
  }
}
