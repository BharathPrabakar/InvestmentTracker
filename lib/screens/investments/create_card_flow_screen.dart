import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_card_model.dart';
import '../../services/yahoo_finance_service.dart';

class CreateCardFlowScreen extends StatefulWidget {
  final List<String> existingSymbols;

  const CreateCardFlowScreen({super.key, required this.existingSymbols});

  @override
  State<CreateCardFlowScreen> createState() => _CreateCardFlowScreenState();
}

class _CreateCardFlowScreenState extends State<CreateCardFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Selected Stock
  YahooStockSearchResult? _selectedStock;
  final TextEditingController _searchCtrl = TextEditingController();
  List<YahooStockSearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Tags
  final List<String> _tags = [];
  final TextEditingController _tagInputCtrl = TextEditingController();

  // Initial Transaction
  final String _actionType = 'BUY'; // Initially only buy
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
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

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
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

  void _addTag() {
    final text = _tagInputCtrl.text.trim().replaceAll('#', '');
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagInputCtrl.clear();
      });
    }
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
      initialDate: _selectedDate,
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
        _selectedDate = picked;
      });
    }
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _submitCard() {
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

    Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Select Stock', 'Add Tags', 'Initial Transaction'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_currentPage],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _prevPage();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Step progress bar
          LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 3,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildStep1SelectStock(),
                _buildStep2EnterTags(),
                _buildStep3Transaction(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 1 Page: Select Stock
  Widget _buildStep1SelectStock() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search and select a stock',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Only stocks not already added to your portfolio can be chosen.',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search ticker (e.g. AAPL, TSLA, INFY)...',
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
              fillColor: const Color(0xFF1E293B),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchCtrl.text.isEmpty
                          ? 'Start typing to search stocks via Yahoo Finance'
                          : 'No matching stocks found',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFF334155)),
                    itemBuilder: (ctx, idx) {
                      final item = _searchResults[idx];
                      final isAlreadyAdded = widget.existingSymbols
                          .map((s) => s.toUpperCase())
                          .contains(item.symbol.toUpperCase());

                      return ListTile(
                        enabled: !isAlreadyAdded,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0F172A),
                          child: Text(
                            item.symbol.length > 3 ? item.symbol.substring(0, 3) : item.symbol,
                            style: TextStyle(
                              color: isAlreadyAdded ? Colors.white38 : const Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              item.symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAlreadyAdded ? Colors.white38 : Colors.white,
                              ),
                            ),
                            if (isAlreadyAdded) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Already Added',
                                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${item.displayName} • ${item.exchange}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isAlreadyAdded
                            ? const Icon(Icons.block, color: Colors.white24, size: 20)
                            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                        onTap: isAlreadyAdded
                            ? null
                            : () {
                                setState(() {
                                  _selectedStock = item;
                                });
                                _nextPage();
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Step 2 Page: Enter Tags
  Widget _buildStep2EnterTags() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                child: const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 10),
              Text(
                'Selected: ${_selectedStock?.symbol ?? ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Enter tags for this investment card',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'One card can hold multiple tags (e.g. Bluechip, High Growth, Dividend).',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagInputCtrl,
                  onSubmitted: (_) => _addTag(),
                  decoration: const InputDecoration(
                    hintText: 'Type tag and tap add...',
                    filled: true,
                    fillColor: Color(0xFF1E293B),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _addTag,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tags.isEmpty
                ? const Center(
                    child: Text(
                      'No tags added yet (Optional).\nYou can continue or add tags above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map(
                            (tag) => Chip(
                              backgroundColor: const Color(0xFF1E293B),
                              label: Text('#$tag', style: const TextStyle(color: Colors.white)),
                              deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                              onDeleted: () {
                                setState(() {
                                  _tags.remove(tag);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _nextPage,
              child: const Text('Next: Initial Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3 Page: Initial Transaction (Buy)
  Widget _buildStep3Transaction() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected stock and tags summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedStock?.symbol} - ${_selectedStock?.displayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _tags.map((t) => '#$t').join('  '),
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action: Buy
            const Text(
              'Action',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: 46,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Text(
                _actionType,
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),

            // Date
            const Text(
              'Date',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                alignment: Alignment.centerLeft,
                side: const BorderSide(color: Color(0xFF334155)),
                backgroundColor: const Color(0xFF1E293B),
              ),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              label: Text(
                DateFormat('dd MMM yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Stock Price & Quantity
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stock Price (\$)',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _calculateAmount(),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          filled: true,
                          fillColor: Color(0xFF1E293B),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _calculateAmount(),
                        decoration: const InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: Color(0xFF1E293B),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Amount
            const Text(
              'Total Amount (\$)',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0.00',
                filled: true,
                fillColor: Color(0xFF1E293B),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submitCard,
                child: const Text('Create Investment Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
