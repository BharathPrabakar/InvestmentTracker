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
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF0F172A),
                child: Text(
                  card.symbol.length > 3 ? card.symbol.substring(0, 3) : card.symbol,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.symbol,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.companyName,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${card.totalInvested.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${card.totalQuantity % 1 == 0 ? card.totalQuantity.toInt() : card.totalQuantity} Shares',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}
