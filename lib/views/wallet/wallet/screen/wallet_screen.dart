import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../ReferCredit/domain/entity/transaction_entity.dart';
import '../../../ReferCredit/presentation/bloc/transaction_bloc.dart';
import '../../../ReferCredit/presentation/bloc/transaction_event.dart';
import '../../../ReferCredit/presentation/bloc/transaction_state.dart';
import '../../presentation/bloc/wallet_bloc.dart';
import '../../presentation/bloc/wallet_event.dart';
import '../../presentation/bloc/wallet_state.dart';
import '../model/wallet_model.dart';
import '../widget/notification_setting.dart';
import '../widget/transaction_list.dart';
import '../widget/wallet_balance_card.dart';
import 'wallet_topup_checkout_screen.dart';

/// "Wallet" — Figma `Wallet 1`.
///
/// Balance card, then transaction history. Refer & Earn and Loyalty Tier used
/// to sit between the two; they now have their own screen, reached from the
/// drawer's **Rewards** entry (`RewardsScreen`).
///
/// Nothing the old screen could do was dropped. The type chips are the
/// design's, and the time filter and the search box moved behind the orange
/// **Filter** button, which opens [TransactionFilterSheet].
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Blocs owned by this state so the fetch helpers can dispatch without
  // context.read<>(), which would fail because the BlocProviders are
  // descendants, not ancestors, of this element.
  late final WalletBloc _walletBloc;
  late final TransactionBloc _transactionBloc;

  List<Transaction> _allTransactions = [];
  NotificationSettings _notificationSettings = NotificationSettings();

  TransactionType _selectedType = TransactionType.all;
  TimeFilter _selectedTime = TimeFilter.allTime;
  String _searchQuery = '';

  bool _isLoadingTransactions = false;
  bool _hasMore = false;
  bool _isLoadMore = false;

  @override
  void initState() {
    super.initState();
    _walletBloc = sl<WalletBloc>()..add(const FetchWalletBalance());
    _transactionBloc = sl<TransactionBloc>()..add(const FetchTransactions());
  }

  @override
  void dispose() {
    _walletBloc.close();
    _transactionBloc.close();
    super.dispose();
  }

  /// True while the sheet's controls are narrowing the list, so the Filter
  /// button can show that something is on even while the sheet is closed.
  bool get _filtersActive =>
      _selectedTime != TimeFilter.allTime || _searchQuery.isNotEmpty;

  /// Login saves `firstname` / `lastname` (no `name` key), so build the
  /// holder name from those; a plain `name` still wins when present.
  String get _holderName {
    final data = sl<PreferencesManager>().getUserData() ?? const {};
    String read(String key) => (data[key] ?? '').toString().trim();
    final full = read('name');
    final name = full.isNotEmpty
        ? full
        : '${read('firstname')} ${read('lastname')}'.trim();
    return name.isEmpty ? 'Wander Nova' : name;
  }

  Transaction _toTransaction(TransactionEntity entity) {
    const creditTypes = {'credit', 'bonus', 'refund'};
    return Transaction(
      id: entity.id.toString(),
      description: entity.description,
      amount: double.tryParse(entity.amount) ?? 0.0,
      date: DateTime.tryParse(entity.created) ?? DateTime.now(),
      isCredit: creditTypes.contains(entity.transactionType),
      status: entity.status,
      // Carried through so the card can print the `Ref:` line the design
      // shows; the backend has always sent it, the old row just dropped it.
      reference: entity.reference,
    );
  }

  // Helper to map TransactionType enum to API string parameter
  String? _getApiType() {
    final name = _selectedType.toString().split('.').last;
    return name == 'all' ? null : name;
  }

  // Helper to map TimeFilter enum to API days integer parameter
  int? _getApiDays() {
    final name = _selectedTime.toString().split('.').last;
    if (name == 'last3Days') return 3;
    if (name == 'last7Days' || name == 'week') return 7;
    if (name == 'last30Days' || name == 'month') return 30;
    return null;
  }

  // Centralized fetch method that dispatches events to the TransactionBloc
  void _fetchTransactions({bool reset = false}) {
    if (reset) {
      setState(() {
        _allTransactions = [];
        _hasMore = false;
        _isLoadMore = false;
      });
    }

    setState(() {
      if (!reset) _isLoadMore = true;
      _isLoadingTransactions =
          !reset; // Only show full screen loader if not loading more
    });

    // Calculate the next page based on current accumulated items (assuming page size 20)
    int nextPage = 1;
    if (!reset) {
      nextPage = (_allTransactions.length / 20).floor() + 1;
    }

    _transactionBloc.add(
      FetchTransactions(
        type: _getApiType(),
        days: _getApiDays(),
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: nextPage,
        loadMore: !reset,
      ),
    );
  }

  // ------------------------------------------------------------- top up

  /// Opens the top-up checkout. The amount is entered there now — the design
  /// puts it on the same screen as the methods — so the dialog that used to
  /// ask for it first is no longer in the way.
  Future<void> _openTopUp() async {
    if (!sl<PreferencesManager>().isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add money to your wallet.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final credited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WalletTopUpCheckoutScreen()),
    );

    if (credited == true && mounted) {
      _walletBloc.add(const RefreshWalletBalance());
      _fetchTransactions(reset: true);
    }
  }

  void _onTimeChanged(TimeFilter time) {
    setState(() => _selectedTime = time);
    _fetchTransactions(reset: true);
  }

  Future<void> _updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    setState(() => _notificationSettings = settings);
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _walletBloc),
        BlocProvider.value(value: _transactionBloc),
      ],
      // Listen to TransactionBloc state to update local UI state for pagination
      child: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess) {
            final converted = state.data.transactions
                .map(_toTransaction)
                .toList();
            setState(() {
              if (_isLoadMore) {
                _allTransactions.addAll(converted);
              } else {
                _allTransactions = converted;
              }
              _hasMore = state.hasMore;
              _isLoadingTransactions = false;
              _isLoadMore = false;
            });
          } else if (state is TransactionLoading) {
            if (!_isLoadMore) {
              setState(() => _isLoadingTransactions = true);
            }
          } else if (state is TransactionFailed) {
            setState(() {
              _isLoadingTransactions = false;
              _isLoadMore = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to load transactions: ${state.error.message}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _walletBloc.add(const RefreshWalletBalance());
                      _fetchTransactions(reset: true);
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _balanceCard(context)),
                        SliverToBoxAdapter(
                          child: SizedBox(height: context.h(28)),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(16),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Transaction History',
                                  style: TextStyle(
                                    fontSize: context.fs(16),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const Spacer(),
                                FilterButton(
                                  active: _filtersActive,
                                  selectedTime: _selectedTime,
                                  onTimeChanged: _onTimeChanged,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: context.h(14)),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(12),
                              vertical: context.h(4)
                            ),
                            child: TransactionFilters(
                              selectedType: _selectedType,
                              selectedTime: _selectedTime,
                              filtersActive: _filtersActive,
                              onTypeChanged: (type) {
                                setState(() => _selectedType = type);
                                _fetchTransactions(reset: true);
                              },
                              onTimeChanged: _onTimeChanged,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: context.h(16)),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            constraints: BoxConstraints(
                              minHeight: context.hp(30),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(16),
                            ),
                            child: TransactionList(
                              transactions: _allTransactions,
                              isLoading: _isLoadingTransactions,
                              hasMore: _hasMore,
                              onLoadMore: () {
                                if (_hasMore && !_isLoadingTransactions) {
                                  _fetchTransactions(reset: false);
                                }
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: context.h(24)),
                        ),
                        // SliverToBoxAdapter(child: _bookingNote(context)),
                        // SliverToBoxAdapter(
                        //   child: SizedBox(height: context.h(20)),
                        // ),
                        // SliverToBoxAdapter(
                        //   child: Padding(
                        //     padding: EdgeInsets.symmetric(
                        //       horizontal: context.w(16),
                        //     ),
                        //     child: NotificationSettingsWidget(
                        //       settings: _notificationSettings,
                        //       onChanged: _updateNotificationSettings,
                        //     ),
                        //   ),
                        // ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: context.h(32)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(8),
        context.w(16),
        context.h(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: EdgeInsets.all(context.w(4)),
              child: Icon(
                Icons.arrow_back_rounded,
                size: context.w(21),
                color: AppColors.navy,
              ),
            ),
          ),
          SizedBox(width: context.w(14)),
          Text(
            'Wallet',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoaded) {
            return WalletBalanceCard(
              balance: double.tryParse(state.balance) ?? 0.0,
              currencySymbol: _symbolFor(state.currency),
              holderName: _holderName,
              onTopUp: _openTopUp,
            );
          }
          if (state is WalletError) {
            return WalletBalanceCard(
              balance: 0.0,
              holderName: _holderName,
              errorMessage: state.message,
              onTopUp: _openTopUp,
            );
          }
          // Loading and initial both show the card skeleton rather than a bare
          // spinner, so the page does not jump once the balance lands.
          return WalletBalanceCard(
            balance: 0.0,
            holderName: _holderName,
            isLoading: true,
          );
        },
      ),
    );
  }

  static String _symbolFor(String currency) {
    const symbols = {
      'INR': '₹',
      'USD': '\$',
      'AED': 'د.إ',
      'EUR': '€',
      'GBP': '£',
    };
    return symbols[currency.toUpperCase()] ?? '₹';
  }

  Widget _bookingNote(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: const Color(0xFFE8ECF1)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card,
              size: context.w(20),
              color: Colors.grey.shade600,
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Text(
                'Use for booking: You can pay with your wallet on the payment '
                'page when booking flights, hotels, or holidays.',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
