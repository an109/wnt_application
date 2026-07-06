import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../ReferCode/presentation/bloc/referral_bloc.dart';
import '../../../ReferCode/presentation/bloc/referral_event.dart';
import '../../../ReferCode/presentation/bloc/referral_state.dart';
import '../../../ReferCredit/domain/entity/transaction_entity.dart';
import '../../../ReferCredit/presentation/bloc/transaction_bloc.dart';
import '../../../ReferCredit/presentation/bloc/transaction_event.dart';
import '../../../ReferCredit/presentation/bloc/transaction_state.dart';
import '../../../WalletStatus/domain/entity/loyality_entity.dart';
import '../../../WalletStatus/presentation/bloc/loyalty_bloc.dart';
import '../../../WalletStatus/presentation/bloc/loyalty_event.dart';
import '../../../WalletStatus/presentation/bloc/loyalty_state.dart';
import '../../presentation/bloc/wallet_bloc.dart';
import '../../presentation/bloc/wallet_event.dart';
import '../../presentation/bloc/wallet_state.dart';
import '../model/wallet_model.dart';
import '../widget/balance_card.dart';
import '../widget/notification_setting.dart';
import '../widget/transaction_list.dart';
import 'add_money_dialog.dart';
import '../../../../core/error/data_state.dart';


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Blocs owned by this state so _handleAddMoney and _fetchTransactions can
  // dispatch events without relying on context.read<>(), which would fail
  // because the BlocProviders are descendants, not ancestors, of this element.
  late final WalletBloc _walletBloc;
  late final TransactionBloc _transactionBloc;
  late final ReferralBloc _referralBloc;
  late final LoyaltyBloc _loyaltyBloc;

  List<Transaction> _allTransactions = [];
  NotificationSettings _notificationSettings = NotificationSettings();

  TransactionType _selectedType = TransactionType.all;
  TimeFilter _selectedTime = TimeFilter.allTime;
  String _searchQuery = '';

  bool _isLoadingTransactions = false;
  bool _hasMore = false;
  bool _isLoadMore = false;
  bool _isReferralCopied = false;

  @override
  void initState() {
    super.initState();
    _walletBloc = sl<WalletBloc>()..add(const FetchWalletBalance());
    _transactionBloc = sl<TransactionBloc>()..add(const FetchTransactions());
    _referralBloc = sl<ReferralBloc>()..add(const FetchReferralEvent());
    _loyaltyBloc = sl<LoyaltyBloc>()..add(FetchUserLoyalty());
  }

  @override
  void dispose() {
    _walletBloc.close();
    _transactionBloc.close();
    _referralBloc.close();
    _loyaltyBloc.close();
    super.dispose();
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
      _isLoadingTransactions = !reset; // Only show full screen loader if not loading more
    });

    // Calculate the next page based on current accumulated items (assuming page size 20)
    int nextPage = 1;
    if (!reset) {
      nextPage = (_allTransactions.length / 20).floor() + 1;
    }

    _transactionBloc.add(FetchTransactions(
      type: _getApiType(),
      days: _getApiDays(),
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: nextPage,
      loadMore: !reset,
    ));
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
            content: Text('₹${amount.toStringAsFixed(2)} added successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
        _walletBloc.add(const RefreshWalletBalance());
        _fetchTransactions(reset: true);
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

  // ==================== LOYALTY SECTION ====================
  Widget _buildLoyaltySection() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
        builder: (context, state) {
          if (state is LoyaltyLoading || state is LoyaltyInitial) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium, size: context.w(22), color: Colors.amber.shade700),
                    SizedBox(width: context.w(8)),
                    Text("Loyalty Tier", style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: context.h(16)),
                const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
              ],
            );
          }

          if (state is LoyaltyLoaded) {
            final dataState = state.dataState;
            if (dataState is DataSuccess<LoyaltyEntity>) {
              return _buildLoyaltyContent(dataState.data!);
            }
            if (dataState is DataFailed<LoyaltyEntity>) {
              return _buildLoyaltyError(dataState.error?.message ?? 'Failed to load');
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoyaltyContent(LoyaltyEntity loyalty) {
    final tierColor = _getColorFromHex(loyalty.tierColor);
    final progress = loyalty.progressPercentage;
    final isMaxTier = loyalty.nextTier == null || loyalty.bookingsNeeded == null || loyalty.bookingsNeeded == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.w(6)),
              decoration: BoxDecoration(color: tierColor.withOpacity(0.15), borderRadius: BorderRadius.circular(context.r(8))),
              child: Icon(Icons.workspace_premium, size: context.w(20), color: tierColor),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Loyalty Tier", style: TextStyle(fontSize: context.fs(12), color: Colors.grey.shade500)),
                  Text(loyalty.tierLabel, style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w700, color: tierColor)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(6)),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(context.r(20)),
                border: Border.all(color: tierColor.withOpacity(0.3)),
              ),
              child: Text(loyalty.tier.toUpperCase(), style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: tierColor, letterSpacing: context.letterSpacingWide)),
            ),
          ],
        ),
        SizedBox(height: context.h(16)),
        Container(
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.r(12))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress to ${isMaxTier ? "Max Tier" : loyalty.nextTierLabel ?? "Next Tier"}', style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                  Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w700, color: tierColor)),
                ],
              ),
              SizedBox(height: context.h(8)),
              ClipRRect(
                borderRadius: BorderRadius.circular(context.r(8)),
                child: LinearProgressIndicator(value: progress, minHeight: context.h(8), backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(tierColor)),
              ),
              SizedBox(height: context.h(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${loyalty.completedBookings} bookings completed', style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600)),
                  if (!isMaxTier && loyalty.bookingsNeeded != null)
                    Text('${loyalty.bookingsNeeded} more to go', style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600, fontWeight: FontWeight.w500))
                  else
                    Text('Highest tier reached', style: TextStyle(fontSize: context.fs(11), color: tierColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(16)),
        Text('Your Benefits', style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600)),
        SizedBox(height: context.h(8)),
        ...loyalty.benefits.map((benefit) => Padding(
          padding: EdgeInsets.only(bottom: context.h(6)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: EdgeInsets.only(top: context.h(2)), child: Icon(Icons.check_circle, size: context.w(16), color: tierColor)),
              SizedBox(width: context.w(8)),
              Expanded(child: Text(benefit, style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade700, height: 1.4))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLoyaltyError(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.workspace_premium, size: context.w(22), color: Colors.amber.shade700), SizedBox(width: context.w(8)), Text("Loyalty Tier", style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600))]),
        SizedBox(height: context.h(12)),
        Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: context.w(40), color: Colors.red.shade300),
              SizedBox(height: context.h(8)),
              Text("Failed to load loyalty data", style: TextStyle(fontSize: context.fs(14), color: Colors.grey.shade600)),
              SizedBox(height: context.h(4)),
              Text(message, style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade500), textAlign: TextAlign.center),
              SizedBox(height: context.h(12)),
              ElevatedButton.icon(
                onPressed: () => context.read<LoyaltyBloc>().add(FetchUserLoyalty()),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: context.w(20), vertical: context.h(10))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorFromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
  // ==================== END LOYALTY SECTION ====================

  Widget _buildReferAndEarnSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(8)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.w(8), offset: Offset(0, context.h(2)))],
      ),
      child: BlocBuilder<ReferralBloc, ReferralState>(
        builder: (context, state) {
          if (state is ReferralLoading || state is ReferralInitial) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.card_giftcard, size: 22), SizedBox(width: 8), Text("Refer & Earn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 12),
                const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
              ],
            );
          }

          if (state is ReferralSuccess && state.data != null) {
            final referral = state.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.card_giftcard, size: context.w(22)), SizedBox(width: context.w(8)), Text("Refer & Earn", style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600))]),
                SizedBox(height: context.h(6)),
                Text("Invite friends and earn rewards on every successful referral.", style: TextStyle(fontSize: context.fs(13), color: Colors.grey.shade600)),
                SizedBox(height: context.h(12)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(10)),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(context.r(12))),
                  child: Row(
                    children: [
                      Expanded(child: Text(referral.referralLink, style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w600, letterSpacing: context.letterSpacingWider))),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: referral.referralLink));
                          setState(() => _isReferralCopied = true);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Referral code copied")));
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _isReferralCopied = false);
                          });
                        },
                        child: Row(
                          children: [
                            Icon(_isReferralCopied ? Icons.check : Icons.copy, size: context.w(18)),
                            SizedBox(width: context.w(4)),
                            Text(_isReferralCopied ? "Copied" : "Copy", style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.fs(14))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(label: "Total Referrals", value: referral.totalReferrals.toString()),
                    _buildStatItem(label: "Total Earned", value: "${referral.totalEarned}"),
                  ],
                ),
              ],
            );
          }

          if (state is ReferralFailed) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.card_giftcard, size: context.w(22)), SizedBox(width: context.w(8)), Text("Refer & Earn", style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600))]),
                SizedBox(height: context.h(12)),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: context.w(40), color: Colors.red.shade300),
                      SizedBox(height: context.h(8)),
                      Text("Failed to load referral data", style: TextStyle(fontSize: context.fs(14), color: Colors.grey.shade600)),
                      SizedBox(height: context.h(12)),
                      ElevatedButton.icon(
                        onPressed: () => context.read<ReferralBloc>().add(const FetchReferralEvent()),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: context.w(20), vertical: context.h(10))),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.r(8))),
        child: Column(
          children: [
            SizedBox(height: context.h(4)),
            Text(value, style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.bold)),
            SizedBox(height: context.h(2)),
            Text(label, style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _walletBloc),
        BlocProvider.value(value: _referralBloc),
        BlocProvider.value(value: _loyaltyBloc),
        BlocProvider.value(value: _transactionBloc),
      ],
      // NEW: Listen to TransactionBloc state to update local UI state for pagination
      child: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess) {
            final converted = state.data.transactions.map(_toTransaction).toList();
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
                SnackBar(content: Text('Failed to load transactions: ${state.error.message}'), backgroundColor: Colors.red),
              );
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const WanderNovaLogo(scaleFactor: 0.6),
            backgroundColor: Colors.white,
            actions: [
              Padding(padding: EdgeInsets.all(context.w(8)), child: Image.asset("assets/images/wander_logo.png", height: 35))
            ],
          ),
          backgroundColor: AppColors.lightBg,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: context.horizontalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: context.gapMedium),
                        Text('My Wallet Balance', style: TextStyle(fontSize: context.headlineSmall, fontWeight: FontWeight.bold)),
                        SizedBox(height: context.gapXSmall),
                        Text('View your WALLET balance, earnings, and transaction history.', style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade600)),
                        SizedBox(height: context.gapLarge),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: context.horizontalPadding,
                    child: BlocBuilder<WalletBloc, WalletState>(
                      builder: (context, state) {
                        if (state is WalletLoading) {
                          return BalanceCard(balance: 0.0, totalEarnings: 0.0, currency: 'INR', isLoading: true, onRecharge: null);
                        }
                        if (state is WalletLoaded) {
                          final balanceValue = double.tryParse(state.balance) ?? 0.0;
                          final earningsValue = double.tryParse(state.totalEarnings) ?? 0.0;
                          return BalanceCard(balance: balanceValue, totalEarnings: earningsValue, currency: state.currency, isLoading: false, onRecharge: _showAddMoneyDialog);
                        }
                        if (state is WalletError) {
                          return BalanceCard(balance: 0.0, totalEarnings: 0.0, currency: 'INR', isLoading: false, onRecharge: _showAddMoneyDialog, errorMessage: state.message);
                        }
                        return BalanceCard(balance: 0.0, totalEarnings: 0.0, currency: 'INR', isLoading: true, onRecharge: null);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildReferAndEarnSection()),
                SliverToBoxAdapter(child: _buildLoyaltySection()),
                SliverToBoxAdapter(child: SizedBox(height: context.gapLarge)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: context.horizontalPadding,
                    child: Container(
                      padding: EdgeInsets.all(context.w(12)),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.borderRadiusMedium), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        children: [
                          Icon(Icons.credit_card, size: context.iconMedium, color: Colors.grey.shade600),
                          SizedBox(width: context.gapMedium),
                          Expanded(child: Text('Use for booking: You can pay with your wallet on the payment page when booking flights, hotels, or holidays.', style: TextStyle(fontSize: context.bodySmall, color: Colors.grey.shade700))),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: context.gapXLarge)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: context.horizontalPadding,
                    child: Text('Transactions', style: TextStyle(fontSize: context.titleMedium, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: context.gapMedium)),
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
                          if (_searchQuery == query && mounted) {
                            _fetchTransactions(reset: true);
                          }
                        });
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: context.gapMedium)),
                SliverToBoxAdapter(
                  child: Container(
                    constraints: BoxConstraints(minHeight: context.hp(40)),
                    padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
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
                SliverToBoxAdapter(child: SizedBox(height: context.gapMedium)),
                if (_allTransactions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: context.horizontalPadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // TextButton.icon(onPressed: _downloadStatement, icon: const Icon(Icons.download, size: 18), label: const Text('Download statement'), style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700)),
                          // SizedBox(width: context.gapSmall),
                          // ElevatedButton(
                          //   onPressed: _downloadStatement,
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.red.shade600,
                          //     foregroundColor: Colors.white,
                          //     padding: EdgeInsets.symmetric(horizontal: context.gapMedium, vertical: context.gapSmall),
                          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadiusSmall)),
                          //   ),
                          //   child: const Text('Last 30 days'),
                          // ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: context.gapLarge)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: context.horizontalPadding,
                    child: NotificationSettingsWidget(settings: _notificationSettings, onChanged: _updateNotificationSettings),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: context.gapXXLarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
