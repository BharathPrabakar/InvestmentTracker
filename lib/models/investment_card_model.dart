enum TransactionType { buy, sell, dividend }

class Transaction {
  final String id;
  final TransactionType type;
  final DateTime date;
  final double price;
  final double quantity;
  final double amount; // total amount: typically price * quantity (or dividend amount)

  const Transaction({
    required this.id,
    required this.type,
    required this.date,
    required this.price,
    required this.quantity,
    required this.amount,
  });

  String get typeLabel {
    switch (type) {
      case TransactionType.buy:
        return 'BUY';
      case TransactionType.sell:
        return 'SELL';
      case TransactionType.dividend:
        return 'DIVIDEND';
    }
  }
}

class InvestmentCardModel {
  final String id;
  final String symbol;
  final String companyName;
  final List<String> tags;
  final List<Transaction> transactions; // stored date-wise

  const InvestmentCardModel({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.tags,
    required this.transactions,
  });

  /// Total active quantity calculated from all transactions
  double get totalQuantity {
    double qty = 0.0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.buy) {
        qty += tx.quantity;
      } else if (tx.type == TransactionType.sell) {
        qty -= tx.quantity;
      }
    }
    return qty > 0 ? qty : 0.0;
  }

  /// Total amount invested (cost basis of buys)
  double get totalInvested {
    double invested = 0.0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.buy) {
        invested += tx.amount;
      }
    }
    return invested;
  }

  /// Total dividend income received
  double get totalDividends {
    double div = 0.0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.dividend) {
        div += tx.amount;
      }
    }
    return div;
  }

  /// Average buy price based on buy transactions
  double get avgBuyPrice {
    double totalBuyQty = 0.0;
    double totalBuyAmt = 0.0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.buy) {
        totalBuyQty += tx.quantity;
        totalBuyAmt += tx.amount;
      }
    }
    return totalBuyQty > 0 ? totalBuyAmt / totalBuyQty : 0.0;
  }

  /// Returns transactions sorted chronologically (newest first for display)
  List<Transaction> get sortedTransactions {
    final list = List<Transaction>.from(transactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
