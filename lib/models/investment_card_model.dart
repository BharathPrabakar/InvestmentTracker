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
  final List<Transaction> transactions;

  const InvestmentCardModel({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.tags,
    required this.transactions,
  });

  /// Chronological verification of all transactions to guarantee:
  /// 1. No SELL occurs before any BUY.
  /// 2. Active holding quantity is never negative at any historical point in time.
  static String? validateTransactions(List<Transaction> txList) {
    if (txList.isEmpty) return null;

    // Sort chronologically (oldest to newest) to replay history
    final chronological = List<Transaction>.from(txList)
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningQty = 0.0;
    bool hasHadBuy = false;

    for (final tx in chronological) {
      if (tx.type == TransactionType.buy) {
        hasHadBuy = true;
        runningQty += tx.quantity;
      } else if (tx.type == TransactionType.sell) {
        if (!hasHadBuy) {
          return 'Invalid transaction order: Cannot sell before any buy transaction has occurred.';
        }
        if (runningQty < tx.quantity) {
          return 'Insufficient shares: Cannot sell ${tx.quantity} shares on ${tx.date.toString().substring(0, 10)}. You only hold $runningQty shares at that date.';
        }
        runningQty -= tx.quantity;
      }
    }
    return null;
  }

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
