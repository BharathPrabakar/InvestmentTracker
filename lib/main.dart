import 'package:flutter/material.dart';

void main() {
  runApp(const InvestmentTrackerApp());
}

class InvestmentTrackerApp extends StatelessWidget {
  const InvestmentTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investment Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainMobileScreen(),
    );
  }
}

class MainMobileScreen extends StatefulWidget {
  const MainMobileScreen({super.key});

  @override
  State<MainMobileScreen> createState() => _MainMobileScreenState();
}

class _MainMobileScreenState extends State<MainMobileScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScreenPlaceholder(title: 'Investments'),
    ScreenPlaceholder(title: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.2),
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
            label: 'Investments',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Color(0xFF10B981)),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class ScreenPlaceholder extends StatelessWidget {
  final String title;

  const ScreenPlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
