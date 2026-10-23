import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      symbol: 'AAPL',
      companyName: 'Apple Inc.',
      tags: ['Tech', 'Long-term', 'Bluechip'],
      transactions: [
        Transaction(
          id: 'tx_1',
          type: TransactionType.buy,
          date: DateTime.now().subtract(const Duration(days: 30)),
          price: 180.0,
          quantity: 10.0,
          amount: 1800.0,
        ),
      ],
    ),
    InvestmentCardModel(
      id: '2',
      symbol: 'NVDA',
      companyName: 'NVIDIA Corporation',
      tags: ['AI', 'High Growth', 'Semiconductors'],
      transactions: [
        Transaction(
          id: 'tx_2',
          type: TransactionType.buy,
          date: DateTime.now().subtract(const Duration(days: 14)),
          price: 110.0,
          quantity: 15.0,
          amount: 1650.0,
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
            setState(() {});
          },
        ),
      ),
    );
  }

  void _confirmDeleteCard(InvestmentCardModel card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Investment Card?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete ${card.symbol} and its transaction history?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              setState(() {
                _investmentCards.remove(card);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
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

  /// Compact outside card showing ONLY basic details (Symbol, Name, Qty, Total Invested, Delete)
  Widget _buildBasicCard(InvestmentCardModel card) {
    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        setState(() {
          _investmentCards.remove(card);
        });
      },
      child: Container(
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
                      '\$${card.totalInvested.toStringAsFixed(2)}',
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white30),
                  onPressed: () => _confirmDeleteCard(card),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  final InvestmentCardModel card;
  final Function(Transaction) onTransactionAdded;

  const AddTransactionSheet({super.key, required this.card, required this.onTransactionAdded});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  TransactionType _type = TransactionType.buy;
  DateTime _date = DateTime.now();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    if (price > 0 && qty > 0) {
      _amountCtrl.text = (price * qty).toStringAsFixed(2);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10B981),
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submit() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? (price * qty);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid transaction numbers')),
      );
      return;
    }

    final tx = Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      date: _date,
      price: price,
      quantity: qty,
      amount: amount,
    );

    widget.onTransactionAdded(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Transaction (${widget.card.symbol})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transaction Type Selector
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.buy, label: Text('BUY')),
                ButtonSegment(value: TransactionType.sell, label: Text('SELL')),
                ButtonSegment(value: TransactionType.dividend, label: Text('DIVIDEND')),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() {
                  _type = set.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Date picker
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: Color(0xFF334155)),
                backgroundColor: const Color(0xFF0F172A),
              ),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              label: Text(
                DateFormat('dd MMM yyyy').format(_date),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),

            // Price & Quantity (if not dividend)
            if (_type != TransactionType.dividend) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculateAmount(),
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        filled: true,
                        fillColor: Color(0xFF0F172A),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculateAmount(),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        filled: true,
                        fillColor: Color(0xFF0F172A),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Total Amount
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _type == TransactionType.dividend
                    ? 'Dividend Payout Amount (\$)'
                    : 'Total Transaction Amount (\$)',
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submit,
                child: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
