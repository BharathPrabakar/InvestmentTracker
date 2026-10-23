import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_card_model.dart';
import '../../services/yahoo_finance_service.dart';

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

  String? _selectedFilterTag;

  List<String> get _allTags {
    final set = <String>{};
    for (final card in _investmentCards) {
      set.addAll(card.tags);
    }
    return set.toList();
  }

  List<InvestmentCardModel> get _filteredCards {
    if (_selectedFilterTag == null) return _investmentCards;
    return _investmentCards
        .where((c) => c.tags.contains(_selectedFilterTag))
        .toList();
  }

  void _openCreateCardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CreateInvestmentCardSheet(
        onCardCreated: (newCard) {
          setState(() {
            _investmentCards.insert(0, newCard);
          });
        },
      ),
    );
  }

  void _openAddTransactionModal(InvestmentCardModel card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddTransactionSheet(
        card: card,
        onTransactionAdded: (tx) {
          setState(() {
            card.transactions.add(tx);
          });
        },
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
        onPressed: _openCreateCardModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Filter Tags Bar
          if (_allTags.isNotEmpty) ...[
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedFilterTag == null,
                    selectedColor: const Color(0xFF10B981),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilterTag = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._allTags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text('#$tag'),
                          selected: _selectedFilterTag == tag,
                          selectedColor: const Color(0xFF10B981),
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilterTag = selected ? tag : null;
                            });
                          },
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Investment Cards
          if (_filteredCards.isEmpty)
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
            ..._filteredCards.map((card) => _buildInvestmentCard(card)),
          const SizedBox(height: 70), // padding for FAB
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(InvestmentCardModel card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const Border(),
        leading: CircleAvatar(
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
        title: Row(
          children: [
            Text(
              card.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const Spacer(),
            Text(
              '\$${card.totalInvested.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              card.companyName,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${card.totalQuantity % 1 == 0 ? card.totalQuantity.toInt() : card.totalQuantity} Qty',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Avg: \$${card.avgBuyPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            if (card.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: card.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        children: [
          const Divider(color: Color(0xFF334155)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transactions (Date-wise)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
              ),
              TextButton.icon(
                onPressed: () => _openAddTransactionModal(card),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF10B981)),
                label: const Text('Add Txn', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...card.sortedTransactions.map((tx) {
            final isBuy = tx.type == TransactionType.buy;
            final isSell = tx.type == TransactionType.sell;
            final dateStr = DateFormat('MMM dd, yyyy').format(tx.date);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isBuy
                              ? const Color(0xFF10B981)
                              : (isSell ? const Color(0xFFEF4444) : const Color(0xFF6366F1)))
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tx.typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isBuy
                            ? const Color(0xFF10B981)
                            : (isSell ? const Color(0xFFEF4444) : const Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${tx.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      Text(
                        '${tx.quantity % 1 == 0 ? tx.quantity.toInt() : tx.quantity} @ \$${tx.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class CreateInvestmentCardSheet extends StatefulWidget {
  final Function(InvestmentCardModel) onCardCreated;

  const CreateInvestmentCardSheet({super.key, required this.onCardCreated});

  @override
  State<CreateInvestmentCardSheet> createState() => _CreateInvestmentCardSheetState();
}

class _CreateInvestmentCardSheetState extends State<CreateInvestmentCardSheet> {
  // Stock Selection via Yahoo Search
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  List<YahooStockSearchResult> _searchResults = [];
  bool _isSearching = false;
  YahooStockSearchResult? _selectedStock;

  // Tags
  final TextEditingController _tagInputCtrl = TextEditingController();
  final List<String> _tags = [];

  // Transaction Form fields
  final String _actionType = 'BUY'; // Initially only buy
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tagInputCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _amountCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() {
        _isSearching = true;
      });
      final results = await YahooFinanceService.searchStocks(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _calculateAmount() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    if (price > 0 && qty > 0) {
      _amountCtrl.text = (price * qty).toStringAsFixed(2);
    }
  }

  void _addTag() {
    final text = _tagInputCtrl.text.trim().replaceAll('#', '');
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagInputCtrl.clear();
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              surface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_selectedStock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please search and select a stock from Yahoo Finance')),
      );
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? (price * qty);

    if (price <= 0 || qty <= 0 || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid price and quantity')),
      );
      return;
    }

    final initialTx = Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.buy,
      date: _selectedDate,
      price: price,
      quantity: qty,
      amount: amount,
    );

    final card = InvestmentCardModel(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      symbol: _selectedStock!.symbol,
      companyName: _selectedStock!.displayName,
      tags: List.from(_tags),
      transactions: [initialTx],
    );

    widget.onCardCreated(card);
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
                const Text(
                  'Create Investment Card',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Step 1: Select Stock (Yahoo Search)
            const Text(
              '1. Select Stock (Yahoo Search)',
              style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (_selectedStock != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedStock!.symbol} - ${_selectedStock!.displayName}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.change_circle, color: Colors.white60, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedStock = null;
                        });
                      },
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search ticker or company (e.g. AAPL, TSLA, INFY)...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFF334155)),
                    itemBuilder: (ctx, idx) {
                      final item = _searchResults[idx];
                      return ListTile(
                        dense: true,
                        title: Text(item.symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(
                          '${item.displayName} (${item.exchange})',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedStock = item;
                            _searchResults = [];
                            _searchCtrl.text = item.symbol;
                          });
                        },
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Step 2: Tags
            const Text(
              '2. Enter Tags (Multiple tags per card)',
              style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputCtrl,
                    onSubmitted: (_) => _addTag(),
                    decoration: const InputDecoration(
                      hintText: 'Enter tag (e.g. Dividend, EV) and tap +',
                      filled: true,
                      fillColor: Color(0xFF0F172A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                  icon: const Icon(Icons.add, color: Color(0xFF10B981)),
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFF0F172A),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Step 3: Transaction Details
            const Text(
              '3. Initial Transaction (Action: BUY)',
              style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Action: Buy & Date
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Text(
                      'Action: $_actionType',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF334155)),
                      backgroundColor: const Color(0xFF0F172A),
                    ),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                    label: Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock Price & Quantity
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _calculateAmount(),
                    decoration: const InputDecoration(
                      labelText: 'Stock Price (\$)',
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

            // Total Amount
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Amount (\$) (Auto-computed)',
                filled: true,
                fillColor: Color(0xFF0F172A),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submit,
                child: const Text(
                  'Submit Investment Card',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
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
