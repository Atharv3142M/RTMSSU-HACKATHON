import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ml_based_personal_finance_optimizer/frontend/user_module/models/transaction_model.dart';
import 'package:ml_based_personal_finance_optimizer/frontend/user_module/services/transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GoogleGenerativeAiApiService {
  final String? Google_GenerativeAI_API_Key = dotenv.env['GOOGLE_GENERATIVE_AI_API_KEY'];
  final TransactionService _service = TransactionService();
  String? userId;

  GoogleGenerativeAiApiService() {
    if (Google_GenerativeAI_API_Key == null || Google_GenerativeAI_API_Key!.isEmpty) {
      throw Exception("API Key is missing or invalid.");
    }
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    print("userId: $userId");
    return userId;
  }

  Future<List<TransactionModel>> fetchTransactions(String userId) async {
    try {
      if (userId.isEmpty) {
        print('Error: Cannot fetch transactions with an empty userId');
        return [];
      }

      print('Starting to fetch transactions for user: $userId');
      final fetched = await _service.fetchTransactionsByUser(userId);
      print('Transactions fetched for userId $userId: ${fetched.length} transactions');
      return fetched;
    } catch (e) {
      print('Error in fetchTransactions for userId $userId: $e');
      return [];
    }
  }

  String formatTransactions(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return "No transaction history available.";

    return transactions.map((tx) {
      return '''
Date: ${tx.transactionDate}
Type: ${tx.isExpense ? "Expense" : "Income"}
Amount: ₹${tx.amount}
Description: ${tx.description}
''';
    }).join('\n');
  }

  Future<String> getResponseForGivenPrompt(String prompt) async {
    try {
      final userId = await getUserId();
      if (userId == null) return "User ID not found.";

      final transactions = await fetchTransactions(userId);
      final formattedTransactions = formatTransactions(transactions);

      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: Google_GenerativeAI_API_Key!,
      );

      final systemPrompt = """
You are a Personal Finance Optimizer AI Assistant.
You help users manage their finances by analyzing their income, expenses, and transaction history.

You can:
1. Answer general finance-related queries.
2. Provide insights into their spending habits.
3. Recommend ways to save money.
4. Detect unusual or large transactions.
5. Categorize their income and expenses.
6. Suggest budgets based on their financial behavior.

Always ask the user:
1. What would they like help with (e.g., savings, expense summary, budget advice)?
2. If relevant, the date range or category they’re interested in.

User's Transactions History:
$formattedTransactions

Be smart, helpful, and non-judgmental. Use the available data in the app to give meaningful suggestions.
""";

      final content = [Content.text(systemPrompt), Content.text(prompt)];
      final response = await model.generateContent(content);

      return removeMarkdown(response.text ?? "No response from AI.");
    } catch (e) {
      print("An error occurred while fetching response from AI: $e");
      return "An error occurred while processing your request.";
    }
  }

  String removeMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'_'), '');
  }
}
