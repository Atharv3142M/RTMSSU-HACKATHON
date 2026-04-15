class TransactionModel {
  final String? transactionId;
  final String userId;
  final double amount;
  final String? description;
  final bool isExpense;
  final DateTime transactionDate;
  final String category;
  final String? merchant;
  final bool isRecurring;
  final int? recurringDuration; // In days

  TransactionModel({
    this.transactionId,
    required this.userId,
    required this.amount,
    this.description,
    required this.isExpense,
    required this.transactionDate,
    required this.category,
    this.merchant,
    this.isRecurring = false,
    this.recurringDuration,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    try {
      print('TransactionModel: Parsing JSON: $json');
      
      // Handle different date formats
      DateTime transactionDate;
      if (json['transactionDate'] is String) {
        transactionDate = DateTime.parse(json['transactionDate']);
      } else if (json['transactionDate'] is DateTime) {
        transactionDate = json['transactionDate'];
      } else {
        // Fallback to current date if parsing fails
        transactionDate = DateTime.now();
        print('TransactionModel: Warning - Could not parse transaction_date, using current date');
      }
      
      final model = TransactionModel(
        transactionId: json['_id'],
        userId: json['userId'],
        amount: (json['amount'] as num).toDouble(),
        description: json['description'],
        isExpense: json['isExpense'],
        transactionDate: transactionDate,
        category: json['category'],
        merchant: json['merchant'],
        isRecurring: json['isRecurring'] ?? false,
        recurringDuration: json['recurringDuration'],
      );
      
      print('TransactionModel: Successfully created model: $model');
      return model;
    } catch (e) {
      print('TransactionModel: Error parsing JSON: $e');
      print('TransactionModel: Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      // '_id': transactionId,
      'userId': userId,
      'transactionDate': transactionDate.toIso8601String(),
      'isExpense': isExpense,
      'amount': amount,
      'description': description,
      'category': category,
      'merchant': merchant,
      'isRecurring': isRecurring,
      'recurringDuration': recurringDuration,
    };
  }

  TransactionModel copyWith({
    String? transactionId,
    String? userId,
    double? amount,
    String? description,
    bool? isExpense,
    DateTime? transactionDate,
    String? category,
    String? merchant,
    bool? isRecurring,
    int? recurringDuration,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      isExpense: isExpense ?? this.isExpense,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringDuration: recurringDuration ?? this.recurringDuration,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(transactionId: $transactionId, userId: $userId, amount: $amount, description: $description, isExpense: $isExpense, transactionDate: $transactionDate, category: $category, merchant: $merchant, isRecurring: $isRecurring, recurringDuration: $recurringDuration)';
  }
}
