import 'package:flutter/material.dart';
import '../../models/stock_holding.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  final List<StockHolding> _stocks = [
    const StockHolding(
      id: '1',
      symbol: 'AAPL',
      companyName: 'Apple Inc.',
      shares: 15.0,
      avgBuyPrice: 182.50,
      currentPrice: 228.40,
    ),
    const StockHolding(
      id: '2',
      symbol: 'NVDA',
      companyName: 'NVIDIA Corporation',
      shares: 25.0,
      avgBuyPrice: 112.00,
      currentPrice: 139.75,
    ),
    const StockHolding(
      id: '3',
      symbol: 'MSFT',
      companyName: 'Microsoft Corporation',
      shares: 10.0,
      avgBuyPrice: 415.00,
      currentPrice: 428.20,
    ),
    const StockHolding(
      id: '4',
      symbol: 'TSLA',
      companyName: 'Tesla, Inc.',
      shares: 18.0,
      avgBuyPrice: 255.00,
      currentPrice: 218.60,
    ),
  ];

  double get _totalInvested =>
      _stocks.fold(0.0, (sum, stock) => sum + stock.investedValue);

  double get _totalCurrentValue =>
      _stocks.fold(0.0, (sum, stock) => sum + stock.currentValue);

  double get _totalPnl => _totalCurrentValue - _totalInvested;

  double get _totalPnlPercentage =>
      _totalInvested > 0 ? (_totalPnl / _totalInvested) * 100 : 0.0;

  void _openAddStockSheet() {
    final symbolCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final sharesCtrl = TextEditingController();
    final buyPriceCtrl = TextEditingController();
    final currentPriceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Stock Holding',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: symbolCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Stock Symbol (e.g. GOOGL)',
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Name (Optional)',
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sharesCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Shares',
                        filled: true,
                        fillColor: Color(0xFF0F172A),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: buyPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Avg Buy Price (\$)',
                        filled: true,
                        fillColor: Color(0xFF0F172A),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentPriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Price (\$) (Defaults to Buy Price)',
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final symbol = symbolCtrl.text.trim().toUpperCase();
                    final shares = double.tryParse(sharesCtrl.text.trim()) ?? 0.0;
                    final buyPrice = double.tryParse(buyPriceCtrl.text.trim()) ?? 0.0;
                    final currentPrice =
                        double.tryParse(currentPriceCtrl.text.trim()) ?? buyPrice;
                    final name = nameCtrl.text.trim();

                    if (symbol.isNotEmpty && shares > 0 && buyPrice > 0) {
                      setState(() {
                        _stocks.add(StockHolding(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          symbol: symbol,
                          companyName: name.isEmpty ? symbol : name,
                          shares: shares,
                          avgBuyPrice: buyPrice,
                          currentPrice: currentPrice,
                        ));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'Save Stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProfitable = _totalPnl >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Investments',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _openAddStockSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Portfolio Stock Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stocks Portfolio',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    Icon(Icons.show_chart, color: Color(0xFF10B981), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_totalCurrentValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invested',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${_totalInvested.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Returns',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isProfitable ? '+' : ''}\$${_totalPnl.toStringAsFixed(2)} (${isProfitable ? '+' : ''}${_totalPnlPercentage.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: isProfitable
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Holdings (${_stocks.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Market Price',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stock Holdings List
          if (_stocks.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Text(
                'No stocks added yet.\nTap + to add your first stock holding.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            )
          else
            ..._stocks.asMap().entries.map((entry) {
              final index = entry.key;
              final stock = entry.value;
              final pos = stock.isProfitable;

              return Dismissible(
                key: Key(stock.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  setState(() {
                    _stocks.removeAt(index);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF0F172A),
                        child: Text(
                          stock.symbol.length > 3
                              ? stock.symbol.substring(0, 3)
                              : stock.symbol,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock.symbol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${stock.shares % 1 == 0 ? stock.shares.toInt() : stock.shares} shares • \$${stock.avgBuyPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${stock.currentValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pos ? '+' : ''}\$${stock.totalGainLoss.toStringAsFixed(2)} (${pos ? '+' : ''}${stock.totalGainLossPercentage.toStringAsFixed(2)}%)',
                            style: TextStyle(
                              color: pos
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
