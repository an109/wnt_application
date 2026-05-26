import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../model/wallet_model.dart';

class TransactionFilters extends StatelessWidget {
  final TransactionType selectedType;
  final TimeFilter selectedTime;
  final Function(TransactionType) onTypeChanged;
  final Function(TimeFilter) onTimeChanged;
  final Function(String) onSearch;

  const TransactionFilters({
    super.key,
    required this.selectedType,
    required this.selectedTime,
    required this.onTypeChanged,
    required this.onTimeChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type and Time Filters
        Wrap(
          spacing: context.gapSmall,
          runSpacing: context.gapSmall,
          children: [
            _FilterChip(
              label: 'All',
              isSelected: selectedType == TransactionType.all,
              onTap: () => onTypeChanged(TransactionType.all),
            ),
            _FilterChip(
              label: 'Credits',
              isSelected: selectedType == TransactionType.credit,
              onTap: () => onTypeChanged(TransactionType.credit),
            ),
            _FilterChip(
              label: 'Debits',
              isSelected: selectedType == TransactionType.debit,
              onTap: () => onTypeChanged(TransactionType.debit),
            ),
            const SizedBox(width: 16),
            _FilterChip(
              label: 'All time',
              isSelected: selectedTime == TimeFilter.allTime,
              onTap: () => onTimeChanged(TimeFilter.allTime),
              isTimeFilter: true,
            ),
            _FilterChip(
              label: 'Last 7 days',
              isSelected: selectedTime == TimeFilter.last7Days,
              onTap: () => onTimeChanged(TimeFilter.last7Days),
              isTimeFilter: true,
            ),
            _FilterChip(
              label: 'Last 30 days',
              isSelected: selectedTime == TimeFilter.last30Days,
              onTap: () => onTimeChanged(TimeFilter.last30Days),
              isTimeFilter: true,
            ),
          ],
        ),

        SizedBox(height: context.gapMedium),

        // Search Bar
        TextField(
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'Search by description or transaction ID',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: context.gapMedium,
              horizontal: context.gapMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTimeFilter;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isTimeFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.borderRadiusSmall),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.gapMedium,
          vertical: context.gapSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isTimeFilter ? Colors.red.shade50 : Colors.red.shade600)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(context.borderRadiusSmall),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.bodySmall,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? (isTimeFilter ? Colors.red.shade700 : Colors.white)
                : Colors.black87,
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
      return Center(
        child: CircularProgressIndicator(),
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
        itemCount: transactions.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: context.dividerThin,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          if (index == transactions.length) {
            return Padding(
              padding: EdgeInsets.all(context.gapMedium),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _TransactionItem(transaction: transactions[index]);
        },
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('transaction_${transaction.id}'), //  Unique key per transaction
      contentPadding: EdgeInsets.symmetric(
        vertical: context.gapMedium,
        horizontal: 0,
      ),
      leading: Container(
        padding: EdgeInsets.all(context.gapSmall),
        decoration: BoxDecoration(
          color: transaction.isCredit
              ? Colors.green.shade50
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(context.borderRadiusSmall),
        ),
        child: Icon(
          transaction.isCredit
              ? Icons.arrow_downward
              : Icons.arrow_upward,
          color: transaction.isCredit ? Colors.green : Colors.red,
          size: context.iconMedium,
        ),
      ),
      title: Text(
        transaction.description,
        style: TextStyle(
          fontSize: context.bodyMedium,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${transaction.formattedDate} • ${transaction.status}',
        style: TextStyle(
          fontSize: context.bodySmall,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Text(
        transaction.isCredit
            ? '+${transaction.formattedAmount}'
            : '-${transaction.formattedAmount}',
        style: TextStyle(
          fontSize: context.bodyMedium,
          fontWeight: FontWeight.bold,
          color: transaction.isCredit ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}