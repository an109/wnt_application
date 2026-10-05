import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../model/wallet_model.dart';

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
/// The type chips are the design's; the time filter and the search box they
/// replaced are not lost — they live behind [onOpenFilters], which the wallet
/// screen opens as a sheet.
class TransactionFilters extends StatelessWidget {
  final TransactionType selectedType;
  final TimeFilter selectedTime;
  final Function(TransactionType) onTypeChanged;
  final VoidCallback onOpenFilters;

  /// Shows the orange button as "on" while anything inside the sheet is
  /// narrowing the list, so an active time filter or search is never
  /// invisible just because the sheet is closed.
  final bool filtersActive;

  final bool showFilterButton;

  const TransactionFilters({
    super.key,
    required this.selectedType,
    required this.selectedTime,
    required this.onTypeChanged,
    required this.onOpenFilters,
    this.filtersActive = false,
    this.showFilterButton = true,
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
        // _FilterButton(active: filtersActive, onTap: onOpenFilters),
        // if (showFilterButton)
        //   FilterButton(active: filtersActive, onTap: onOpenFilters),
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

class FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const FilterButton({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.OrangeColor,
      borderRadius: BorderRadius.circular(context.r(4)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
              // A dot rather than a count: the sheet holds two controls, so
              // the number would never be interesting.
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

/// The time filter and search that the design's Filter button opens.
///
/// Both were on the wallet screen before the redesign; they kept working and
/// simply moved in here.
class TransactionFilterSheet extends StatefulWidget {
  final TimeFilter selectedTime;
  final String searchQuery;
  final Function(TimeFilter) onTimeChanged;
  final Function(String) onSearch;

  const TransactionFilterSheet({
    super.key,
    required this.selectedTime,
    required this.searchQuery,
    required this.onTimeChanged,
    required this.onSearch,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TimeFilter _time = widget.selectedTime;
  late final TextEditingController _search =
      TextEditingController(text: widget.searchQuery);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() {
    // Time first, then search: the screen refetches on each, and the search
    // callback is the one that carries the debounce.
    widget.onTimeChanged(_time);
    widget.onSearch(_search.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.r(22)),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(12),
          context.w(20),
          context.h(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: context.w(38),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: _T.stroke,
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
              ),
            ),
            SizedBox(height: context.h(16)),
            Text(
              'Filter transactions',
              style: TextStyle(
                fontSize: context.fs(17),
                fontWeight: FontWeight.w700,
                color: _T.ink,
              ),
            ),
            SizedBox(height: context.h(16)),
            Text(
              'Period',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: _T.muted,
              ),
            ),
            SizedBox(height: context.h(8)),
            Wrap(
              spacing: context.w(8),
              runSpacing: context.h(8),
              children: [
                _timeChip('All time', TimeFilter.allTime),
                _timeChip('Last 7 days', TimeFilter.last7Days),
                _timeChip('Last 30 days', TimeFilter.last30Days),
              ],
            ),
            SizedBox(height: context.h(18)),
            Text(
              'Search',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: _T.muted,
              ),
            ),
            SizedBox(height: context.h(8)),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _apply(),
              decoration: InputDecoration(
                hintText: 'Description or transaction ID',
                hintStyle: TextStyle(
                  fontSize: context.fs(13),
                  color: _T.muted,
                ),
                prefixIcon: Icon(Icons.search, size: context.w(19)),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                  borderSide: const BorderSide(color: _T.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                  borderSide: const BorderSide(color: AppColors.AppBlue),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
              ),
            ),
            SizedBox(height: context.h(20)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _time = TimeFilter.allTime;
                        _search.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: context.h(14)),
                      side: const BorderSide(color: _T.stroke),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w600,
                        color: _T.ink,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.OrangeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: context.h(14)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(String label, TimeFilter value) {
    final selected = _time == value;
    return GestureDetector(
      onTap: () => setState(() => _time = value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.AppBlue : Colors.white,
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(color: selected ? AppColors.AppBlue : _T.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.fs(13),
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _T.ink,
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
      return Padding(
        padding: EdgeInsets.all(context.h(32)),
        child: const Center(child: CircularProgressIndicator()),
      );
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
