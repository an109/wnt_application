import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../model/wallet_model.dart';
import '../widget/balance_card.dart';
import '../widget/notificartion_setting.dart';
import '../widget/transaction_list.dart';
import '../widget/wallet_services.dart';
import 'add_money_dialog.dart';


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  WalletBalance _balance = const WalletBalance(balance: 0, totalEarnings: 0);
  List<Transaction> _transactions = [];
  NotificationSettings _notificationSettings = NotificationSettings();

  TransactionType _selectedType = TransactionType.all;
  TimeFilter _selectedTime = TimeFilter.allTime;
  String _searchQuery = '';

  bool _isLoading = false;
  bool _hasMore = false;
  int _currentPage = 0;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kDebugMode) {
      // This will print all GlobalKeys in the tree (helpful for debugging)
      debugPrint('🔍 WalletScreen rebuilding - checking for key conflicts');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchBalance(),
      _fetchTransactions(reset: true),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchBalance() async {
    try {
      final balance = await _walletService.getWalletBalance();
      if (mounted) {
        setState(() => _balance = balance);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _fetchTransactions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _transactions = [];
        _currentPage = 0;
      });
    }

    try {
      final transactions = await _walletService.getTransactions(
        type: _selectedType,
        timeFilter: _selectedTime,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            _transactions = transactions;
          } else {
            _transactions.addAll(transactions);
          }
          _currentPage++;
          _hasMore = transactions.isNotEmpty;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _showAddMoneyDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMoneyDialog(
        onConfirm: (amount, paymentMethod) {
          _handleAddMoney(amount, paymentMethod);
        },
      ),
    );
  }

  Future<void> _handleAddMoney(double amount, String paymentMethod) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _walletService.addMoney(amount, paymentMethod);
      if (mounted) {
        Navigator.pop(context); // Remove loading
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('₹${amount.toStringAsFixed(2)} added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchBalance();
          await _fetchTransactions(reset: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add money. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadStatement() async {
    try {
      await _walletService.downloadStatement(_selectedTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statement downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download statement.')),
        );
      }
    }
  }

  Future<void> _updateNotificationSettings(NotificationSettings settings) async {
    try {
      await _walletService.updateNotificationSettings(settings);
      setState(() => _notificationSettings = settings);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset("assets/images/wander_nova_logo.jpg", height: 35),
          )
        ],
      ),
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            // SliverAppBar(
            //   floating: true,
            //   backgroundColor: Colors.white,
            //   elevation: 0,
            //   title: Text(
            //     'My Wallet Balance',
            //     style: TextStyle(
            //       fontSize: context.titleLarge,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),

            // Header Section - FIXED: Removed the nested SliverToBoxAdapter
            SliverToBoxAdapter(
              child: Padding(
                padding: context.horizontalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.gapMedium),
                    Text(
                      'My Wallet Balance',
                      style: TextStyle(
                        fontSize: context.headlineSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.gapXSmall),
                    Text(
                      'View your WALLET balance, earnings, and transaction history.',
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: context.gapLarge), // Fixed: Just use SizedBox directly
                  ],
                ),
              ),
            ),

            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: context.horizontalPadding,
                child: BalanceCard(
                  balance: _balance.balance,
                  totalEarnings: _balance.totalEarnings,
                  onRecharge: _showAddMoneyDialog,
                ),
              ),
            ),

            // Spacing
            SliverToBoxAdapter(child: SizedBox(height: context.gapLarge)),

            // Info Card
            SliverToBoxAdapter(
              child: Padding(
                padding: context.horizontalPadding,
                child: Container(
                  padding: EdgeInsets.all(context.gapMedium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: context.iconMedium,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: context.gapMedium),
                      Expanded(
                        child: Text(
                          'Use for booking: You can pay with your wallet on the payment page when booking flights, hotels, or holidays.',
                          style: TextStyle(
                            fontSize: context.bodySmall,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Spacing
            SliverToBoxAdapter(child: SizedBox(height: context.gapXLarge)),

            // Transactions Section
            SliverToBoxAdapter(
              child: Padding(
                padding: context.horizontalPadding,
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: context.titleMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Spacing
            SliverToBoxAdapter(child: SizedBox(height: context.gapMedium)),

            // Transaction Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: context.horizontalPadding,
                child: TransactionFilters(
                  selectedType: _selectedType,
                  selectedTime: _selectedTime,
                  onTypeChanged: (type) {
                    setState(() => _selectedType = type);
                    _fetchTransactions(reset: true);
                  },
                  onTimeChanged: (time) {
                    setState(() => _selectedTime = time);
                    _fetchTransactions(reset: true);
                  },
                  onSearch: (query) {
                    setState(() => _searchQuery = query);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchQuery == query) {
                        _fetchTransactions(reset: true);
                      }
                    });
                  },
                ),
              ),
            ),

            // Spacing
            SliverToBoxAdapter(child: SizedBox(height: context.gapMedium)),

            // Transaction List
            SliverToBoxAdapter(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: context.hp(40),
                ),
                padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
                child: TransactionList(
                  transactions: _transactions,
                  isLoading: _isLoading,
                  hasMore: _hasMore,
                  onLoadMore: () => _fetchTransactions(),
                ),
              ),
            ),

            // Spacing
            SliverToBoxAdapter(child: SizedBox(height: context.gapMedium)),

            // Download Statement
            if (_transactions.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: context.horizontalPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _downloadStatement,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download statement'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: context.gapSmall),
                      ElevatedButton(
                        onPressed: _downloadStatement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.gapMedium,
                            vertical: context.gapSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                          ),
                        ),
                        child: const Text('Last 30 days'),
                      ),
                    ],
                  ),
                ),
              ),

            // Spacing
            SliverToBoxAdapter(child: SizedBox(height: context.gapLarge)),

            // Notification Settings
            SliverToBoxAdapter(
              child: Padding(
                padding: context.horizontalPadding,
                child: NotificationSettingsWidget(
                  settings: _notificationSettings,
                  onChanged: _updateNotificationSettings,
                ),
              ),
            ),

            // Bottom spacing
            SliverToBoxAdapter(child: SizedBox(height: context.gapXXLarge)),
          ],
        ),
      ),
    );
  }
}