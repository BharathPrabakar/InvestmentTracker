enum TransactionType { buy, sell, dividend }

class Transaction {
  final String id;
  final TransactionType type;
  final DateTime date; // For BUY/SELL: transaction date. For DIVIDEND: payment date.
  final double price; // For BUY/SELL: price per share. For DIVIDEND: dividend per share (DPS).
  final double quantity; // For BUY/SELL: trade quantity. For DIVIDEND: eligible shares held before ex-date.
  final double amount; // For BUY/SELL: price * quantity. For DIVIDEND: DPS * eligible shares.
  final DateTime? exDividendDate; // Specific to DIVIDEND: cutoff date to be eligible for dividend.

  const Transaction({
    required this.id,
    required this.type,
    required this.date,
    required this.price,
    required this.quantity,
    required this.amount,
    this.exDividendDate,
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

  /// Copies transaction with recalculated values
  Transaction copyWith({
    String? id,
    TransactionType? type,
    DateTime? date,
    double? price,
    double? quantity,
    double? amount,
    DateTime? exDividendDate,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      exDividendDate: exDividendDate ?? this.exDividendDate,
    );
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

  /// Calculates eligible stock quantity held strictly BEFORE the ex-dividend date.
  /// (Shares purchased ON the ex-dividend date are NOT eligible for dividend).
  static double getEligibleQuantityOnDate(List<Transaction> txList, DateTime exDate) {
    final relevantTrades = txList.where((tx) {
      if (tx.type == TransactionType.dividend) return false;
      // Truncate to day level comparison: must be strictly before ex-dividend date
      final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final exDay = DateTime(exDate.year, exDate.month, exDate.day);
      return txDay.isBefore(exDay);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningQty = 0.0;
    for (final tx in relevantTrades) {
      if (tx.type == TransactionType.buy) {
        runningQty += tx.quantity;
      } else if (tx.type == TransactionType.sell) {
        runningQty -= tx.quantity;
      }
    }
    return runningQty > 0 ? runningQty : 0.0;
  }

  /// Recomputes all dividend transactions based on current buy/sell history
  /// Returns updated list of transactions with recalculated eligible quantities and dividend amounts
  static List<Transaction> recalculateAllTransactions(List<Transaction> txList) {
    final result = <Transaction>[];
    for (final tx in txList) {
      if (tx.type == TransactionType.dividend) {
        final exDate = tx.exDividendDate ?? tx.date;
        final eligibleQty = getEligibleQuantityOnDate(txList, exDate);
        final recalculatedAmount = eligibleQty * tx.price; // price holds DPS
        result.add(tx.copyWith(
          quantity: eligibleQty,
          amount: recalculatedAmount,
        ));
      } else {
        result.add(tx);
      }
    }
    return result;
  }

  /// Full chronological validation:
  /// 1. No SELL occurs before any BUY.
  /// 2. Active holding quantity is never negative at any historical point.
  /// 3. Dividends cannot exist if eligible stock holding on ex-date is 0.
  static String? validateTransactions(List<Transaction> txList) {
    if (txList.isEmpty) return null;

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
      } else if (tx.type == TransactionType.dividend) {
        final exDate = tx.exDividendDate ?? tx.date;
        final eligibleShares = getEligibleQuantityOnDate(txList, exDate);
        if (eligibleShares <= 0) {
          return 'Dividend ineligible: You hold 0 shares on ex-dividend date (${exDate.toString().substring(0, 10)}). Dividend cannot exist without stock holding.';
        }
      }
    }
    return null;
  }

  /// Latest price observed from transactions (last buy/sell price)
  double get latestPrice {
    final trades = transactions.where((t) => t.type != TransactionType.dividend).toList();
    if (trades.isEmpty) return 0.0;
    trades.sort((a, b) => b.date.compareTo(a.date));
    return trades.first.price;
  }

  /// Realized Profit & Loss from closed positions (SELL transactions)
  /// Uses weighted average cost basis at time of sell
  double get realizedPnL {
    final chronological = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningQty = 0.0;
    double runningCost = 0.0;
    double realized = 0.0;

    for (final tx in chronological) {
      if (tx.type == TransactionType.buy) {
        runningCost += tx.amount;
        runningQty += tx.quantity;
      } else if (tx.type == TransactionType.sell) {
        if (runningQty > 0) {
          final avgCost = runningCost / runningQty;
          final costOfSold = avgCost * tx.quantity;
          realized += (tx.amount - costOfSold);
          runningQty -= tx.quantity;
          runningCost -= costOfSold;
          if (runningQty <= 0) {
            runningCost = 0.0;
            runningQty = 0.0;
          }
        }
      }
    }
    return realized;
  }

  /// Unrealized Profit & Loss on currently open holding based on latest price
  double get unrealizedPnL {
    if (totalQuantity <= 0) return 0.0;
    final currentVal = totalQuantity * latestPrice;
    final costBasis = totalQuantity * avgBuyPrice;
    return currentVal - costBasis;
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
