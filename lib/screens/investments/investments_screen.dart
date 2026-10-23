import 'package:flutter/material.dart';
import '../../models/investment_card_model.dart';
import 'create_card_flow_screen.dart';
import 'investment_card_detail_screen.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  final List<InvestmentCardModel> _investmentCards = [
    InvestmentCardModel(
      id: '1',
      symbol: 'RELIANCE.NS',
      companyName: 'Reliance Industries Limited',
      tags: ['Energy', 'Bluechip', 'Nifty50'],
      transactions: [
        Transaction(
          id: 'tx_1',
          type: TransactionType.buy,
          date: DateTime.now().subtract(const Duration(days: 30)),
          price: 2850.0,
          quantity: 10.0,
          amount: 28500.0,
        ),
      ],
    ),
    InvestmentCardModel(
      id: '2',
      symbol: 'TCS.NS',
      companyName: 'Tata Consultancy Services',
      tags: ['IT', 'Tata Group', 'Dividend'],
      transactions: [
        Transaction(
          id: 'tx_2',
          type: TransactionType.buy,
          date: DateTime.now().subtract(const Duration(days: 14)),
          price: 4120.0,
          quantity: 5.0,
          amount: 20600.0,
        ),
      ],
    ),
  ];

  List<String> get _existingSymbols =>
      _investmentCards.map((c) => c.symbol).toList();

  Future<void> _openCreateCardFlow() async {
    final newCard = await Navigator.push<InvestmentCardModel>(
      context,
      MaterialPageRoute(
        builder: (ctx) => CreateCardFlowScreen(
          existingSymbols: _existingSymbols,
        ),
      ),
    );

    if (newCard != null && mounted) {
      setState(() {
        _investmentCards.insert(0, newCard);
      });
    }
  }

  void _openCardDetail(InvestmentCardModel card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => InvestmentCardDetailScreen(
          card: card,
          onCardDeleted: () {
            setState(() {
              _investmentCards.remove(card);
            });
          },
          onStateChanged: () {
            setState(() {
              _investmentCards.removeWhere((c) => c.transactions.isEmpty);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Investments',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _openCreateCardFlow,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          if (_investmentCards.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60),
              alignment: Alignment.center,
              child: const Text(
                'No investment cards created yet.\nTap "+ New Card" to select a stock and begin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            )
          else
            ..._investmentCards.map((card) => _buildBasicCard(card)),
          const SizedBox(height: 70), // padding for FAB
        ],
      ),
    );
  }

  /// Compact outside card showing ONLY basic details (Symbol, Name, Qty, Total Invested).
  /// Touching anywhere on the card navigates directly to the full detail screen.
  Widget _buildBasicCard(InvestmentCardModel card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openCardDetail(card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Symbol, Name, Chevron
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF0F172A),
                    child: Text(
                      card.symbol.length > 3 ? card.symbol.substring(0, 3) : card.symbol,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.symbol,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          card.companyName,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.white30),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFF334155)),
              const SizedBox(height: 12),
              // Basic details grid: Total Investment, Realized P/L, Unrealized P/L, Total Dividends
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total Investment
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Investment',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₹${card.totalInvested.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  // Realized P/L
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Realized P/L',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${card.realizedPnL >= 0 ? '+' : ''}₹${card.realizedPnL.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: card.realizedPnL >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  // Unrealized P/L
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unrealized P/L',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${card.unrealizedPnL >= 0 ? '+' : ''}₹${card.unrealizedPnL.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: card.unrealizedPnL >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  // Total Dividends
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Dividends',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₹${card.totalDividends.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
