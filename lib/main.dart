import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/pool_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/liquidity_screen.dart';
import 'screens/pool_overview_screen.dart';
import 'screens/swap_screen.dart';
import 'screens/wallet_screen.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_gate.dart';
import 'widgets/deep_link_listener.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget, matching WalletProvider's own startup pattern: a
  // missing Firebase project config must not block app launch, and
  // initialize() already swallows that failure internally.
  NotificationService().initialize();
  // Constructed here, early, so app_links can capture the link that
  // launched the app from a cold start. It's only acted on once
  // DeepLinkListener mounts, which happens after AppLockGate unlocks.
  final deepLinkService = DeepLinkService();
  runApp(AMMobileApp(deepLinkService: deepLinkService));
}

class AMMobileApp extends StatelessWidget {
  const AMMobileApp({super.key, required this.deepLinkService});

  final DeepLinkService deepLinkService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => PoolProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'AMM Mobile App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: AppLockGate(
          child: DeepLinkListener(
            linkStream: deepLinkService.links,
            child: const HomeScreen(),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PoolOverviewScreen(),
    LiquidityScreen(),
    SwapScreen(),
    WalletScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_outlined),
            activeIcon: Icon(Icons.water_drop),
            label: 'Pools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Liquidity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz),
            label: 'Swap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}
