import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../model/wallet_model.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// Shared tones for the transaction history — Figma `Wallet 1`.
class _T {
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF7A8798);
  static const stroke = Color(0xFFE8ECF1);
  static const credit = Color(0xFF16A34A);
  static const debit = Color(0xFFE11D48);
  static const pending = Color(0xFFF59E0B);
}

/// The row above the list: `All / Credits / Debits` on the left, the orange
/// **Filter** button on the right.
///
/// The type chips are the design's. Tapping **Filter** drops the period list
/// under the button.
class TransactionFilters extends StatelessWidget {
  final TransactionType selectedType;
  final TimeFilter selectedTime;
  final Function(TransactionType) onTypeChanged;
  final Function(TimeFilter) onTimeChanged;

  /// Shows the orange button as "on" while a period other than All Time is
  /// narrowing the list, so an active filter is visible without opening the
  /// menu.
  final bool filtersActive;

  /// The screen draws this button in its own header, so the chips row leaves
  /// it out unless asked.
  final bool showFilterButton;

  const TransactionFilters({
    super.key,
    required this.selectedType,
    required this.selectedTime,
    required this.onTypeChanged,
    required this.onTimeChanged,
    this.filtersActive = false,
    this.showFilterButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(right: context.w(8)),
            child: Row(
              children: [
                _TypeChip(
                  label: 'All',
                  isSelected: selectedType == TransactionType.all,
                  onTap: () => onTypeChanged(TransactionType.all),
                ),
                SizedBox(width: context.w(8)),
                _TypeChip(
                  label: 'Credits',
                  isSelected: selectedType == TransactionType.credit,
                  onTap: () => onTypeChanged(TransactionType.credit),
                ),
                SizedBox(width: context.w(8)),
                _TypeChip(
                  label: 'Debits',
                  isSelected: selectedType == TransactionType.debit,
                  onTap: () => onTypeChanged(TransactionType.debit),
                ),
              ],
            ),
          ),
        ),
        if (showFilterButton)
          FilterButton(
            active: filtersActive,
            selectedTime: selectedTime,
            onTimeChanged: onTimeChanged,
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.AppBlue : Colors.white,
      borderRadius: BorderRadius.circular(context.r(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(4),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(
              color: isSelected ? AppColors.AppBlue : _T.stroke,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : _T.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// The orange **Filter** button and the period list it drops underneath.
class FilterButton extends StatelessWidget {
  final bool active;
  final TimeFilter selectedTime;
  final Function(TimeFilter) onTimeChanged;

  const FilterButton({
    super.key,
    required this.active,
    required this.selectedTime,
    required this.onTimeChanged,
  });

  static const _periods = <TimeFilter, String>{
    TimeFilter.allTime: 'All Time',
    TimeFilter.last3Days: 'Last 3 Days',
    TimeFilter.last7Days: 'Last 7 Days',
    TimeFilter.last30Days: 'Last 30 Days',
  };

  /// Opens the list directly under the button and aligned to its right edge,
  /// so the card hangs off the button rather than floating mid-screen.
  Future<void> _open(BuildContext context) async {
    final button = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final picked = await showMenu<TimeFilter>(
      context: context,
      color: Colors.white,
      elevation: 8,
      surfaceTintColor: Colors.white,
      shadowColor: const Color(0x33000000),
      constraints: BoxConstraints(minWidth: context.w(168)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(18)),
      ),
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        bottomRight.dy + context.h(6),
        overlay.size.width - bottomRight.dx,
        0,
      ),
      items: [
        for (final entry in _periods.entries)
          PopupMenuItem<TimeFilter>(
            value: entry.key,
            height: context.h(42),
            padding: EdgeInsets.symmetric(horizontal: context.w(20)),
            child: Text(
              entry.value,
              style: TextStyle(
                fontSize: context.fs(12),
                // The period in force is marked, so the menu says what the
                // list is already showing.
                fontWeight: entry.key == selectedTime
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: entry.key == selectedTime ? AppColors.AppBlue : _T.ink,
              ),
            ),
          ),
      ],
    );

    if (picked != null && picked != selectedTime) onTimeChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.OrangeColor,
      borderRadius: BorderRadius.circular(context.r(4)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(8),
            vertical: context.h(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              SizedBox(width: context.w(6)),
              Icon(
                Icons.tune_rounded,
                size: context.w(14),
                color: Colors.white,
              ),
              // A dot rather than a count: there is only ever one period in
              // force, so a number would say nothing.
              if (active) ...[
                SizedBox(width: context.w(5)),
                Container(
                  width: context.w(6),
                  height: context.w(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && transactions.isEmpty) {
      return const AppLoadingView.compact(message: 'Loading transactions…');
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: context.iconXLarge,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: context.gapMedium),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: context.bodyLarge,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.gapSmall),
            Text(
              'Your wallet transactions will appear here.',
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification &&
            scrollNotification.metrics.pixels ==
                scrollNotification.metrics.maxScrollExtent &&
            !isLoading &&
            hasMore) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: transactions.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: context.h(12)),
        itemBuilder: (context, index) {
          if (index == transactions.length) {
            return Padding(
              padding: EdgeInsets.all(context.w(12)),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return _TransactionCard(transaction: transactions[index]);
        },
      ),
    );
  }
}

/// One transaction, as the design draws it: icon tile, description and
/// timestamp, signed amount and a status pill, then a dashed rule above the
/// reference and the credit/debit word.
class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  bool get _isPending => transaction.status.toLowerCase().contains('pending');

  Color get _accent => transaction.isCredit ? _T.credit : _T.debit;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('transaction_${transaction.id}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _T.stroke),
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(14),
        context.w(14),
        context.h(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _icon(context),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: _T.ink,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      transaction.formattedDateTime,
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: _T.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(8)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${transaction.isCredit ? '+ ' : '- '}'
                    '${transaction.compactAmount}',
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  _statusPill(context),
                ],
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          _DashedRule(color: _T.stroke),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Expanded(
                child: Text(
                  transaction.reference.isEmpty
                      ? 'Ref: —'
                      : 'Ref: ${transaction.reference}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: _T.muted,
                  ),
                ),
              ),
              SizedBox(width: context.w(8)),
              Text(
                transaction.isCredit ? 'Credit' : 'Debit',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _icon(BuildContext context) {
    final tint = transaction.isCredit
        ? const Color(0xFFE8F7EE)
        : const Color(0xFFE7F2FD);
    return Container(
      width: context.w(38),
      height: context.w(38),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      child: Icon(
        transaction.isCredit
            ? Icons.add_card_rounded
            : Icons.flight_takeoff_rounded,
        size: context.w(19),
        color: transaction.isCredit ? _T.credit : AppColors.AppBlue,
      ),
    );
  }

  Widget _statusPill(BuildContext context) {
    final pending = _isPending;
    final bg = pending ? const Color(0xFFFDF0DC) : const Color(0xFFE2F1FD);
    final fg = pending ? _T.pending : AppColors.AppBlue;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.r(6)),
      ),
      child: Text(
        transaction.status.toUpperCase(),
        style: TextStyle(
          fontSize: context.fs(9),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
    );
  }
}

class _DashedRule extends StatelessWidget {
  final Color color;

  const _DashedRule({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 3.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count < 0 ? 0 : count,
            (_) => SizedBox(
              width: dash,
              height: 1,
              child: ColoredBox(color: color),
            ),
          ),
        );
      },
    );
  }
}
