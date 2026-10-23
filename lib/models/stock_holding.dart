class StockHolding {
  final String id;
  final String symbol;
  final String companyName;
  final double shares;
  final double avgBuyPrice;
  final double currentPrice;

  const StockHolding({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.shares,
    required this.avgBuyPrice,
    required this.currentPrice,
  });

  double get investedValue => shares * avgBuyPrice;
  double get currentValue => shares * currentPrice;
  double get totalGainLoss => currentValue - investedValue;
  double get totalGainLossPercentage =>
      investedValue > 0 ? (totalGainLoss / investedValue) * 100 : 0.0;
  bool get isProfitable => totalGainLoss >= 0;
}
