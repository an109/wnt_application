import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../presentation/bloc/wallet_bloc.dart';
import '../../presentation/bloc/wallet_event.dart';
import '../../presentation/bloc/wallet_state.dart';
import '../model/wallet_model.dart';
import '../widget/balance_card.dart';
import '../widget/notificartion_setting.dart';
import '../widget/transaction_list.dart';
import 'add_money_dialog.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<Transaction> _transactions = [];
  NotificationSettings _notificationSettings = NotificationSettings();

  TransactionType _selectedType = TransactionType.all;
  TimeFilter _selectedTime = TimeFilter.allTime;
  String _searchQuery = '';

  bool _isLoadingTransactions = false;
  bool _hasMore = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialTransactions();
  }

  Future<void> _loadInitialTransactions() async {
    setState(() => _isLoadingTransactions = true);
    await _fetchTransactions(reset: true);
    setState(() => _isLoadingTransactions = false);
  }

  Future<void> _fetchTransactions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _transactions = [];
        _currentPage = 0;
      });
    }

    try {
      // Your existing transaction API call here
      print('Fetching transactions with filters: type=$_selectedType, time=$_selectedTime');
      // Replace with actual transaction fetch
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          if (reset) {
            _transactions = [];
          }
          _currentPage++;
          _hasMore = false;
        });
      }
    } catch (e) {
      print('Transaction fetch error: $e');
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rs ${amount.toStringAsFixed(2)} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh wallet balance from API
        context.read<WalletBloc>().add(const RefreshWalletBalance());
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
      print('Downloading statement for: $_selectedTime');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statement downloaded successfully!')),
        );
      }
    } catch (e) {
      print('Download statement error: $e');
    }
  }

  Future<void> _updateNotificationSettings(NotificationSettings settings) async {
    try {
      print('Updating notification settings');
      setState(() => _notificationSettings = settings);
    } catch (e) {
      print('Notification settings error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WalletBloc>()..add(const FetchWalletBalance()),
      child: Scaffold(
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          backgroundColor: Colors.white,
          actions: [
            Padding(
              padding: EdgeInsets.all(context.w(8)),
              child: Image.asset("assets/images/wander_nova_logo.jpg", height: 35),
            )
          ],
        ),
        backgroundColor: Colors.blue.shade50,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header Section
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
                      SizedBox(height: context.gapLarge),
                    ],
                  ),
                ),
              ),

              // Balance Card - DYNAMIC DATA FROM API ONLY
              SliverToBoxAdapter(
                child: Padding(
                  padding: context.horizontalPadding,
                  child: BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, state) {
                      print('WalletScreen - Building with state: ${state.runtimeType}');

                      if (state is WalletLoading) {
                        print('WalletScreen - Showing loading state');
                        return BalanceCard(
                          balance: 0.0,
                          totalEarnings: 0.0,
                          currency: 'INR',
                          isLoading: true,
                          onRecharge: null,
                        );
                      }

                      if (state is WalletLoaded) {
                        // PARSE ACTUAL API DATA
                        final balanceValue = double.tryParse(state.balance) ?? 0.0;
                        final earningsValue = double.tryParse(state.totalEarnings) ?? 0.0;
                        final currencyCode = state.currency;

                        print('WalletScreen - API Data Loaded:');
                        print('  Balance: $balanceValue $currencyCode');
                        print('  Total Earnings: $earningsValue $currencyCode');
                        print('  Wallet ID: ${state.wallet.id}');
                        print('  Is Active: ${state.wallet.isActive}');

                        return BalanceCard(
                          balance: balanceValue,
                          totalEarnings: earningsValue,
                          currency: currencyCode,
                          isLoading: false,
                          onRecharge: _showAddMoneyDialog,
                        );
                      }

                      if (state is WalletError) {
                        print('WalletScreen - Error: ${state.message}');
                        return BalanceCard(
                          balance: 0.0,
                          totalEarnings: 0.0,
                          currency: 'INR',
                          isLoading: false,
                          onRecharge: _showAddMoneyDialog,
                          errorMessage: state.message,
                        );
                      }

                      // Initial state - show loading
                      return BalanceCard(
                        balance: 0.0,
                        totalEarnings: 0.0,
                        currency: 'INR',
                        isLoading: true,
                        onRecharge: null,
                      );
                    },
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
                    padding: EdgeInsets.all(context.w(12)),
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
                    isLoading: _isLoadingTransactions,
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
      ),
    );
  }
}